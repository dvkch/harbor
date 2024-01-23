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
    
    @Argument(help: "Environment")
    var env: String?
    var environment: Environment!
    
    @Argument(help: "Service")
    var service: String!
    
    @Option(help: "Tail")
    var tail: Int = 50

    @Flag(help: "Tail")
    var noStream: Bool = false

    mutating func run() throws {
        (self.environment, self.service) = Environment.selectService(env: env, service: service, filter: .none)
        print("")
        print("Streaming logs from \(environment.name)/\(service!)...")
        environment.logs(service: service, follow: !noStream, tail: tail)
    }
}

