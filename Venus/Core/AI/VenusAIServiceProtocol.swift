//
//  VenusAIServiceProtocol.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol VenusAIServiceProtocol: Sendable {
    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood]
    ) async throws -> String
    
    func generateStreamResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood]
    ) -> AsyncThrowingStream<String, Error>
    
    func analyzeEmotionalState(message: String) async throws -> EmotionalState
    func generateWellnessSuggestion(emotionalState: EmotionalState) -> String
    
    func generateMirrorResume(
        checkInHistory: [Mood],
        userProfile: UserProfile?
    ) async throws -> String
    
    func generateMirrorInsights(
        checkInHistory: [Mood],
        chatSessions: [ChatSession],
        userProfile: UserProfile?
    ) async throws -> (
        weeklyTrend: WeeklyEmotionalTrend,
        weeklyInsights: WeeklyStrategicInsights,
        patternAlert: PatternAlert?
    )
    
    func generateSuggestion(mood: MoodType, userContext: UserProfile) async throws -> String
    func generateGreeting(userName: String, mood: MoodType?) async throws -> String
    func generateOnboardingProfile(userProfile: UserProfile) async throws -> AIOnboardingProfileResponse

    // MARK: - Biometrics & Readiness AI Methods

    func analyzeChatReadinessImpact(messages: [ChatMessage]) async -> ChatReadinessImpact?
    func generateReadinessMicroCopy(
        score: Double,
        primaryState: String,
        userContext: String?
    ) async -> (stateTitle: String, stateSubtitle: String)
}

// Backward compatibility typealias
typealias GeminiServiceProtocol = VenusAIServiceProtocol
