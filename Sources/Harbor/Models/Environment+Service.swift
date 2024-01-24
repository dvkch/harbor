//
//  Environment+Service.swift
//  
//
//  Created by syan on 17/02/2023.
//

import Foundation

extension Environment {
    
    enum ServiceFilter {
        case none, db, sensitiveOperation
    }
    
    static func selectEnvironment(env envName: String?) -> Environment {
        let envs = Config.shared.environments
        let selectedEnv: Environment
        if let envName, let env = envs.first(where: { $0.alias == envName }) {
            selectedEnv = env
        }
        else {
            selectedEnv = Prompt.choice("Select your env:", options: envs)
        }
        return selectedEnv
    }

    static func selectService(env envName: String?, service serviceName: String?, filter: ServiceFilter) -> (Environment, any Serviceable) {
        let selectedEnv = selectEnvironment(env: envName)
        
        // select service
        let services: [any Serviceable] = selectedEnv.services(filter: filter)
        let selectedService: any Serviceable
        if let serviceName, let service = services.unique(where: { $0.serviceDisplayName.hasPrefix(serviceName) }) {
            selectedService = service
        }
        else {
            selectedService = Prompt.choice("Select the service:", services: services)
        }

        return (selectedEnv, selectedService)
    }

    func services(filter: ServiceFilter) -> [any Serviceable] {
        let command: String
        var services: [any Serviceable]

        switch provider {
        case .swarm:
            command = "docker service ls --format '{{.Name}}'"
            services = sshList(.command(command)).sorted()
        case .compose:
            command = "docker container ls --format '{{.Names}}'"
            services = sshList(.command(command)).sorted()
        case .k3s:
            command = "k3s kubectl get deployment --recursive --all-namespaces --output=json"
            let servicesData = sshList(.command(command)).joined(separator: "\n").data(using: .utf8)!
            let servicesJson = try! JSONDecoder().decode(KubernetesList<KubernetesDeployment>.self, from: servicesData)
            services = servicesJson.items.filter({ $0.metadata.namespace != "kube-system" && $0.status.replicas != nil })
        }
        
        switch filter {
        case .sensitiveOperation:
            services = services
                .filter { !$0.serviceDisplayName.contains("traefik") }
                .filter { !$0.serviceDisplayName.contains("nginx") }
        case .db:
            services = services
                .filter { $0.serviceDisplayName.contains("_db") }
        case .none:
            break
        }
        
        return services
    }
    
    func logs(service s: any Serviceable, follow: Bool, tail: Int) {
        let followFlag = follow ? "-f" : ""
        let args = "\(followFlag) --tail \(tail)"
        switch provider {
        case .swarm:
            sshRun(.command("docker service logs \(s.serviceName) \(args)"))
        case .compose:
            sshRun(.command("docker container logs \(s.serviceName) \(args)"))
        case .k3s:
            let cmd = "k3s kubectl logs \(s.serviceName) -n \(s.serviceNamespace) --all-containers=true \(args)"
            sshRun(.command(cmd))
        }
    }
  
    func reload(service: any Serviceable) {
        switch provider {
        case .swarm:
            sshInteractive("docker service update \(service.serviceName) --force")
        case .compose:
            sshInteractive("docker container restart \(service.serviceName)")
        case .k3s:
            sshInteractive("k3s kubectl rollout restart \(service.serviceName) -n \(service.serviceNamespace)")
        }
    }
    
    func inspect(service: any Serviceable) -> any Inspectable {
        switch provider {
        case .swarm:
            let rawJSON = sshList(.command("docker service inspect \(service.serviceName)")).joined()
            let rawData = rawJSON.data(using: .utf8)!
            return try! JSONDecoder().decode([DockerService].self, from: rawData)[0]
        case .compose:
            let rawJSON = sshList(.command("docker container inspect \(service.serviceName)")).joined()
            let rawData = rawJSON.data(using: .utf8)!
            return try! JSONDecoder().decode([DockerContainer].self, from: rawData)[0]
        case .k3s:
            return service as! KubernetesDeployment
        }
    }
    
    @discardableResult
    func exec(service: any Serviceable, command: String, interactive: Bool = true, redirectOutputPath: String? = nil) -> [String] {
        switch provider {
        case .swarm:
            // https://www.reddit.com/r/docker/comments/a5kbte/comment/ebp9kab/?utm_source=share&utm_medium=web2x&context=3
            let script = [
                "#!/bin/bash",
                "TASK_ID=$(docker service ps --filter 'desired-state=running' \(service.serviceName) -q)",
                "NODE_ID=$(docker inspect --format '{{ .NodeID }}' $TASK_ID)",
                "CONTAINER_ID=$(docker inspect --format '{{ .Status.ContainerStatus.ContainerID }}' $TASK_ID)",
                "NODE_HOST=$(docker node inspect --format '{{ .Description.Hostname }}' $NODE_ID)",
                "echo $NODE_HOST",
                "echo $CONTAINER_ID",
            ].joined(separator: "\n")

            let info = sshList(.script(script))
            let nodeName = info[0]
            let containerID = info[1]
            
            guard let nodeHost = nodes?[nodeName] else {
                print("Found node named \(nodeName) for service \(service.serviceDisplayName), but couldn't find corresponding host, check your config file")
                exit(-1)
            }

            let updatedEnv = self.copy(newHost: nodeHost)
            if interactive {
                updatedEnv.sshInteractive("docker exec -it \(containerID) \(command)")
                return []
            }
            else {
                return updatedEnv.sshList(.command("docker exec -i \(containerID) \(command)"), redirectOutputPath: redirectOutputPath)
            }
                
        case .compose:
            if interactive {
                sshInteractive("docker exec -it \(service.serviceName) \(command)")
                return []
            }
            else {
                return sshList(.command("docker exec -i \(service.serviceName) \(command)"), redirectOutputPath: redirectOutputPath)
            }
            
        case .k3s:
            fatalError("NOT IMPLEMENTED")
        }
    }
}
