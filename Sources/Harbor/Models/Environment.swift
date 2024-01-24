//
//  Environment.swift
//
//
//  Created by syan on 16/02/2023.
//

import Foundation

struct Environment: Codable {
    let name: String
    let alias: String
    private(set) var host: String
    private let userOptional: String?
    var user: String { userOptional ?? "root" }
    private let portOptional: Int?
    var port: Int { portOptional ?? 22 }
    let provider: Provider
    let nodes: [String: String]?
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case alias = "alias"
        case host = "host"
        case userOptional = "user"
        case portOptional = "port"
        case provider = "provider"
        case nodes = "nodes"
    }
    
    enum Provider: String, Codable {
        case compose = "compose"
        case swarm = "swarm"
        case k3s = "k3s"
    }
    
    func copy(newHost: String) -> Environment {
        var copy = self.copy
        copy.host = newHost
        return copy
    }
}

extension Environment: CustomStringConvertible {
    var description: String {
        return name
    }
}
