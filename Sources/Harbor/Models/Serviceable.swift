//
//  Serviceable.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

protocol Serviceable {
    var serviceDisplayName: String { get }
    var serviceName: String { get }
    var serviceNamespace: String { get }
    var serviceCapabilities: [ServiceCapability] { get }
}

enum ServiceCapability {
    case db, reloadable, sensitive, exec
}

extension String: Serviceable {
    var serviceDisplayName: String { return self }
    var serviceName: String { return self }
    var serviceNamespace: String { fatalError("Unsupported") }
    var serviceCapabilities: [ServiceCapability] {
        var capabilities = [ServiceCapability]()
        capabilities.append(.exec)
        capabilities.append(.reloadable)
        if serviceDisplayName.contains("_db") || serviceDisplayName.contains("-db") {
            capabilities.append(.db)
        }
        if serviceDisplayName.contains("traefik") || serviceDisplayName.contains("nginx") {
            capabilities.append(.sensitive)
        }
        return capabilities
    }
}
