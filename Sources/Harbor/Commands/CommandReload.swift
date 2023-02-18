//
//  CommandReload.swift
//
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ArgumentParser

struct CommandReload: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "reload",
        abstract: "Restart a service"
    )
    
    @Argument(help: "Environment")
    var env: String?
    var environment: Environment!
    
    @Argument(help: "Service")
    var service: String!
    
    mutating func run() throws {
        (self.environment, self.service) = Environment.selectService(env: env, service: service, filter: .none)
        
        print("")
        print("Will now restart \(environment.name)/\(service!)...")
        environment.reload(service: service)
    }
}

