//
//  Inspectable.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

protocol Inspectable {
    var inspectableImage: String { get }
    var inspectableEnv: [(String, String)] { get }
}

extension Inspectable {
    func inspectableEnv(for key: String) -> String? {
        return inspectableEnv.last(where: { $0.0 == key })?.1
    }
}

struct ConcreteInspectable: Inspectable {
    let inspectableImage: String
    let inspectableEnv: [(String, String)]

    init(inspectableImage: String, inspectableEnv: [(String, String)]) {
        self.inspectableImage = inspectableImage
        self.inspectableEnv = inspectableEnv
    }

    init(inspectableImage: String, inspectableEnv: [String: String]) {
        self.inspectableImage = inspectableImage
        self.inspectableEnv = inspectableEnv.map { ($0, $1) }
    }
}
