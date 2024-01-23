//
//  CommandStats.swift
//
//
//  Created by syan on 18/02/2023.
//

import Foundation
import ArgumentParser

struct CommandStats: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "stats",
        abstract: "Obtain container stats for an environment",
        discussion: "For a Docker Swarm environment, this will only show the stats for a single node"
    )
    
    @Argument(help: "Environment")
    var env: String?
    var environment: Environment!
    
    @Flag(help: "Print only first output instead of streaming")
    var noStream: Bool = false
    
    mutating func run() throws {
        self.environment = Environment.selectEnvironment(env: env)
        
        if environment.provider == .swarm {
            let nodeHost = Prompt.choice("Select your node:", optionsWithTitleKeys: environment.nodes ?? [:])
            self.environment = self.environment.copy(newHost: nodeHost)
        }
        
        var command = "docker stats"
        if noStream {
            command += " --no-stream"
        }
        
        environment.sshRun(.command(command))
    }
}

