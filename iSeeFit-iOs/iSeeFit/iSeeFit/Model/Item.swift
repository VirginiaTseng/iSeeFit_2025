//
//  Item.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-17.
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
