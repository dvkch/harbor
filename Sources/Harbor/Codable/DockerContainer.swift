//
//  DockerContainer.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

// https://docs.docker.com/engine/api/v1.42/#tag/Container/operation/ContainerInspect
struct DockerContainer: Decodable {
    let id: String
    let created: String
    let path: String
    let args: [String]

    struct ContainerState: Decodable {
        let status: String
        let running: Bool
        let paused: Bool
        let restarting: Bool
        let oomKilled: Bool
        let dead: Bool
        let pid: Int
        let exitCode: Int
        let error: String
        let startedAt: String
        let finishedAt: String
        
        private enum CodingKeys: String, CodingKey {
            case status     = "Status"
            case running    = "Running"
            case paused     = "Paused"
            case restarting = "Restarting"
            case oomKilled  = "OOMKilled"
            case dead       = "Dead"
            case pid        = "Pid"
            case exitCode   = "ExitCode"
            case error      = "Error"
            case startedAt  = "StartedAt"
            case finishedAt = "FinishedAt"
        }
    }
    let state: ContainerState
    
    let image: String
    let resolvConfPath: String
    let hostnamePath: String
    let hostsPath: String
    let logPath: String
    let name: String
    let restartCount: Int
    let driver: String
    let platform: String?

    struct HostConfig: Decodable {
        struct LogConfig: Decodable {
            let type: String
            
            private enum CodingKeys: String, CodingKey {
                case type = "Type"
            }
        }
        let logConfig: LogConfig
        let networkMode: String
        
        struct PortBinding: Decodable {
            let hostIP: String
            let hostPort: String
            private enum CodingKeys: String, CodingKey {
                case hostIP   = "HostIp"
                case hostPort = "HostPort"
            }
        }
        let portBindings: [String: PortBinding]
        
        struct RestartPolicy: Decodable {
            let name: String
            let maximumRetryCount: Int
            
            private enum CodingKeys: String, CodingKey {
                case name = "Name"
                case maximumRetryCount = "MaximumRetryCount"
            }
        }
        let restartPolicy: RestartPolicy
        let privileged: Bool
        let cpuShares: Int
        let memory: Int
        
        struct Mount: Decodable {
            let type: String
            let source: String
            let target: String

            private enum CodingKeys: String, CodingKey {
                case type   = "Type"
                case source = "Source"
                case target = "Target"
            }
        }
        let mounts: [Mount]?

        private enum CodingKeys: String, CodingKey {
            case logConfig      = "LogConfig"
            case networkMode    = "NetworkMode"
            case portBindings   = "PortBindings"
            case restartPolicy  = "RestartPolicy"
            case privileged    = "Privileged"
            case cpuShares      = "CpuShares"
            case memory         = "Memory"
            case mounts         = "Mounts"
        }
    }
    let hostConfig: HostConfig
    
    struct Mount: Decodable {
        let name: String?
        let type: String?
        let driver: String?
        let source: String
        let destination: String
        let mode: String
        let rw: Bool

        private enum CodingKeys: String, CodingKey {
            case name        = "Name"
            case type        = "Type"
            case driver      = "Driver"
            case source      = "Source"
            case destination = "Destination"
            case mode        = "Mode"
            case rw          = "RW"
        }
    }
    let mounts: [Mount]
    
    struct Config: Decodable {
        let hostname: String
        let domainName: String
        let user: String
        let exposedPorts: [String: [String: String]]?
        let env: [String]
        let cmd: [String]
        let image: String
        let volumes: [String: [String: String]]?
        let workingDir: String
        let entrypoint: [String]?
        let labels: [String: String]
        
        private enum CodingKeys: String, CodingKey {
            case hostname = "Hostname"
            case domainName = "Domainname"
            case user = "User"
            case exposedPorts = "ExposedPorts"
            case env = "Env"
            case cmd = "Cmd"
            case image = "Image"
            case volumes = "Volumes"
            case workingDir = "WorkingDir"
            case entrypoint = "Entrypoint"
            case labels = "Labels"
        }
    }
    let config: Config
    
    struct NetworkSettings: Decodable {
        let bridge: String

        struct Port: Decodable {
            let hostIP: String
            let hostPort: String
            private enum CodingKeys: String, CodingKey {
                case hostIP   = "HostIp"
                case hostPort = "HostPort"
            }
        }
        let ports: [String: Port?]?
        
        struct Network: Decodable {
            let networkID: String
            let ipAddress: String

            private enum CodingKeys: String, CodingKey {
                case networkID = "NetworkID"
                case ipAddress = "IPAddress"
            }
        }
        let networks: [String: Network]
        
        private enum CodingKeys: String, CodingKey {
            case bridge     = "Bridge"
            case ports      = "Ports"
            case networks   = "Networks"
        }
    }
    let networkSettings: NetworkSettings
    
    private enum CodingKeys: String, CodingKey {
        case id = "Id"
        case created = "Created"
        case path = "Path"
        case args = "Args"
        case state = "State"
        case image = "Image"
        case resolvConfPath = "ResolvConfPath"
        case hostnamePath = "HostnamePath"
        case hostsPath = "HostsPath"
        case logPath = "LogPath"
        case name = "Name"
        case restartCount = "RestartCount"
        case driver = "Driver"
        case platform = "Platform"
        case hostConfig = "HostConfig"
        case mounts = "Mounts"
        case config = "Config"
        case networkSettings = "NetworkSettings"
    }
}

extension DockerContainer: Inspectable {
    var inspectableImage: String {
        return config.image
    }
    
    var inspectableEnv: [(String, String)] {
        return config.env.parsedEnv
    }
}
