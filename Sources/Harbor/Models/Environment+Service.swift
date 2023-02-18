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
    
    static func selectService(env envName: String?, service serviceName: String?, filter: ServiceFilter) -> (Environment, String) {
        // select env
        let envs = Config.shared.environments
        let selectedEnv: Environment
        if let envName, let env = envs.first(where: { $0.alias == envName }) {
            selectedEnv = env
        }
        else {
            selectedEnv = Prompt.choice("Select your env:", options: envs)
        }
        
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
    
    func logs(service: String, tail: Int) {
        switch provider {
        case .swarm:
            sshRun(.command("docker service logs #{service} -f --tail \(tail)"))
        case .compose:
            sshRun(.command("docker container logs #{service} -f --tail \(tail)"))
        }
    }
  
    func reload(service: String) {
        switch provider {
        case .swarm:
            sshRun(.command("docker service update #{service} --force"), cleanupDuplicateOutput: true)
        case .compose:
            sshRun(.command("docker container restart #{service}"))
        }
    }
    
    enum InspectableValues {
        case image, env
    }
    func inspect(service: String, keys: [InspectableValues]) -> [InspectableValues: Any] {
        if keys.isEmpty {
            print("No values to inspect, returning early")
            return [:]
        }

        let rawData: String
        switch provider {
        case .swarm:
            rawData = sshList(.command("docker service inspect \(service)")).joined()
        case .compose:
            rawData = sshList(.command("docker container inspect \(service)")).joined()
        }
  
        let json = try! JSONSerialization.jsonObject(with: rawData.data(using: .utf8)!) as! NSDictionary
        var result = [InspectableValues: Any]()
        
        keys.forEach { key in
            switch key {
            case .image:
                result[key] = json.dig([0, "Spec", "Labels", "com.docker.stack.image"]) ?? json.dig([0, "Config", "Image"])
            case .env:
                let rawValue = json.dig([0, "Spec", "TaskTemplate", "ContainerSpec", "Env"]) ?? json.dig([0, "Config", "Env"])
                guard let value = rawValue as? [String] else {
                    fatalError("Invalid data from env inspection")
                }
                result[key] = value
                    .map { $0.split(separator: "=", maxSplits: 1).map { String($0) } }
                    .reduce(into: [String: String]()) { $0[$1[0]] = $1[1] }
            }
        }
  
        return result
    }
    
    func exec(service: String, command: String, interactive: Bool = true) -> [String] {
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
                print("Couldn't find the corresponding host for the service \(service) on the node named \(nodeName)")
                exit(-1)
            }

            let updatedEnv = self.copy(newHost: nodeHost)
            if interactive {
                updatedEnv.sshInteractive("docker exec -it \(containerID) \(command)")
                return []
            }
            else {
                return updatedEnv.sshList(.command("docker exec -it \(containerID) \(command)"))
            }
                
        case .compose:
            if interactive {
                sshInteractive("docker exec -it \(service) \(command)")
                return []
            }
            else {
                return sshList(.command("docker exec -i \(service) \(command)"))
            }
        }
    }
}
