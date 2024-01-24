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
    
    @Argument(help: "Environment", completion: .custom({ Environment.generateEnvironmentCompletion($0.last) }))
    var env: String?
    
    @Flag(help: "Print only first output instead of streaming")
    var noStream: Bool = false
    
    mutating func run() throws {
        var environment = Environment.selectEnvironment(env: env)
        
        let dockerStreamFlag = noStream ? "--no-stream" : ""
        
        let command: String

        switch environment.provider {
        case .compose:
            command = "docker stats \(dockerStreamFlag)"

        case .swarm:
            command = "docker stats \(dockerStreamFlag)"
            let nodeHost = Prompt.choice("Select your node:", optionsWithTitleKeys: environment.nodes ?? [:])
            environment = environment.copy(newHost: nodeHost)

        case .k3s:
            command = "k3s kubectl top pod --all-namespaces"
        }
        
        environment.sshInteractive(command)
    }
}

