//
//  Recommendation.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct Recommendation: Identifiable, Equatable {
    let id: UUID
    let activity: Activity
    let suggestedTime: Date
    let reason: String
    
    init(id: UUID = UUID(), activity: Activity, suggestedTime: Date = Date(), reason: String) {
        self.id = id
        self.activity = activity
        self.suggestedTime = suggestedTime
        self.reason = reason
    }
}
