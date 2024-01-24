//
//  Environment+Completion.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

extension Environment {
    static func generateEnvironmentCompletion(_ input: String?) -> [String] {
        return Config.shared.environments.map(\.alias).filter { $0.starts(with: input ?? "") }
    }
    
    static func generateServiceCompletion(_ input: String?, env: String?, filter: ServiceFilter) -> [String] {
        let environment = Config.shared.environments.first(where: { $0.alias == env })
        return environment?.services(filter: filter).map(\.serviceDisplayName).filter { $0.starts(with: input ?? "") } ?? []
    }
}
