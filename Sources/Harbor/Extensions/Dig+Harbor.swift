//
//  Dig+Harbor.swift
//  
//
//  Created by syan on 17/02/2023.
//

import Foundation

extension Array {
    func dig(_ paths: ArraySlice<Any>) -> Any? {
        guard let path = paths.first else {
            // called with empty keys
            return nil
        }
        guard let index = path as? Int else {
            // using a dictionary key for an array
            fatalError("Digging using key \(path) into \(self)")
        }

        let otherPaths = paths.dropFirst()
        if otherPaths.isEmpty {
            // nothing else to dig
            return self[index]
        }
        
        if let value = self[index] as? Array<Any> {
            return value.dig(otherPaths)
        }
        if let value = self[index] as? NSDictionary {
            return value.dig(otherPaths)
        }
        fatalError("Digging into a non-sequence value: \(self[index])")
    }
}

extension NSDictionary {
    func dig(_ paths: ArraySlice<Any>) -> Any? {
        guard let path = paths.first else {
            // called with empty keys
            return nil
        }
        guard let key = path as? String else {
            // using an index for a dictionary
            fatalError("Digging using key \(path) into \(self)")
        }

        let otherPaths = paths.dropFirst()
        if otherPaths.isEmpty {
            // nothing else to dig
            return self[index]
        }
        
        if let value = self[key] as? Array<Any> {
            return value.dig(otherPaths)
        }
        if let value = self[key] as? NSDictionary {
            return value.dig(otherPaths)
        }
        fatalError("Digging into a non-sequence value: \(self[key] ?? "<nil>")")
    }
}
