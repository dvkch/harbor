//
//  KubernetesDeployment.swift
//
//
//  Created by syan on 23/01/2024.
//

struct KubernetesDeployment: Decodable {
    struct Metadata: Decodable {
        let annotations: [String: String]
        let creationTimestamp: String
        let generation: Int
        let labels: [String: String]
        let name: String
        let namespace: String
        let uid: String

        private enum CodingKeys: String, CodingKey {
            case annotations        = "annotations"
            case creationTimestamp  = "creationTimestamp"
            case generation         = "generation"
            case labels             = "labels"
            case name               = "name"
            case namespace          = "namespace"
            case uid                = "uid"
        }
    }
    let metadata: Metadata
    
    struct Spec: Decodable {
        let progressDeadlineSeconds: Int
        let replicas: Int
        let revisionHistoryLimit: Int
        
        struct Selector: Decodable {
            let matchLabels: [String: String]
            
            private enum CodingKeys: String, CodingKey {
                case matchLabels = "matchLabels"
            }
        }
        let selector: Selector
        
        struct Strategy: Decodable {
            let type: String
            
            struct RollingUpdate: Decodable {
                let maxSurge: DecodableEither<String, Int>
                let maxUnavailable: DecodableEither<String, Int>

                private enum CodingKeys: String, CodingKey {
                    case maxSurge       = "maxSurge"
                    case maxUnavailable = "maxUnavailable"
                }
            }
            let rollingUpdate: RollingUpdate?
            
            private enum CodingKeys: String, CodingKey {
                case type           = "type"
                case rollingUpdate  = "rollingUpdate"
            }
        }
        let strategy: Strategy
        
        struct Template: Decodable {
            struct Metadata: Decodable {
                let annotations: [String: String]?
                let creationTime: String?
                let labels: [String: String]
                let name: String?

                private enum CodingKeys: String, CodingKey {
                    case annotations    = "annotations"
                    case creationTime   = "creationTime"
                    case labels         = "labels"
                    case name           = "name"
                }
            }
            let metadata: Metadata
            
            struct Spec: Decodable {
                struct Container: Decodable {
                    let args: [String]?
                    
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
                        let limits: [String: String]
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
                    let volumeMounts: [Mount]?
                    
                    private enum CodingKeys: String, CodingKey {
                        case args                       = "args"
                        case env                        = "env"
                        case image                      = "image"
                        case imagePullPolicy            = "imagePullPolicy"
                        case name                       = "name"
                        case ports                      = "ports"
                        case resources                  = "resources"
                        case terminationMessagePath     = "terminationMessagePath"
                        case terminationMessagePolicy   = "terminationMessagePolicy"
                        case volumeMounts               = "volumeMounts"
                    }
                }
                let containers: [Container]

                let dnsPolicy: String
                let hostNetwork: Bool?
                let nodeSelector: [String: String]?
                let priorityClassName: String?
                let schedulerName: String?
                let restartPolicy: String?
                let serviceAccount: String?
                let serviceAccountName: String?
                let terminationGracePeriodSeconds: Int
                let tolerations: [[String: String]]?
                
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

                    struct EmptyDir: Decodable {}
                    let emptyDir: EmptyDir?
                    
                    struct ConfigMap: Decodable {
                        let defaultMode: Int
                        let items: [[String: String]]?
                        let name: String

                        private enum CodingKeys: String, CodingKey {
                            case defaultMode = "defaultMode"
                            case items       = "items"
                            case name        = "name"
                        }
                    }
                    let configMap: ConfigMap?

                    private enum CodingKeys: String, CodingKey {
                        case name       = "name"
                        case hostPath   = "hostPath"
                        case emptyDir   = "emptyDir"
                        case configMap  = "configMap"
                    }
                }
                let volumes: [Volume]?
                
                private enum CodingKeys: String, CodingKey {
                    case containers                     = "containers"
                    case dnsPolicy                      = "dnsPolicy"
                    case hostNetwork                    = "hostNetwork"
                    case nodeSelector                   = "nodeSelector"
                    case priorityClassName              = "priorityClassName"
                    case schedulerName                  = "schedulerName"
                    case restartPolicy                  = "restartPolicy"
                    case serviceAccount                 = "serviceAccount"
                    case serviceAccountName             = "serviceAccountName"
                    case terminationGracePeriodSeconds  = "terminationGracePeriodSeconds"
                    case tolerations                    = "tolerations"
                    case volumes                        = "volumes"
                }
            }
            let spec: Spec

            private enum CodingKeys: String, CodingKey {
                case metadata   = "metadata"
                case spec       = "spec"
            }
        }
        let template: Template
        
        private enum CodingKeys: String, CodingKey {
            case progressDeadlineSeconds    = "progressDeadlineSeconds"
            case replicas                   = "replicas"
            case revisionHistoryLimit       = "revisionHistoryLimit"
            case selector                   = "selector"
            case strategy                   = "strategy"
            case template                   = "template"
        }
    }
    let spec: Spec

    struct Status: Decodable {
        let availableReplicas: Int?
        let observedGeneration: Int
        let readyReplicas: Int?
        let replicas: Int?
        let updatedReplicas: Int?

        private enum CodingKeys: String, CodingKey {
            case availableReplicas  = "availableReplicas"
            case observedGeneration = "observedGeneration"
            case readyReplicas      = "readyReplicas"
            case replicas           = "replicas"
            case updatedReplicas    = "updatedReplicas"
        }
    }
    let status: Status
    
    private enum CodingKeys: String, CodingKey {
        case metadata   = "metadata"
        case spec       = "spec"
        case status     = "status"
    }
}

extension KubernetesDeployment: Serviceable {
    var serviceDisplayName: String {
        return (
            metadata.labels["app"] ??
            metadata.labels["app.kubernetes.io/instance"] ??
            metadata.labels["io.kubernetes.pod.name"] ?? 
            metadata.uid
        )
    }
    
    var serviceName: String {
        return "deployment/" + metadata.name
    }
    
    var serviceNamespace: String {
        return metadata.namespace
    }
}

extension KubernetesDeployment: Inspectable {
    var inspectableImage: String {
        return self.spec.template.spec.containers.first!.image
    }
    
    var inspectableEnv: [(String, String)] {
        return self.spec.template.spec.containers.first?.env?.map { ($0.name, $0.value ?? "") } ?? []
    }
}
