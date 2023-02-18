//
//  Environment+SSH.swift
//  
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ConsoleKit
import SwiftCLI

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
    func sshRun(_ command: SSHCommand, output: Bool = true, cleanupDuplicateOutput: Bool = false) -> [String] {
        let commandString: String
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("harbor-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempFileURL) }

        switch command {
        case .command(let value):
            commandString = "ssh -p\(port) \(user)@\(host) \"\(value)\""
        case .script(let value):
            try! value.write(to: tempFileURL, atomically: true, encoding: .utf8)
            commandString = "ssh -\(port) \(user)@\(host) 'bash -s' < \(tempFileURL.path)"
        }

        var dataOut = ""
        var dataErr = ""
        let pipeOut = Pipe()
        let pipeErr = Pipe()
        
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
        task.launchPath = "/usr/bin/env"
        task.arguments = ["bash", "-c", commandString]
        task.standardOutput = pipeOut
        task.standardError = pipeErr
        task.launch()
        task.waitUntilExit()
        if task.terminationStatus != 0 {
            print("Error while executing \(commandString) on \(host), returned \(task.terminationStatus)")
            exit(task.terminationStatus)
        }
        return dataOut.split(separator: "\n").map { String($0) }
    }
    
    func sshInteractive(_ command: String) {
        let stdInPipe = Pipe()
        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()
        
        Thread.detachNewThread {
            try! runInRawMode {
                while true {
                    var char: UInt8 = 0
                    read(STDIN_FILENO, &char, 1)
                    write(stdInPipe.fileHandleForWriting.fileDescriptor, &char, 1)
                }
            }
        }
        
        Thread.detachNewThread {
            try! runInRawMode(fd: STDOUT_FILENO) {
                while true {
                    var char: UInt8 = 0
                    read(stdOutPipe.fileHandleForReading.fileDescriptor, &char, 1)
                    write(STDOUT_FILENO, &char, 1)
                }
            }
        }
        
        Thread.detachNewThread {
            try! runInRawMode(fd: STDERR_FILENO) {
                while true {
                    var char: UInt8 = 0
                    read(stdErrPipe.fileHandleForReading.fileDescriptor, &char, 1)
                    write(STDERR_FILENO, &char, 1)
                }
            }
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["ssh", "-tt", "-p\(port)", "\(user)@\(host)", command]
        task.standardInput = stdInPipe
        task.standardOutput = stdOutPipe
        task.standardError = stdErrPipe
        task.launch()
        task.waitUntilExit()
        exit(0)
    }
    
    func sshList(_ command: SSHCommand) -> [String] {
        return sshRun(command, output: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    func sshValue(_ command: SSHCommand) -> String? {
        return sshList(command).first
    }
}
