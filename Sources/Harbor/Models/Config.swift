//
//  Config.swift
//  
//
//  Created by syan on 16/02/2023.
//

import Foundation

struct Config: Codable {
    
    // MARK: Paths
    static let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/harbor.json")

    static let inputHistoryPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/harbor_input_history")

    // MARK: Init
    static let shared: Config = {
        guard let configData = try? Data(contentsOf: configPath) else {
            return Config(environments: [])
        }

        return try! JSONDecoder().decode(Config.self, from: configData)
    }()
    
    // MARK: Properties
    let environments: [Environment]
    
    // MARK: History
    func readInputHistory() -> [String] {
        let content = (try? String(contentsOf: type(of: self).inputHistoryPath)) ?? ""
        return content.components(separatedBy: .newlines)
    }
    
    func writeInputHistory(_ items: [String], maxItems: Int) {
        let itemsToWrite = items.dropFirst(max(0, items.count - maxItems))
        let content = itemsToWrite.joined(separator: "\n")
        try? content.write(to: type(of: self).inputHistoryPath, atomically: true, encoding: .utf8)
    }
}
