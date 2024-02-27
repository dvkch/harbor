//
//  HerokuAddon.swift
//
//
//  Created by syan on 27/02/2024.
//

import Foundation

struct HerokuAddon: Decodable {
    let id: String
    let name: String
    let app: HerokuApp.Element
    let createdAt: String
    let updatedAt: String
    let configVars: [String]
    let state: String
    
    struct AddonService: Decodable {
        let name: String
        let humanName: String
        
        enum Kind: String, CaseIterable {
            case postgresql = "heroku-postgresql"
            case redis = "heroku-redis"
            case unknown = ""
        }
        var kind: Kind {
            return Kind.allCases.first(where: { $0.rawValue == name }) ?? .unknown
        }
        
        private enum CodingKeys: String, CodingKey {
            case name       = "name"
            case humanName  = "human_name"
        }
    }
    let addonService: AddonService
    let webURL: URL?
    
    private enum CodingKeys: String, CodingKey {
        case id             = "id"
        case name           = "name"
        case app            = "app"
        case createdAt      = "created_at"
        case updatedAt      = "updated_at"
        case configVars     = "config_vars"
        case state          = "state"
        case addonService   = "addon_service"
        case webURL         = "web_url"
    }
}

extension HerokuAddon: Equatable {
    static func == (lhs: HerokuAddon, rhs: HerokuAddon) -> Bool {
        return lhs.id == rhs.id
    }
}
