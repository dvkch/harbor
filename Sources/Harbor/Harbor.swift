//
//  Harbor.swift
//
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ArgumentParser
import ConsoleKit

enum Crash {
    case signal(Int32)
    #if os(macOS)
    case exception(NSException)
    #endif
}

var crashCleanup: [() -> ()] = []
func exceptionHandler(_ error: Crash) {
    switch error {
    case .signal(let signal):
        print("Signal received:", String(cString: strsignal(signal)))
    #if os(macOS)
    case .exception(let e):
        print("Exception:")
        print(e)
    #endif
    }
    crashCleanup.forEach { block in
        block()
    }
}

@main
struct Harbor: ParsableCommand {
    static var configuration: CommandConfiguration = {
        let commands: [ParsableCommand.Type] = [
            CommandStats.self,
            CommandExec.self,
            CommandLogs.self,
            CommandReload.self,
            CommandDbBackup.self,
            CommandDockerInit.self,
            CommandCompletion.self
        ].filter { ($0 as? RuntimeAvailability.Type)?.isAvailable != false }
        
        return .init(
            abstract: "Harbor",
            version: "1.2",
            subcommands: commands,
            defaultSubcommand: nil
        )
    }()
    
    public static func main(_ arguments: [String]?) {
        do {
            var command = try parseAsRoot(arguments)
            try command.run()
        } catch {
            exit(withError: error)
        }
    }

    public static func main() {
        let currentTermSettings = Terminal().obtainMode(fd: FileHandle.standardInput.fileDescriptor)
        crashCleanup.append {
            if let currentTermSettings {
                Terminal().setMode(currentTermSettings, fd: FileHandle.standardInput.fileDescriptor)
            }
        }
        
        #if os(macOS)
        NSSetUncaughtExceptionHandler({ e in exceptionHandler(.exception(e)) });
        #endif
        signal(SIGABRT, { e in exceptionHandler(.signal(e)) })
        signal(SIGABRT, { e in exceptionHandler(.signal(e)) })
        signal(SIGILL,  { e in exceptionHandler(.signal(e)) })
        signal(SIGSEGV, { e in exceptionHandler(.signal(e)) })
        signal(SIGFPE,  { e in exceptionHandler(.signal(e)) })
        signal(SIGBUS,  { e in exceptionHandler(.signal(e)) })
        signal(SIGPIPE, { e in exceptionHandler(.signal(e)) })

        main(nil)
    }
}
