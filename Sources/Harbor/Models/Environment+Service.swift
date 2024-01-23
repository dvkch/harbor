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

    static func selectService(env envName: String?, service serviceName: String?, filter: ServiceFilter) -> (Environment, String) {
        let selectedEnv = selectEnvironment(env: envName)
        
        // select service
        let services = selectedEnv.services(filter: filter)
        let selectedService: String
        if let serviceName, let service = services.unique(where: { $0.hasPrefix(serviceName) }) {
            selectedService = service
        }
        else {
            selectedService = Prompt.choice("Select the service:", options: services)
        }

        return (selectedEnv, selectedService)
    }

    func services(filter: ServiceFilter) -> [String] {
        let command: String
        switch provider {
        case .swarm:
            command = "docker service ls --format '{{.Name}}'"
        case .compose:
            command = "docker container ls --format '{{.Names}}'"
        }
        
        var services = sshList(.command(command)).sorted()
        
        // cleanup k8s ix services
        if services.first(where: { $0.starts(with: "k8s_") }) != nil {
            services = services
                .filter { !$0.contains("_POD_") }
                .filter { !$0.contains("_kube-system_") }
        }
        
        switch filter {
        case .sensitiveOperation:
            services = services
                .filter { !$0.contains("traefik") }
                .filter { !$0.contains("nginx") }
        case .db:
            services = services
                .filter { $0.contains("_db") }
        case .none:
            break
        }
        
        return services
    }
    
    func logs(service: String, follow: Bool, tail: Int) {
        let followFlag = follow ? "-f" : ""
        switch provider {
        case .swarm:
            sshRun(.command("docker service logs \(service) \(followFlag) --tail \(tail)"))
        case .compose:
            sshRun(.command("docker container logs \(service) \(followFlag) --tail \(tail)"))
        }
    }
  
    func reload(service: String) {
        switch provider {
        case .swarm:
            sshInteractive("docker service update \(service) --force")
        case .compose:
            sshInteractive("docker container restart \(service)")
        }
    }
    
    func inspect(service: String) -> any Inspectable {
        switch provider {
        case .swarm:
            let rawJSON = sshList(.command("docker service inspect \(service)")).joined()
            let rawData = rawJSON.data(using: .utf8)!
            return try! JSONDecoder().decode([DockerServiceInspect].self, from: rawData)[0]
        case .compose:
            let rawJSON = sshList(.command("docker container inspect \(service)")).joined()
            let rawData = rawJSON.data(using: .utf8)!
            return try! JSONDecoder().decode([DockerContainerInspect].self, from: rawData)[0]
        }
    }
    
    @discardableResult
    func exec(service: String, command: String, interactive: Bool = true, redirectOutputPath: String? = nil) -> [String] {
        switch provider {
        case .swarm:
            // https://www.reddit.com/r/docker/comments/a5kbte/comment/ebp9kab/?utm_source=share&utm_medium=web2x&context=3
            let script = [
                "#!/bin/bash",
                "TASK_ID=$(docker service ps --filter 'desired-state=running' \(service) -q)",
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
                print("Found node named \(nodeName) for service \(service), but couldn't find corresponding host, check your config file")
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
                sshInteractive("docker exec -it \(service) \(command)")
                return []
            }
            else {
                return sshList(.command("docker exec -i \(service) \(command)"), redirectOutputPath: redirectOutputPath)
            }
        }
    }
}
