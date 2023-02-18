//
//  ProjectKind.swift
//  
//
//  Created by syan on 18/02/2023.
//

import Foundation

enum ProjectKind: String, CaseIterable, CustomStringConvertible {
    case nuxtStatic = "Nuxt static"
    case nuxtServer = "Nuxt server"
    case rails = "Rails"
    
    var description: String { rawValue }
}

extension ProjectKind {
    struct Param: CustomStringConvertible, Hashable {
        let name: String
        let description: String
        let `default`: String?
        
        init(name: String, description: String, default: String? = nil) {
            self.name = name
            self.description = description
            self.default = `default`
        }
    }

    var requiredParams: [Param] {
        switch self {
        case .nuxtStatic:
            return [
                Param(name: "NODE_VERSION", description: "Node.js version", default: "18")
            ]
        case .nuxtServer:
            return [
                Param(name: "NODE_VERSION", description: "Node.js version", default: "18")
            ]
        case .rails:
            return [
                Param(name: "RUBY_VERSION", description: "Ruby version", default: "3.1.3")
            ]
        }
    }
}

extension ProjectKind {
    struct TemplateFile {
        let source: String
        let destination: String
    }

    var fileList: [TemplateFile] {
        var files: [TemplateFile] = [
            TemplateFile(
                source: "DockerInit/Common/_dockerignore",
                destination: ".dockerignore"
            )
        ]
        
        switch self {
        case .nuxtStatic:
            files += [
                TemplateFile(
                    source: "DockerInit/NuxtStatic/docker-compose.yml",
                    destination: "docker-compose.yml"
                ),
                TemplateFile(
                    source: "DockerInit/NuxtStatic/docker-nginx-server.conf",
                    destination: "docker-nginx-server.conf"
                ),
                TemplateFile(
                    source: "DockerInit/NuxtStatic/docker-nginx.conf",
                    destination: "docker-nginx.conf"
                ),
                TemplateFile(
                    source: "DockerInit/NuxtStatic/Dockerfile",
                    destination: "Dockerfile"
                )
            ]

        case .nuxtServer:
            files += [
                TemplateFile(
                    source: "DockerInit/NuxtServer/docker-compose.yml",
                    destination: "docker-compose.yml"
                ),
                TemplateFile(
                    source: "DockerInit/NuxtServer/Dockerfile",
                    destination: "Dockerfile"
                    
                )
            ]
            
        case .rails:
            files += [
                TemplateFile(
                    source: "DockerInit/Rails/docker_startup.sh",
                    destination: "docker_startup.sh"
                ),
                TemplateFile(
                    source: "DockerInit/Rails/docker-compose.yml",
                    destination: "docker-compose.yml"
                ),
                TemplateFile(
                    source: "DockerInit/Rails/Dockerfile",
                    destination: "Dockerfile"
                )
            ]
        }
        
        return files
    }
}

extension ProjectKind {
    var checklist: [String] {
        switch self {
        case .nuxtStatic:
            return [
                "- use process.env.APP_URL in your nuxt.config.js file as needed",
                "- update Dockerfile to switch to npm if needed"
            ]
            
        case .nuxtServer:
            return [
                "- use process.env.APP_URL in your nuxt.config.js file as needed",
                "- update your nuxt config to support SERVER_HOST and SERVER_PORT env",
                "- update Dockerfile to switch to npm if needed"
            ]

        case .rails:
            return [
                "- use ENV['APP_HOST'] if need be"
            ]
        }
    }
}

