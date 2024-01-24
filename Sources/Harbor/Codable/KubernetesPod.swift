//
//  KubernetesPod.swift
//
//
//  Created by syan on 23/01/2024.
//

struct KubernetesPod: Decodable {
    struct Metadata: Decodable {
        let annotations: [String: String]?
        let creationTimestamp: String
        let generateName: String
        let labels: [String: String]
        let name: String
        let namespace: String
        let uid: String

        private enum CodingKeys: String, CodingKey {
            case annotations        = "annotations"
            case creationTimestamp  = "creationTimestamp"
            case generateName       = "generateName"
            case labels             = "labels"
            case name               = "name"
            case namespace          = "namespace"
            case uid                = "uid"
        }
    }
    let metadata: Metadata
    
    struct Spec: Decodable {
        struct Container: Decodable {
            struct Env: Decodable {
                let name: String
                let value: String?

                private enum CodingKeys: String, CodingKey {
                    case name   = "name"
                    case value  = "value"
                }
            }
            let env: [Env]?
            
            let image: String
            let imagePullPolicy: String
            let name: String
            
            struct Port: Decodable {
                let containerPort: Int
                let `protocol`: String

                private enum CodingKeys: String, CodingKey {
                    case containerPort  = "containerPort"
                    case `protocol`     = "protocol"
                }
            }
            let ports: [Port]?
            
            struct Resources: Decodable {
                let limits: [String: String]?
                let requests: [String: String]?

                private enum CodingKeys: String, CodingKey {
                    case limits     = "limits"
                    case requests   = "requests"
                }
            }
            let resources: Resources
            
            let terminationMessagePath: String?
            let terminationMessagePolicy: String
            
            struct Mount: Decodable {
                let mountPath: String
                let name: String
                let readOnly: Bool?

                private enum CodingKeys: String, CodingKey {
                    case mountPath  = "mountPath"
                    case name       = "name"
                    case readOnly   = "readOnly"
                }
            }
            let volumeMounts: [Mount]
            
            private enum CodingKeys: String, CodingKey {
                case env                    = "env"
                case image                  = "image"
                case imagePullPolicy        = "imagePullPolicy"
                case name                   = "name"
                case ports                  = "ports"
                case resources              = "resources"
                case terminationMessagePath = "terminationMessagePath"
                case terminationMessagePolicy = "terminationMessagePolicy"
                case volumeMounts           = "volumeMounts"
            }
        }
        let containers: [Container]
        
        let dnsPolicy: String
        let enableServiceLinks: Bool
        let nodeName: String
        let restartPolicy: String
        let schedulerName: String
        let terminationGracePeriodSeconds: Int
        
        struct Volume: Decodable {
            let name: String
            
            struct HostPath: Decodable {
                let path: String
                let type: String
                private enum CodingKeys: String, CodingKey {
                    case path   = "path"
                    case type   = "type"
                }
            }
            let hostPath: HostPath?

            private enum CodingKeys: String, CodingKey {
                case name       = "name"
                case hostPath   = "hostPath"
            }
        }
        let volumes: [Volume]
        
        private enum CodingKeys: String, CodingKey {
            case containers                     = "containers"
            case dnsPolicy                      = "dnsPolicy"
            case enableServiceLinks             = "enableServiceLinks"
            case nodeName                       = "nodeName"
            case restartPolicy                  = "restartPolicy"
            case schedulerName                  = "schedulerName"
            case terminationGracePeriodSeconds  = "terminationGracePeriodSeconds"
            case volumes                        = "volumes"
        }
    }
    let spec: Spec

    struct StatusRunning: Decodable {
        struct ContainerStatus: Decodable {
            let id: String
            let image: String
            let name: String
            let ready: Bool
            let restartCount: Int
            let started: Bool
            
            private enum CodingKeys: String, CodingKey {
                case id           = "containerID"
                case image        = "image"
                case name         = "name"
                case ready        = "ready"
                case restartCount = "restartCount"
                case started      = "started"
            }
        }
        let containerStatuses: [ContainerStatus]
        let hostIP: String
        let phase: String
        let podIP: String
        
        struct PodIP: Decodable {
            let ip: String
            
            private enum CodingKeys: String, CodingKey {
                case ip = "ip"
            }
        }
        let podIPs: [PodIP]
        let qosClass: String
        let startTime: String

        private enum CodingKeys: String, CodingKey {
            case containerStatuses = "containerStatuses"
            case hostIP            = "hostIP"
            case phase             = "phase"
            case podIP             = "podIP"
            case podIPs            = "podIPs"
            case qosClass          = "qosClass"
            case startTime         = "startTime"
        }
    }
    
    struct StatusFailed: Decodable {
        let message: String
        let phase: String
        let reason: String
        let startTime: String

        private enum CodingKeys: String, CodingKey {
            case message    = "message"
            case phase      = "phase"
            case reason     = "reason"
            case startTime  = "startTime"
        }
    }
    
    let status: DecodableEither<StatusRunning, StatusFailed>

    private enum CodingKeys: String, CodingKey {
        case metadata   = "metadata"
        case spec       = "spec"
        case status     = "status"
    }
}

extension KubernetesPod: Serviceable {
    var serviceDisplayName: String {
        return (
            metadata.labels["app"] ??
            metadata.labels["app.kubernetes.io/instance"] ??
            metadata.labels["io.kubernetes.pod.name"] ?? 
            metadata.uid
        )
    }
    
    var serviceName: String {
        return "pod/" + metadata.name
    }
    
    var serviceNamespace: String {
        return metadata.namespace
    }
    
    var serviceDeployment: String {
        let podHash = metadata.labels["pod-template-hash"] ?? ""
        let deploymentName = metadata.generateName.replacingOccurrences(of: "-\(podHash)-", with: "")
        return "deployment/" + deploymentName
    }
}

extension KubernetesPod: Inspectable {
    var inspectableImage: String {
        return spec.containers.first!.image
    }
    
    var inspectableEnv: [(String, String)] {
        return spec.containers.first!.env?.map { ($0.name, $0.value ?? "") } ?? []
    }
}
