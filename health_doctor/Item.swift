//
//  Item.swift
//  health_doctor
//
//  Created by Sebastian Böhler on 16.07.25.
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
