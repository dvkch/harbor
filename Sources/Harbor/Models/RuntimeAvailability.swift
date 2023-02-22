//
//  RuntimeAvailability.swift
//  
//
//  Created by syan on 21/02/2023.
//

import ArgumentParser

protocol RuntimeAvailability {
    static var isAvailable: Bool { get }
}
