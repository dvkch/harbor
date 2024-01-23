//
//  Inspectable.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

protocol Inspectable {
    var inspectableImage: String { get }
    var inspectableEnv: [(String, String)] { get }
}

extension Inspectable {
    func inspectableEnv(for key: String) -> String? {
        return inspectableEnv.last(where: { $0.0 == key })?.1
    }
}

extension DockerContainerInspect: Inspectable {
    var inspectableImage: String {
        return image
    }
    
    var inspectableEnv: [(String, String)] {
        return config.env.parsedEnv
    }
}

extension DockerServiceInspect: Inspectable {
    var inspectableImage: String {
        return (spec.labels ?? [:])["com.docker.stack.image"]!
    }
    
    var inspectableEnv: [(String, String)] {
        return spec.taskTemplate.containerSpec.env?.parsedEnv ?? []
    }
}
