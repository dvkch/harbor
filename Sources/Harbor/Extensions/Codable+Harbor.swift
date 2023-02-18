//
//  Codable+Harbor.swift
//  
//
//  Created by syan on 18/02/2023.
//

import Foundation

extension Decodable where Self: Encodable {
    var copy: Self {
        let data = try! JSONEncoder().encode(self)
        return try! JSONDecoder().decode(type(of: self), from: data)
    }
}
