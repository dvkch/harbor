//
//  Serviceable.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

protocol Serviceable: CustomStringConvertible {
    var serviceDisplayName: String { get }
    var serviceName: String { get }
    var serviceNamespace: String { get }
    var serviceDeployment: String { get }
}

extension Serviceable {
    var description: String {
        return serviceDisplayName
    }
}

extension String: Serviceable {
    var serviceDisplayName: String { return self }
    var serviceName: String { return self }
    var serviceNamespace: String { return "" }
    var serviceDeployment: String { return "" }
}
