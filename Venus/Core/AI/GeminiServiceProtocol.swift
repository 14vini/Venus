//
//  GeminiServiceProtocol.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol GeminiServiceProtocol {
    /// Generate AI suggestion based on user's current mood and profile
    func generateSuggestion(mood: MoodType, userContext: UserProfile) async throws -> String
    
    /// Generate a personalized greeting
    func generateGreeting(userName: String, mood: MoodType?) async throws -> String
}
