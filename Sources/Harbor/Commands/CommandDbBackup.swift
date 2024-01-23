//
//  CommandDbBackup.swift
//  
//
//  Created by syan on 17/02/2023.
//

import Foundation
import ArgumentParser

struct CommandDbBackup: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "db-backup",
        abstract: "Download a backup of the DB"
    )
    
    @Argument(help: "Environment")
    var env: String?
    var environment: Environment!
    
    @Argument(help: "Service")
    var service: String!
    
    @Argument(help: "Filename")
    var filename: String!
    
    mutating func run() throws {
        (self.environment, self.service) = Environment.selectService(env: env, service: service, filter: .db)
        let config = environment.inspect(service: service)
        let image = config.inspectableImage.split(separator: ":").first
        let tag = config.inspectableImage.split(separator: ":").last
        guard let image = image, let tag = tag else {
            print("Couldn't detect image for service \(service!)")
            return
        }
        
        let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(filename)
        
        print("")
        print("Detected image: \(image), tag: \(tag)")
        self.filename = filename ?? Prompt.input("Output filename:", default: "db.dump")
        
        switch image {
        case "postgres":
            let user = config.inspectableEnv(for: "POSTGRES_USER") ?? "postgres"
            guard let dbName = config.inspectableEnv(for: "POSTGRES_DB") else {
                print("No POSTGRES_DB is defined for the service")
                return
            }
            
            let command = "pg_dump -Fc --no-acl --no-owner -h localhost -U \(user) \(dbName)"
            let data = environment.exec(service: service, command: command, interactive: false).joined().data(using: .utf8)!
            try! data.write(to: outputURL)
            
        case "myssql":
            guard let user = config.inspectableEnv(for: "MYSQL_USER") else {
                print("Couldn't find MYSQL_USER")
                return
            }
            guard let pass = config.inspectableEnv(for: "MYSQL_PASSWORD") else {
                print("Couldn't find MYSQL_PASSWORD")
                return
            }
            guard let db = config.inspectableEnv(for: "MYSQL_DATABASE") else {
                print("Couldn't find MYSQL_DATABASE")
                return
            }

            var command = "MYSQL_PWD=\(pass) /usr/bin/mysqldump --default-character-set=utf8mb4 --no-tablespaces -u \(user) \(db)"
            command = "/bin/bash -c '\(command)'"
            let dump = environment
                .exec(service: service, command: command, interactive: false)
                .joined(separator: "\n")

            try dump.write(to: outputURL, atomically: true, encoding: .utf8)
            
        default:
            print("Unrecognized DB image \(image), cannot perform DB backup")
        }
    }
}

