//
//  KubernetesList.swift
//
//
//  Created by syan on 23/01/2024.
//

import Foundation

struct KubernetesList<T: Decodable>: Decodable {
    let items: [T]
}
