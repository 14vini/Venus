//
//  LocalSubscriptionStatusProvider.swift
//  Venus
//
//  Created by Kaua on 19/02/26.
//

import Foundation

struct LocalSubscriptionStatusProvider: SubscriptionStatusProviderProtocol {
    static let planKey = "venus.plan.isPro"

    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func currentPlan() async -> VenusPlan {
        userDefaults.bool(forKey: Self.planKey) ? .pro : .free
    }
}
