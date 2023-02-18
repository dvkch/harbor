//
//  String+Harbor.swift
//  
//
//  Created by syan on 18/02/2023.
//

import Foundation

extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")

    // https://www.hackingwithswift.com/example-code/strings/how-to-convert-a-string-to-a-safe-format-for-url-slugs-and-filenames
    var slugified: String {
        guard isNotEmpty else {
            fatalError("Slugified strings shouldn't be empty")
        }

        let latin = applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false)!
        let components = latin.components(separatedBy: String.slugSafeCharacters.inverted)
        return components.filter(\.isNotEmpty).joined(separator: "-")
    }
}

extension String {
    func escapingOccurrences(of string: String) -> String {
        replacingOccurrences(of: string, with: "\\" + string)
    }
    
    var commandEscaped: String {
        if self.contains(where: \.isWhitespace) {
            return "\"" + escapingOccurrences(of: "\"") + "\""
        }
        return self
    }
}
