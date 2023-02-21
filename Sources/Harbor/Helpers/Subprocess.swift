//
//  Subprocess.swift
//  
//
//  Created by syan on 18/02/2023.
//

import Foundation

// https://gist.github.com/dduan/d4e967f3fc2801d3736b726cd34446bc
class Subprocess {
    
    // MARK: Init
    init(path: String, args: [String], env: [String: String] = [:], autokillAfterDeath: Bool = true) {
        self.path = path
        self.args = args
        self.envs = env
        self.autokillAfterDeath = autokillAfterDeath
    }
    
    deinit {
        try? FileManager.default.removeItem(at: generatedScriptURL)
    }
    
    // MARK: Properties
    let path: String
    let args: [String]
    let envs: [String: String]
    private var fullEnvs: [String: String] {
        var finalEnv = ProcessInfo.processInfo.environment
        envs.forEach { key, value in
            finalEnv[key] = value
        }
        return finalEnv
    }
    let autokillAfterDeath: Bool

    // MARK: Internal properties
    enum State: Equatable {
        case notRunning
        case running(pid: pid_t)
        case ended(terminationStatus: Int32)
    }
    private(set) var state: State = .notRunning
    
    // MARK: Internal helpers
    private lazy var generatedScriptURL: URL = {
        // this script will check every second if the parent still exists. if it doesn't it will kill the subprocess
        var fullCommand = ([path] + args).map(\.commandEscaped).joined(separator: " ")
        var script: String {
            [
                "#!/bin/bash",
                "wait_for_parent() { while sleep 1; do kill -0 $PPID > /dev/null 2>&1 || (pkill -P $$ && exit 1); done }",
                "wait_for_parent & (\(fullCommand))"
            ].joined(separator: "\n")
        }

        let scriptPath = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).sh", isDirectory: false)
        try! script.write(to: scriptPath, atomically: true, encoding: .utf8)
        return scriptPath
    }()

    func launch() {
        guard state == .notRunning else {
            fatalError("Already running")
        }

        var pid: pid_t = 0
        if autokillAfterDeath {
            swift_posix_spawn(pid: &pid, path: "/bin/bash", args: [generatedScriptURL.path], envs: fullEnvs)
        }
        else {
            swift_posix_spawn(pid: &pid, path: path, args: [path] + args, envs: fullEnvs)
        }
        state = .running(pid: pid)
    }
    
    func waitUntilExit() {
        guard case .running(let pid) = state else {
            fatalError("Is not running")
        }

        var terminationStatus: Int32 = 0
        let r = waitpid(pid, &terminationStatus, 0)
        guard r != -1 else {
            fatalError("WaitPIDError")
        }
        state = .ended(terminationStatus: terminationStatus)
    }
}

private func swift_posix_spawn(pid: UnsafeMutablePointer<pid_t>, path: String, args: [String], envs: [String: String]) {
    let cArgs = ([path] + args).map { strdup($0) } + [nil]
    let cEnvs = envs.map { k, v in strdup("\(k)=\(v.commandEscaped)") } + [nil]

    defer { cArgs.forEach { free($0) } }
    defer { cEnvs.forEach { free($0) } }

    let r = posix_spawn(pid, path, nil, nil, cArgs, cEnvs)
    guard r == 0 else {
        fatalError("POSIXSpawnError: \(r)")
    }
}
