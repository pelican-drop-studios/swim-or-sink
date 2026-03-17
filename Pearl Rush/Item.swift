//
//  Item.swift
//  Pearl Rush
//
//  Created by Brayden Weismantel on 17/3/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
