//
//  DockerService.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

// https://docs.docker.com/engine/api/v1.42/#tag/Service/operation/ServiceInspect
struct DockerService: Decodable {
    let id: String
    let createdAt: String
    let updatedAt: String
    
    struct Spec: Decodable {
        let name: String
        let labels: [String: String]?
        
        struct TaskTemplate: Decodable {
            struct ContainerSpec: Decodable {
                let image: String
                let labels: [String: String]?
                let args: [String]?
                let hostname: String?
                let env: [String]?
                let stopGracePeriod: Int?
                
                struct Healthcheck: Decodable {
                    let test: [String]
                    let interval: Int
                    let startPeriod: Int?
                    
                    private enum CodingKeys: String, CodingKey {
                        case test        = "Test"
                        case interval    = "Interval"
                        case startPeriod = "StartPeriod"
                    }
                }
                let healthcheck: Healthcheck?
                
                private enum CodingKeys: String, CodingKey {
                    case image              = "Image"
                    case labels             = "Labels"
                    case args               = "Args"
                    case hostname           = "Hostname"
                    case env                = "Env"
                    case stopGracePeriod    = "StopGracePeriod"
                    case healthcheck        = "Healthcheck"
                }
            }
            let containerSpec: ContainerSpec
            
            struct RestartPolicy: Decodable {
                let condition: String
                let delay: Int?
                let maxAttempts: Int
                
                private enum CodingKeys: String, CodingKey {
                    case condition   = "Condition"
                    case delay       = "Delay"
                    case maxAttempts = "MaxAttempts"
                }
            }
            let restartPolicy: RestartPolicy?
            
            struct Network: Decodable {
                let target: String
                let aliases: [String]
                
                private enum CodingKeys: String, CodingKey {
                    case target = "Target"
                    case aliases = "Aliases"
                }
            }
            let networks: [Network]?
            let runtime: String?
            
            private enum CodingKeys: String, CodingKey {
                case containerSpec  = "ContainerSpec"
                case restartPolicy  = "RestartPolicy"
                case networks       = "Networks"
                case runtime        = "Runtime"
            }
        }
        let taskTemplate: TaskTemplate
        
        struct Mode: Decodable {
            let replicas: Int
            
            private enum CodingKeys: String, CodingKey {
                case replicas = "Replicas"
            }
        }
        let mode: [String: Mode]
        
        struct UpdateConfig: Decodable {
            let parallelism: Int
            let failureAction: String
            let monitor: Int?
            let maxFailureRatio: Double
            let order: String?
            
            private enum CodingKeys: String, CodingKey {
                case parallelism     = "Parallelism"
                case failureAction   = "FailureAction"
                case monitor         = "Monitor"
                case maxFailureRatio = "MaxFailureRatio"
                case order           = "Order"
            }
        }
        let updateConfig: UpdateConfig?
        let rollbackConfig: UpdateConfig?
        
        private enum CodingKeys: String, CodingKey {
            case name = "Name"
            case labels = "Labels"
            case taskTemplate = "TaskTemplate"
            case mode = "Mode"
            case updateConfig = "UpdateConfig"
            case rollbackConfig = "RollbackConfig"
        }
    }
    let spec: Spec
    let previousSpec: Spec?
    
    struct Endpoint: Decodable {
        struct Spec: Decodable {
            let mode: String
            
            private enum CodingKeys: String, CodingKey {
                case mode = "Mode"
            }
        }
        let spec: Spec
        
        struct VirtualIP: Decodable {
            let networkID: String
            let address: String
            
            private enum CodingKeys: String, CodingKey {
                case networkID  = "NetworkID"
                case address    = "Addr"
            }
        }
        let virtualIPs: [VirtualIP]
        
        private enum CodingKeys: String, CodingKey {
            case spec       = "Spec"
            case virtualIPs = "VirtualIPs"
        }
    }
    let endpoint: Endpoint
    
    private enum CodingKeys: String, CodingKey {
        case id             = "ID"
        case createdAt      = "CreatedAt"
        case updatedAt      = "UpdatedAt"
        case spec           = "Spec"
        case previousSpec   = "PreviousSpec"
        case endpoint       = "Endpoint"
    }
}

extension DockerService: Inspectable {
    var inspectableImage: String {
        return (spec.labels ?? [:])["com.docker.stack.image"]!
    }
    
    var inspectableEnv: [(String, String)] {
        return spec.taskTemplate.containerSpec.env?.parsedEnv ?? []
    }
}
