//
//  CommandExec.swift
//
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ArgumentParser
import ArgumentParserToolInfo

struct CommandExec: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "exec",
        abstract: "Run a command on a given docker service"
    )
    
    @Argument(help: "Environment")
    var env: String?
    var environment: Environment!
    
    @Argument(help: "Service")
    var service: String!
    
    @Flag(help: "Access reverse proxies and other sensitive containers")
    var sensitive: Bool = false
    
    @Argument(help: "Command")
    var command: [String] = []

    mutating func run() throws {
        (self.environment, self.service) = Environment.selectService(
            env: env, service: service,
            filter: sensitive ? .none : .sensitiveOperation
        )
        
        let command = self.command.joined(separator: " ").nilIfEmpty ?? Prompt.input("Command:", default: "/bin/sh")
        _ = environment.exec(service: service, command: command)
    }
}

