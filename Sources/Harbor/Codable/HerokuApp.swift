//
//  HerokuApp.swift
//
//
//  Created by syan on 27/02/2024.
//

import Foundation

struct HerokuApp: Decodable {
    let id: String
    let name: String
    let createdAt: String
    let updatedAt: String
    let releasedAt: String?
    let archivedAt: String?
    let buildpack: String
    let stack: Element
    let buildStack: Element
    let region: Element
    let webURL: URL?
    
    struct Element: Decodable {
        let id: String
        let name: String

        private enum CodingKeys: String, CodingKey {
            case id = "id"
            case name = "name"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id         = "id"
        case name       = "name"
        case createdAt  = "created_at"
        case updatedAt  = "updated_at"
        case releasedAt = "released_at"
        case archivedAt = "archived_at"
        case buildpack  = "buildpack_provided_description"
        case stack      = "stack"
        case buildStack = "build_stack"
        case region     = "region"
        case webURL     = "web_url"
    }
}

extension HerokuApp: Equatable {
    static func == (lhs: HerokuApp, rhs: HerokuApp) -> Bool {
        return lhs.id == rhs.id
    }
}
