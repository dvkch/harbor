//
//  Prompt.swift
//  
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ConsoleKit
import LineNoise

struct Prompt {

    static func choice<T: CustomStringConvertible>(_ title: String, options: [T]) -> T {
        if options.count == 1 {
            return options[0]
        }
        
        return Terminal().showOptions(title: title, options: options, display: { $0.description })
    }
    
    static func choice<E: CaseIterable & RawRepresentable & CustomStringConvertible>(_ title: String, options: E.Type) -> E {
        return choice(title, options: E.allCases.map { $0 })
    }
    
    static func choice<V>(_ title: String, optionsWithTitleKeys options: [String: V]) -> V {
        let keys = options.keys.sorted { key1, key2 in
            key1.description < key2.description
        }
        
        let selectedKey = choice(title, options: keys)
        return options[selectedKey]!
    }
    
    static func input(_ title: String, default: String? = nil) -> String {
        let history = Config.shared.readInputHistory()

        let ln = LineNoise()
        ln.setHistoryMaxLength(100)
        ln.preserveHistoryEdits = true
        history.forEach { ln.addHistory($0) }

        ln.setCompletionCallback { input in
            return history.filter { $0.hasPrefix(input) }.reversed()
        }
        ln.setHintsCallback { input in
            if let bestMatch = history.last(where: { $0.hasPrefix(input) })?.dropFirst(input.count), bestMatch.isNotEmpty {
                return (String(bestMatch), (127, 0, 127))
            }
            else {
                return (nil, nil)
            }
        }
        
        let input: String
        do {
            input = try ln.getLine(prompt: title + " ")
        }
        catch {
            exit(0)
        }
        print("")

        Config.shared.writeInputHistory(history + [input], maxItems: 200)
        return input
    }
    
    static func confirm(_ title: String) -> Bool {
        return Terminal().confirm("\(title)")
    }
}
