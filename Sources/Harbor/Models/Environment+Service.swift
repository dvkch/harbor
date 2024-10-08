//
//  Environment+Service.swift
//  
//
//  Created by syan on 17/02/2023.
//

import Foundation

extension Environment {
    
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
    
    enum Filter {
        case `is`(ServiceCapability)
        case ìsNot(ServiceCapability)
    }

    static func selectService(env envName: String?, service serviceName: String?, filters: [Filter]) -> (Environment, any Serviceable) {
        let selectedEnv = selectEnvironment(env: envName)
        
        // select service
        let services: [any Serviceable] = selectedEnv.services(filters: filters)
        let selectedService: any Serviceable
        if let serviceName, let service = services.unique(where: { $0.serviceDisplayName.hasPrefix(serviceName) }) {
            selectedService = service
        }
        else {
            selectedService = Prompt.choice("Select the service:", services: services)
        }

        return (selectedEnv, selectedService)
    }

    func services(filters: [Filter]) -> [any Serviceable] {
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
            services = sshCodable(.command(command), type: KubernetesList<KubernetesDeployment>.self)
                .items.filter({ $0.serviceNamespace != "kube-system" && $0.status.readyReplicas != nil })
        case .heroku:
            let apps = sshCodable(.command("heroku apps --json"), type: [HerokuApp].self)
            let dynos = apps.map { app in
                sshCodable(.command("heroku ps -a \(app.name) --json"), type: [HerokuDyno].self)
            }.reduce([], +)
            let addons = sshCodable(.command("heroku addons --json"), type: [HerokuAddon].self)
            services = HerokuService.services(apps: apps, dynos: dynos, addons: addons)
        }
        
        filters.forEach { filter in
            switch filter {
            case .is(let cap):
                services = services.filter { $0.serviceCapabilities.contains(cap) }
            case .ìsNot(let cap):
                services = services.filter { !$0.serviceCapabilities.contains(cap) }
            }
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
            let cmd = "k3s kubectl logs \(s.serviceName) -n \(s.serviceNamespace) --all-containers=true --prefix \(args)"
            sshRun(.command(cmd))
        case .heroku:
            let followFlag = follow ? "--tail" : ""
            var args = "\(followFlag) --num=\(tail) --force-colors"

            if s.serviceName.isNotEmpty {
                args += " -d \(s.serviceName)"
            }
            sshRun(.command("heroku logs -a \(s.serviceNamespace) \(args)"))
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
        case .heroku:
            sshInteractive("heroku dyno:restart \(service.serviceName) -a \(service.serviceNamespace)")
        }
    }
    
    func inspect(service: any Serviceable) -> any Inspectable {
        switch provider {
        case .swarm:
            return sshCodable(.command("docker service inspect \(service.serviceName)"), type: [DockerService].self)[0]
        case .compose:
            return sshCodable(.command("docker container inspect \(service.serviceName)"), type: [DockerContainer].self)[0]
        case .k3s:
            return service as! KubernetesDeployment
        case .heroku:
            let env = sshCodable(.command("heroku config --json -a \(service.serviceNamespace)"), type: [String: String].self)
            return ConcreteInspectable(inspectableImage: "", inspectableEnv: env)
        }
    }
    
    @discardableResult
    func exec(service s: any Serviceable, command: String, interactive: Bool = true, redirectOutputPath: String? = nil) -> [String] {
        let interactiveFlags = interactive ? "-it" : "-i"
        
        let sshEnv: Environment
        let sshCmd: String

        switch provider {
        case .swarm:
            // https://www.reddit.com/r/docker/comments/a5kbte/comment/ebp9kab/?utm_source=share&utm_medium=web2x&context=3
            let script = [
                "#!/bin/bash",
                "TASK_ID=$(docker service ps --filter 'desired-state=running' \(s.serviceName) -q)",
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
                print("Found node named \(nodeName) for service \(s.serviceDisplayName), but couldn't find corresponding host, check your config file")
                exit(-1)
            }

            sshEnv = self.copy(newHost: nodeHost)
            sshCmd = "docker exec \(interactiveFlags) \(containerID) \(command)"
                
        case .compose:
            sshEnv = self
            sshCmd = "docker exec \(interactiveFlags) \(s.serviceName) \(command)"
            
        case .k3s:
            sshEnv = self
            sshCmd = "k3s kubectl exec \(interactiveFlags) \(s.serviceName) -n \(s.serviceNamespace) -- \(command)"

        case .heroku:
            sshEnv = self
            sshCmd = "heroku run -a \(s.serviceNamespace) \(command)"
        }

        if interactive {
            sshEnv.sshInteractive(sshCmd)
            return []
        }
        else {
            return sshEnv.sshList(.command(sshCmd), redirectOutputPath: redirectOutputPath)
        }
    }
}
