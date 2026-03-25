//
//  VenusPlan.swift
//  Venus
//
//  Created by Kaua on 19/02/26.
//

import Foundation

enum VenusPlan: String, Codable, Sendable {
    case free
    case pro
}

struct CheckInAllowance: Sendable {
    static let defaultFreeDailyLimit = 3

    let plan: VenusPlan
    let dailyLimit: Int?
    let usedToday: Int
    
    var isUnlimited: Bool {
        dailyLimit == nil
    }
    
    var remainingToday: Int? {
        guard let dailyLimit else { return nil }
        return max(0, dailyLimit - usedToday)
    }
    
    var canCheckIn: Bool {
        guard let remainingToday else { return true }
        return remainingToday > 0
    }
    
    static let freeDefault = CheckInAllowance(
        plan: .free,
        dailyLimit: defaultFreeDailyLimit,
        usedToday: 0
    )
}
