//
//  GeminiServiceProtocol.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol GeminiServiceProtocol: Sendable {
    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood]
    ) async throws -> String
    
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
}

typealias VenusAIServiceProtocol = GeminiServiceProtocol
