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
    
    @Argument(help: "Environment", completion: .custom({ Environment.generateEnvironmentCompletion($0.last) }))
    var env: String?
    
    @Argument(help: "Service", completion: .custom({
        Environment.generateServiceCompletion($0.last, env: $0.beforeLast, filters: [.is(.db)])
    }))
    var service: String!

    @Argument(help: "Filename")
    var filename: String!

    @Flag(name: .long, help: "Obtain the latest download, for providers supporting it")
    var latest: Bool = false

    mutating func run() throws {
        let environment: Environment
        let service: any Serviceable
        (environment, service) = Environment.selectService(env: env, service: self.service, filters: [.is(.db)])

        let config = environment.inspect(service: service)
        let imageParts = config.inspectableImage.split(separator: ":")
        var image = String(imageParts.first ?? "")
        var tag = String(imageParts.last ?? "")
        
        if let service = service as? HerokuService, let db = service.addons.first(where: { $0.addonService.kind == .postgresql }) {
            image = db.addonService.name
            tag = ""
        }

        guard image.isNotEmpty else {
            print("Couldn't detect image for service \(service.serviceDisplayName)")
            return
        }
        
        print("")
        print("Detected image: \(image), tag: \(tag)")
        self.filename = filename ?? Prompt.input("Output filename:", default: "db.dump")

        let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(filename)

        switch image {
        case "postgres":
            let user = config.inspectableEnv(for: "POSTGRES_USER") ?? "postgres"
            guard let dbName = config.inspectableEnv(for: "POSTGRES_DB") else {
                print("No POSTGRES_DB is defined for the service")
                return
            }
            
            let command = "pg_dump -Fc --no-acl --no-owner -h localhost -U \(user) \(dbName)"
            environment.exec(service: service, command: command, interactive: false, redirectOutputPath: outputURL.path)
            
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
            environment.exec(service: service, command: command, interactive: false, redirectOutputPath: outputURL.path)

        case "heroku-postgresql":
            if !latest {
                environment.sshInteractive("heroku pg:backups:capture --app \(service.serviceNamespace)")
            }
            environment.sshInteractive("heroku pg:backups:download --app \(service.serviceNamespace) -o \"\(outputURL.path)\"")

        default:
            print("Unrecognized DB image \(image), cannot perform DB backup")
            return
        }

        print("Finished! Your data is available at", outputURL.path)
    }
}

