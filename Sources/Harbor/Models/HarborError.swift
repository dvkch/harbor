//
//  HarborError.swift
//  
//
//  Created by syan on 27/02/2024.
//

import Foundation

enum HarborError {
    case unsupported(Environment.Provider)
}

extension HarborError: Error {
    var errorDescription: String? {
        switch self {
        case .unsupported(let provider): return "This operation is not supported on \(provider.rawValue)"
        }
    }
}
