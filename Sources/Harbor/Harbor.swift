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
    static var configuration = CommandConfiguration(
        abstract: "Harbor",
        subcommands: [
            CommandExec.self,
            CommandLogs.self,
            CommandReload.self,
            CommandDbBackup.self,
            CommandDockerInit.self,
        ],
        defaultSubcommand: nil
    )
}

