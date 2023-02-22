//
//  Harbor.swift
//
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ArgumentParser

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
        ].filter { ($0 as? RuntimeAvailability.Type)?.isAvailable != false }
        
        return .init(
            abstract: "Harbor",
            version: "1.0",
            subcommands: commands,
            defaultSubcommand: nil
        )
    }()
}

