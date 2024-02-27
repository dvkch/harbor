//
//  Environment+SSH.swift
//  
//
//  Created by syan on 16/02/2023.
//

import Foundation

#if os(Linux)
import Glibc
#else
import Darwin
#endif


extension Environment {
    enum SSHCommand {
        case command(String)
        case script(String)
    }
    
    @discardableResult
    func sshRun(_ command: SSHCommand, output: Bool = true, cleanupDuplicateOutput: Bool = false, redirectOutputPath: String? = nil) -> [String] {
        var commandString: String
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("harbor-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempFileURL) }

        switch command {
        case .command(let value):
            commandString = "ssh -p\(port) \(user)@\(host) \"\(value)\""
        case .script(let value):
            try! value.write(to: tempFileURL, atomically: true, encoding: .utf8)
            commandString = "ssh -\(port) \(user)@\(host) 'bash -s' < \(tempFileURL.path)"
        }
        
        if let redirectOutputPath {
            commandString += " > \"\(redirectOutputPath)\""
        }
        
        var dataOut = ""
        var dataErr = ""

        let pipeOut = Pipe()
        defer { pipeOut.fileHandleForReading.closeFile() }
        
        let pipeErr = Pipe()
        defer { pipeErr.fileHandleForReading.closeFile() }

        pipeOut.fileHandleForReading.readabilityHandler = { handle in
            if let line = String(data: handle.availableData, encoding: .utf8) {
                if output {
                    // TODO: handle dedup
                    print(line, terminator: "")
                }
                dataOut += line
            }
        }
        pipeErr.fileHandleForReading.readabilityHandler = { handle in
            if let line = String(data: handle.availableData, encoding: .utf8) {
                if output {
                    // TODO: handle dedup
                    print(line, terminator: "")
                }
                dataErr += line
            }
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["bash", "-c", commandString]
        task.standardOutput = pipeOut
        task.standardError = pipeErr
        try! task.run()
        task.waitUntilExit()
        if task.terminationStatus != 0 {
            print("Error while executing \(commandString) on \(host), returned \(task.terminationStatus)")
            exit(task.terminationStatus)
        }

        return dataOut.split(separator: "\n").map { String($0) }
    }
    
    func sshInteractive(_ command: String) {
        let task = Subprocess(
            path: "/usr/bin/env",
            args: ["ssh", "-tt", "-x", "-p\(port)", "\(user)@\(host)", command],
            autokillAfterDeath: true
        )
        task.launch()
        task.waitUntilExit()
    }
    
    func sshList(_ command: SSHCommand, redirectOutputPath: String? = nil) -> [String] {
        return sshRun(command, output: false, redirectOutputPath: redirectOutputPath)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    func sshCodable<T: Decodable>(_ command: SSHCommand, type: T.Type) -> T {
        let data = sshList(command).joined().data(using: .utf8)!
        do {
            return try JSONDecoder().decode(T.self, from: data)
        }
        catch {
            fatalError("Couldn't decode \(type): \(error)")
        }
    }
    
    func sshValue(_ command: SSHCommand, redirectOutputPath: String? = nil) -> String? {
        return sshList(command, redirectOutputPath: redirectOutputPath).first
    }
}
