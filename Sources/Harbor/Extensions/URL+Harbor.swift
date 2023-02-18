//
//  URL+Harbor.swift
//  
//
//  Created by syan on 16/02/2023.
//

import Foundation

extension URL {
    var exists: Bool {
        return FileManager.default.fileExists(atPath: absoluteString)
    }
}
