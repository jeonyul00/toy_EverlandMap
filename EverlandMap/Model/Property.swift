//
//  Property.swift
//  EverlandMap
//
//  Created by 전율 on 11/19/24.
//

import Foundation

struct Property: Codable {
    let name: String?
    let desc: String?
    let category: String
    let accessibleToDisabled: Bool?
}
