//
//  DecodableEither.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

enum DecodableEither<T: Decodable, U: Decodable>: Decodable {
    case either(T)
    case or(U)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let value = try container.decode(T.self)
            self = .either(value)
        }
        catch {
            let value = try container.decode(U.self)
            self = .or(value)
        }
    }
    
    var either: T? {
        switch self {
        case .either(let value): return value
        case .or: return nil
        }
    }
    
    var or: U? {
        switch self {
        case .either: return nil
        case .or(let value): return value
        }
    }
}
