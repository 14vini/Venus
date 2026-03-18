//
//  LocalSubscriptionStatusProvider.swift
//  Venus
//
//  Created by Codex on 19/02/26.
//

import Foundation

/// Local source of truth for plan status.
/// Future premium rollout can replace this by StoreKit / backend provider.
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
