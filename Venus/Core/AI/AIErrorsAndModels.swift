//
//  AIErrorsAndModels.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

// MARK: - AI Errors

enum VenusAIError: LocalizedError {
    case noResponse
    case invalidResponse
    case networkError
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "Não foi possível obter resposta da Venus."
        case .invalidResponse:
            return "Resposta da inteligência artificial inválida ou corrompida."
        case .networkError:
            return "Falha de conexão com os serviços de inteligência artificial."
        case .missingAPIKey:
            return "Chave de API do Gemini não configurada."
        }
    }
}

typealias GeminiError = VenusAIError

// MARK: - Emotional State Models

enum EmotionType: String, CaseIterable, Codable, Sendable {
    case happy, sad, anxious, angry, neutral, excited, frustrated, lonely, stressed, grateful
}

struct EmotionalState: Sendable {
    let primaryEmotion: EmotionType
    let intensity: Int // 1-10
    let needsSupport: Bool
    let keywords: [String]
    
    static func neutral() -> EmotionalState {
        return EmotionalState(
            primaryEmotion: .neutral,
            intensity: 5,
            needsSupport: false,
            keywords: []
        )
    }
}

// MARK: - Gemini JSON Response Models

struct AIChatResponse: Codable {
    let response: String
    let summary: String
    let tags: [String]
    let reminder: String?
}

struct AIMirrorResponse: Codable {
    let direction: String
    let currentWeekScore: Double
    let previousWeekScore: Double?
    let summary: String
    let dominantTrigger: String
    let criticalWindow: String
    let bestDay: String
    let behavioralFocus: String
    let alertTitle: String?
    let alertDetail: String?
}

// MARK: - System Prompts

struct VenusSystemPrompt {
    static let fullPrompt = """
    You are the AI assistant (Venus) for this app (a mood/check-in and reminder app).
    You are supportive, emotionally intelligent, and designed to help users feel better (not to provide therapy or medical advice).

    Goal:
    Help the user capture, understand, and act on their daily mood or emotional check-ins with minimal friction.

    Core Behavior:
    - Accept short or long user input about how they feel.
    - Identify mood, emotional intensity, likely patterns, and possible triggers.
    - Generate a concise, premium-style response that feels supportive, intelligent, and clear.
    - Summarize the user’s input into a short note that can be saved in the app.
    - Optionally create a reminder or action suggestion when appropriate.

    Output Style:
    - Keep responses brief, polished, and easy to read.
    - Use a premium, calm, professional tone.
    - Avoid long explanations unless the user asks for them.
    - Prefer structured output over verbose text.
    - Do NOT use markdown bold/italic formatting in the JSON text fields.

    Token Efficiency & Processing Rules:
    - Only reference the latest user input plus the stored context.
    - Reuse stable context instead of reconstructing it in every turn.
    - Read the user's latest message and existing context, merge new input, and produce output.
    - If the user mentions distress or risk, respond with supportive language and encourage immediate real-world help.
    - Every output MUST be a valid JSON object matching the format below. Do not wrap the JSON in markdown blocks like ```json ... ```. Just return raw JSON.

    Format:
    {
      "response": "Short supportive reply to the user.",
      "summary": "Compact recap of the user’s mood/check-in.",
      "tags": ["mood", "stress", "sleep", "focus"],
      "reminder": "Optional reminder text or null"
    }

    Rules for JSON output fields:
    - "response": A short, empathetic, calm response directly to the user (in Portuguese).
    - "summary": A concise recap of the user's current mood/check-in (in Portuguese).
    - "tags": Array of strings representing identified moods or topics (e.g. "mood", "sono", "estresse", "foco"). Max 4 tags.
    - "reminder": An optional short text suggesting a practical task/action the user can do to feel better (in Portuguese), or null if not applicable.
    """
}
