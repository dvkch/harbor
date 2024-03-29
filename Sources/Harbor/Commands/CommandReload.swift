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
    
    @Argument(help: "Environment", completion: .custom({ Environment.generateEnvironmentCompletion($0.last) }))
    var env: String?
    var environment: Environment!
    
    @Argument(help: "Service", completion: .custom({
        Environment.generateServiceCompletion($0.last, env: $0.beforeLast, filters: [.is(.reloadable)])
    }))
    var service: String!
    
    mutating func run() throws {
        let environment: Environment
        let service: any Serviceable
        (environment, service) = Environment.selectService(env: env, service: self.service, filters: [.is(.reloadable)])
        
        print("")
        print("Will now restart \(environment.name)/\(service.serviceDisplayName)...")
        environment.reload(service: service)
    }
}

