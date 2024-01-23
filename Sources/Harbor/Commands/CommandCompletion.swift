//
//  CommandReload.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation
import ArgumentParser

struct CommandCompletion: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "completion",
        abstract: "Update harbor completion scripts"
    )
    
    enum Shell: String, Decodable, ExpressibleByArgument, CaseIterable {
        case zsh = "zsh"
        case bash = "bash"
        case fish = "fish"
    }

    @Argument(help: "Shell", completion: .list(Shell.allCases.map(\.rawValue)))
    var shell: Shell
    
    private var helpURL: String {
        return "https://apple.github.io/swift-argument-parser/documentation/argumentparser/installingcompletionscripts/"
    }
    
    private func completionContent() -> String {
        var dataOut = ""

        let pipeOut = Pipe()
        defer { pipeOut.fileHandleForReading.closeFile() }

        pipeOut.fileHandleForReading.readabilityHandler = { handle in
            if let line = String(data: handle.availableData, encoding: .utf8) {
                dataOut += line
            }
        }


        let p = Process()
        p.executableURL = URL(fileURLWithPath: ProcessInfo.processInfo.arguments.first!)
        p.arguments = ["--generate-completion-script", shell.rawValue]
        p.standardOutput = pipeOut

        try! p.run()
        p.waitUntilExit()
        return dataOut
    }

    mutating func run() throws {
        // TODO: better content
        let content = completionContent()
        
        switch shell {
        case .zsh:
            let directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".oh-my-zsh/completions/")
            if FileManager.default.fileExists(atPath: directory.path) {
                let outputPath = directory.appendingPathComponent("_harbor", isDirectory: false)
                try content.write(toFile: outputPath.path, atomically: true, encoding: .utf8)
                print("Auto completion has been installed at", outputPath.path)
            }
            else {
                print("Auto completion cannot be auto installed as you donnot seem to have oh-my-zsh installed. For further information, see", helpURL)
            }
            
        case .bash:
            let directory = URL(fileURLWithPath: "/usr/local/etc/bash_completion.d")
            if FileManager.default.fileExists(atPath: directory.path) {
                let outputPath = directory.appendingPathComponent("harbor.bash", isDirectory: false)
                try content.write(toFile: outputPath.path, atomically: true, encoding: .utf8)
                print("Auto completion has been installed at", outputPath.path)
            }
            else {
                print("Auto completion cannot be auto installed as you donnot seem to have bash-completion installed. For further information, see", helpURL)
            }
            
        case .fish:
            let directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/fish/completions/")
            if FileManager.default.fileExists(atPath: directory.path) {
                let outputPath = directory.appendingPathComponent("harbor.fish", isDirectory: false)
                try content.write(toFile: outputPath.path, atomically: true, encoding: .utf8)
                print("Auto completion has been installed at", outputPath.path)
            }
            else {
                print("Auto completion cannot be auto installed as you donnot seem to have fish installed. For further information, see", helpURL)
            }
        }
    }
}
