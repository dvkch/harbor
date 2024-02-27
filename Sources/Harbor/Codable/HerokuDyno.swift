//
//  HerokuDyno.swift
//
//
//  Created by syan on 27/02/2024.
//

import Foundation

struct HerokuDyno: Decodable {
    let id: String
    let name: String
    let app: HerokuApp.Element
    let command: String
    let type: String
    let state: String
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case app = "app"
        case command = "command"
        case type = "type"
        case state = "state"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension HerokuDyno: Equatable {
    static func == (lhs: HerokuDyno, rhs: HerokuDyno) -> Bool {
        return lhs.id == rhs.id
    }
}
