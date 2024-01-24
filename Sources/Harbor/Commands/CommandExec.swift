//
//  CommandExec.swift
//
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ArgumentParser

struct CommandExec: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "exec",
        abstract: "Run a command on a given docker service"
    )
    
    @Argument(help: "Environment", completion: .custom({ Environment.generateEnvironmentCompletion($0.last) }))
    var env: String?
    
    @Argument(help: "Service", completion: .custom({ Environment.generateServiceCompletion($0.last, env: $0.beforeLast, filter: .none) }))
    var service: String!
    
    @Flag(help: "Access reverse proxies and other sensitive containers")
    var sensitive: Bool = false
    
    @Argument(help: "Command")
    var command: [String] = []

    mutating func run() throws {
        let environment: Environment
        let service: any Serviceable
        (environment, service) = Environment.selectService(
            env: env, service: self.service,
            filter: sensitive ? .none : .sensitiveOperation
        )
        
        let command = self.command.joined(separator: " ").nilIfEmpty ?? Prompt.input("Command:", default: "/bin/sh")
        _ = environment.exec(service: service, command: command)
    }
}

