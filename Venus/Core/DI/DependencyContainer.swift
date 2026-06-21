//
//  DependencyContainer.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftData

@MainActor
class DependencyContainer {
    static let shared = DependencyContainer()
    
    let modelContainer: ModelContainer
    private let behaviorFeedbackStore: BehaviorFeedbackStoreProtocol = BehaviorFeedbackStore()
    
    private init() {
        do {
            let schema = Schema([
                UserProfileModel.self,
                MoodModel.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Factories
    
    // User Profile
    func makeUserProfileRepository() -> UserProfileRepositoryProtocol {
        return UserProfileRepositoryImpl(modelContainer: modelContainer)
    }
    
    func makeMoodRepository() -> MoodRepositoryProtocol {
        return MoodRepositoryImpl(modelContainer: modelContainer)
    }
    
    func makeSaveMoodUseCase() -> SaveMoodUseCaseProtocol {
        return SaveMoodUseCase(repository: makeMoodRepository())
    }
    
    func makeMoodCheckInViewModel() -> MoodCheckInViewModel {
        return MoodCheckInViewModel(saveMoodUseCase: makeSaveMoodUseCase())
    }
    
    // MARK: - Premium / Subscription
    
    func makeSubscriptionStatusProvider() -> SubscriptionStatusProviderProtocol {
        return LocalSubscriptionStatusProvider()
    }
    
    func makeCheckInAllowanceUseCase() -> CheckInAllowanceUseCaseProtocol {
        return CheckInAllowanceUseCase(subscriptionStatusProvider: makeSubscriptionStatusProvider())
    }
    
    // MARK: - AI Service
    
    func makeGeminiService() -> GeminiServiceProtocol {
        return GeminiServiceImpl()
    }
    
    func makeVenusAIService() -> VenusAIServiceProtocol {
        return VenusAIService()
    }
    
    // MARK: - Recommendation Engine

    func makeBehaviorFeedbackStore() -> BehaviorFeedbackStoreProtocol {
        behaviorFeedbackStore
    }

    func makePatternEngineUseCase() -> PatternEngineUseCaseProtocol {
        return PatternEngineUseCase(
            moodRepository: makeMoodRepository(),
            userProfileRepository: makeUserProfileRepository(),
            subscriptionStatusProvider: makeSubscriptionStatusProvider(),
            feedbackStore: makeBehaviorFeedbackStore()
        )
    }
    
    // MARK: - Chat
    
    func makeChatRepository() -> ChatRepositoryProtocol {
        return ChatRepositoryImpl()
    }
}
