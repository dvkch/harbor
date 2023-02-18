//
//  Sequence+Harbor.swift
//  
//
//  Created by syan on 17/02/2023.
//

import Foundation

extension Collection {
    var nilIfEmpty: Self? {
        return isEmpty ? nil : self
    }
    
    var isNotEmpty: Bool {
        return !isEmpty
    }
    
    func unique(where predicate: (Element) -> Bool) -> Element? {
        let filteredItems = self.filter(predicate)
        return filteredItems.count == 1 ? filteredItems.first : nil
    }
}
