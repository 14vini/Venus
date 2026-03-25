//
//  CheckInAllowanceUseCase.swift
//  Venus
//
//  Created by Kaua on 19/02/26.
//

import Foundation

protocol SubscriptionStatusProviderProtocol {
    func currentPlan() async -> VenusPlan
}

protocol CheckInAllowanceUseCaseProtocol {
    func execute(usedToday: Int) async -> CheckInAllowance
}

struct CheckInAllowanceUseCase: CheckInAllowanceUseCaseProtocol {
    private let subscriptionStatusProvider: SubscriptionStatusProviderProtocol
    
    init(subscriptionStatusProvider: SubscriptionStatusProviderProtocol) {
        self.subscriptionStatusProvider = subscriptionStatusProvider
    }
    
    func execute(usedToday: Int) async -> CheckInAllowance {
        let plan = await subscriptionStatusProvider.currentPlan()
        
        switch plan {
        case .pro:
            return CheckInAllowance(plan: .pro, dailyLimit: nil, usedToday: usedToday)
        case .free:
            return CheckInAllowance(
                plan: .free,
                dailyLimit: CheckInAllowance.defaultFreeDailyLimit,
                usedToday: usedToday
            )
        }
    }
}
