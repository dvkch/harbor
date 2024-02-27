//
//  CommandLogs.swift
//
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ArgumentParser

struct CommandLogs: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "logs",
        abstract: "Show log stream for a docker service"
    )
    
    @Argument(help: "Environment", completion: .custom({ Environment.generateEnvironmentCompletion($0.last) }))
    var env: String?
    
    @Argument(help: "Service", completion: .custom({ 
        Environment.generateServiceCompletion($0.last, env: $0.beforeLast, filters: [])
    }))
    var service: String!
    
    @Option(help: "Tail")
    var tail: Int = 50

    @Flag(help: "Tail")
    var noStream: Bool = false

    mutating func run() throws {
        let environment: Environment
        let service: any Serviceable
        (environment, service) = Environment.selectService(env: env, service: self.service, filters: [])

        print("")
        print("Streaming logs from \(environment.name)/\(service.serviceDisplayName)...")
        environment.logs(service: service, follow: !noStream, tail: tail)
    }
}

