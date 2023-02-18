//
//  Prompt.swift
//  
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ConsoleKit

struct Prompt {

    static func choice<T: CustomStringConvertible>(_ title: String, options: [T]) -> T {
        return Terminal().choose("\(title)", from: options)
    }
    
    static func choice<E: CaseIterable & RawRepresentable & CustomStringConvertible>(_ title: String, options: E.Type) -> E {
        return choice(title, options: E.allCases.map { $0 })
    }
    
    static func input(_ title: String, default: String? = nil, historyKey: String? = nil) -> String {
        Terminal().output("\(title)")
        if let historyKey, let savedValue = UserDefaults.standard.string(forKey: historyKey) {
            if choice("Use saved value?", options: [savedValue, "custom"]) == savedValue {
                return savedValue
            }
        }
        let value = Terminal().input()
        if let historyKey {
            UserDefaults.standard.set(value, forKey: historyKey)
        }
        return value
    }
    
    static func confirm(_ title: String) -> Bool {
        return Terminal().confirm("\(title)")
    }
}
