//
//  Config.swift
//  
//
//  Created by syan on 16/02/2023.
//

import Foundation

struct Config: Codable {

    // MARK: Init
    static let shared: Config = {
        let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/harbor.json")

        guard let configData = try? Data(contentsOf: configPath) else {
            return Config(environments: [])
        }

        return try! JSONDecoder().decode(Config.self, from: configData)
    }()
    
    // MARK: Properties
    let environments: [Environment]
}
