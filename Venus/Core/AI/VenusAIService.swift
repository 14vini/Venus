//
//  VenusAIService.swift
//  Venus
//
//  Enhanced AI service for Venus conversational capabilities
//

import Foundation
import GoogleGenerativeAI

protocol VenusAIServiceProtocol {
    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?
    ) async throws -> String
    
    func analyzeEmotionalState(message: String) async throws -> EmotionalState
    func generateWellnessSuggestion(emotionalState: EmotionalState) -> String
}

class VenusAIService: VenusAIServiceProtocol {
    private let model: GenerativeModel
    private let conversationMemory = ConversationMemory()
    private let contextManager = ConversationContextManager()
    
    init(apiKey: String = AppConfig.geminiAPIKey) {
        self.model = GenerativeModel(
            name: AppConfig.geminiModel,
            apiKey: apiKey,
            systemInstruction: ModelContent(role: "system", parts: [
                ModelContent.Part.text(VenusSystemPrompt.fullPrompt)
            ])
        )
    }
    
    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?
    ) async throws -> String {
        
        // Update conversation memory
        conversationMemory.addMessage(userMessage, isFromUser: true)
        
        // Convert history to ModelContent for Gemini
        var historyContent = try conversationHistory.suffix(30).map { message in
            try ModelContent(role: message.isFromUser ? "user" : "model", parts: [.text(message.content)])
        }
        
        // Remove the last message from history if it's the one we just appended in ViewModel
        if let last = historyContent.last, last.role == "user" && conversationHistory.last?.content == userMessage {
             historyContent.removeLast()
        }

        let context = buildContextString(profile: userProfile)
        let finalPrompt = context + userMessage
        
        do {
            let chat = model.startChat(history: historyContent)
            let response = try await chat.sendMessage(finalPrompt)
            
            guard let text = response.text else {
                throw VenusAIError.noResponse
            }
            
            let cleanResponse = cleanResponse(text)
            conversationMemory.addMessage(cleanResponse, isFromUser: false)
            
            return cleanResponse
        } catch {
            print("DEBUG: Gemini API Error: \(error)")
            print("DEBUG: Falling back to hardcoded responses")
            // Fallback to contextual hardcoded responses
            return generateFallbackResponse(userMessage: userMessage, history: conversationHistory)
        }
    }
    
    func analyzeEmotionalState(message: String) async throws -> EmotionalState {
        let prompt = """
        Analyze the emotional state of this message and respond with ONLY a JSON object:
        
        Message: "\(message)"
        
        Response format:
        {
            "primary_emotion": "happy|sad|anxious|angry|neutral|excited|frustrated|lonely|stressed|grateful",
            "intensity": 1-10,
            "needs_support": true/false,
            "keywords": ["word1", "word2"]
        }
        """
        
        do {
            let response = try await model.generateContent(prompt)
            guard let text = response.text else {
                return EmotionalState.neutral()
            }
            
            return try parseEmotionalState(from: text)
        } catch {
            return analyzeEmotionalStateFallback(message: message)
        }
    }
    
    func generateWellnessSuggestion(emotionalState: EmotionalState) -> String {
        switch emotionalState.primaryEmotion {
        case .anxious:
            return "Que tal tentarmos uma respiração 4-7-8? Inspire por 4, segure por 7, expire por 8. Isso pode ajudar a acalmar a ansiedade. 🌸"
        case .sad:
            return "Às vezes é importante honrar nossos sentimentos. Que tal escrever três coisas pelas quais você é grato hoje? 💙"
        case .stressed:
            return "O estresse pode ser intenso. Tente fazer uma pausa de 5 minutos - respire fundo ou ouça uma música que te acalma. ✨"
        case .lonely:
            return "A solidão é difícil. Lembre-se que você não está sozinho. Que tal ligar para alguém querido ou dar uma caminhada? 🤗"
        case .angry:
            return "A raiva é válida. Que tal tentar contar até 10 devagar ou fazer alguns alongamentos para liberar essa energia? 🔥"
        case .frustrated:
            return "Frustração acontece. Às vezes ajuda dar um passo para trás e ver a situação de outro ângulo. Respire fundo. 💪"
        case .excited:
            return "Que energia maravilhosa! Aproveite esse momento positivo e talvez compartilhe essa alegria com alguém especial. ⭐"
        case .grateful:
            return "Gratidão é transformadora! Que tal anotar esse sentimento em um diário ou fazer algo gentil por você mesmo? 🙏"
        default:
            return "Como você está se sentindo agora? Estou aqui para conversar sobre qualquer coisa que esteja em sua mente. 💜"
        }
    }
    
    // MARK: - Private Methods
    
    private func buildContextString(profile: UserProfile?) -> String {
        var context = ""
        
        // Add user profile context
        if let profile = profile {
            context += "[Info do Perfil: "
            context += "Nome: \(profile.name), "
            context += "Interesses: \(profile.interests.joined(separator: ", ")), "
            context += "Áreas de melhoria: \(profile.improvementAreas.joined(separator: ", "))"
            context += "] "
        }
        
        // Add conversation memory insights
        let memoryInsights = conversationMemory.getRecentInsights()
        if !memoryInsights.isEmpty {
            context += "[Insights Anteriores: \(memoryInsights.joined(separator: ", "))] "
        }

        if !context.isEmpty {
            context += "\n\n"
        }
        
        return context
    }
    
    private func generateFallbackResponse(userMessage: String, history: [ChatMessage]) -> String {
        let lowercased = userMessage.lowercased()
        
        // Context-aware fallback responses
        let recentTopics = history.suffix(4).map { $0.content.lowercased() }.joined(separator: " ")
        
        if lowercased.contains("ansiedade") || lowercased.contains("ansioso") {
            if recentTopics.contains("respiração") {
                return "Vejo que a ansiedade ainda está presente. Além da respiração, que tal tentarmos uma técnica de grounding? Nomeie 5 coisas que você vê, 4 que você ouve, 3 que você toca. 🌸"
            }
            return "Entendo sua ansiedade. Vamos tentar juntos: respire fundo por 4 segundos, segure por 4, e solte por 6. Repita algumas vezes. 🌸"
        }
        
        if lowercased.contains("triste") || lowercased.contains("tristeza") {
            return "Sua tristeza é válida e importante. Às vezes precisamos sentir para curar. Que tal escrever sobre o que está sentindo ou ouvir uma música que te conforta? 💙"
        }
        
        if lowercased.contains("estresse") || lowercased.contains("estressado") {
            return "O estresse pode ser avassalador. Que tal fazer uma pausa de 5 minutos? Levante-se, estique o corpo, ou simplesmente respire conscientemente. ✨"
        }
        
        if lowercased.contains("obrigado") || lowercased.contains("obrigada") {
            return "Fico muito feliz em poder estar aqui com você! Lembre-se: você é mais forte do que imagina. 💜"
        }
        
        // Default empathetic response with suggestion
        let responses = [
            "Obrigada por compartilhar isso comigo. Como você está se sentindo agora? Que tal fazermos uma respiração consciente juntos? 🌱",
            "Entendo. Às vezes ajuda colocar os pensamentos para fora. Que tal escrever sobre o que está passando pela sua mente? ✍️",
            "Estou aqui para você. Que tal começarmos com três respirações profundas para nos centrarmos? 💙"
        ]
        
        return responses.randomElement() ?? "Como posso te ajudar hoje? 💜"
    }
    
    private func cleanResponse(_ response: String) -> String {
        return response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
    }
    
    private func parseEmotionalState(from jsonString: String) throws -> EmotionalState {
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return EmotionalState.neutral()
        }
        
        let emotionString = json["primary_emotion"] as? String ?? "neutral"
        let intensity = json["intensity"] as? Int ?? 5
        let needsSupport = json["needs_support"] as? Bool ?? false
        let keywords = json["keywords"] as? [String] ?? []
        
        let emotion = EmotionType(rawValue: emotionString) ?? .neutral
        
        return EmotionalState(
            primaryEmotion: emotion,
            intensity: intensity,
            needsSupport: needsSupport,
            keywords: keywords
        )
    }
    
    private func analyzeEmotionalStateFallback(message: String) -> EmotionalState {
        let lowercased = message.lowercased()
        
        let emotionKeywords: [(EmotionType, [String])] = [
            (.anxious, ["ansiedade", "ansioso", "nervoso", "preocupado", "medo"]),
            (.sad, ["triste", "tristeza", "deprimido", "melancolia", "chateado"]),
            (.angry, ["raiva", "irritado", "furioso", "bravo", "ódio"]),
            (.stressed, ["estresse", "estressado", "pressão", "sobrecarregado"]),
            (.lonely, ["sozinho", "solidão", "isolado", "abandonado"]),
            (.excited, ["animado", "empolgado", "feliz", "alegre", "eufórico"]),
            (.grateful, ["grato", "agradecido", "obrigado", "gratidão"])
        ]
        
        for (emotion, keywords) in emotionKeywords {
            if keywords.contains(where: { lowercased.contains($0) }) {
                let intensity = lowercased.contains("muito") || lowercased.contains("extremamente") ? 8 : 6
                return EmotionalState(
                    primaryEmotion: emotion,
                    intensity: intensity,
                    needsSupport: [.anxious, .sad, .angry, .stressed, .lonely].contains(emotion),
                    keywords: keywords.filter { lowercased.contains($0) }
                )
            }
        }
        
        return EmotionalState.neutral()
    }
}

// MARK: - Supporting Types

enum VenusAIError: Error {
    case noResponse
    case invalidResponse
    case networkError
}

enum EmotionType: String, CaseIterable {
    case happy, sad, anxious, angry, neutral, excited, frustrated, lonely, stressed, grateful
}

struct EmotionalState {
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

class ConversationMemory {
    private var messages: [(String, Bool)] = [] // (content, isFromUser)
    private var insights: Set<String> = []
    private let maxMessages = 20
    
    func addMessage(_ content: String, isFromUser: Bool) {
        messages.append((content, isFromUser))
        
        if messages.count > maxMessages {
            messages.removeFirst()
        }
        
        if isFromUser {
            extractInsights(from: content)
        }
    }
    
    func getRecentInsights() -> [String] {
        return Array(insights.suffix(5))
    }
    
    private func extractInsights(from content: String) {
        let lowercased = content.lowercased()
        
        let insightPatterns = [
            ("trabalho", "Mencionou trabalho"),
            ("família", "Falou sobre família"),
            ("relacionamento", "Discutiu relacionamentos"),
            ("saúde", "Preocupações com saúde"),
            ("futuro", "Ansiedade sobre o futuro"),
            ("passado", "Reflexões sobre o passado")
        ]
        
        for (keyword, insight) in insightPatterns {
            if lowercased.contains(keyword) {
                insights.insert(insight)
            }
        }
    }
}

struct VenusSystemPrompt {
    static let fullPrompt = """
    You are Venus, a supportive, emotionally intelligent conversational AI designed to help users feel better, not to provide therapy, diagnosis, or medical advice.

    Venus is not a therapist and does not replace professional mental health care.
    Your role is to offer presence, understanding, grounding, and gentle emotional support.

    Conversation Style
    • Talk in a human, warm, and natural way.
    • Be emotionally aware, validating, and present.
    • Adapt your tone to what the user asks for:
    • If the user wants gentle, be gentle.
    • If the user wants direct or harsh, be firm but respectful.
    • If the user wants a neutral or casual chat, match that energy.
    • Never judge, shame, or dismiss the user's feelings.
    • Do not use dirty talk, sexual explicit content, inappropriate language can be allowed.

    Topics
    The user may talk about:
    • Their feelings or emotions
    • Their day
    • Stress, anxiety, anger, sadness, loneliness
    • Past experiences or memories
    • Daily life, relationships, thoughts, or random topics

    As long as the content is respectful and non-explicit, Venus can talk about anything, but if is something explict but normal to talk like trying to quit pornograph, it's allowed.

    Crisis-Safe Handling (Very Important)
    If a user expresses extreme distress, despair, or hints of self-harm:
    • Stay calm, present, and compassionate
    • Validate their feelings without validating harmful actions
    • Do not provide instructions, methods, or analysis
    • Do not panic or use alarmist language
    • Do not claim to be the only support

    Venus should:
    • Encourage reaching out to trusted people (friends, family)
    • Encourage seeking local professional or emergency support
    • Use gentle, supportive language (never commanding)

    Example tone:
    "I'm really glad you told me this. You don't have to go through it alone. If things feel overwhelming right now, reaching out to someone you trust or a local support service could really help."

    Only suggest emergency services when the situation clearly indicates risk.

    Core Rule (Non-Negotiable)
    Every response must end with at least one gentle suggestion that could help the user feel a little better.

    Suggestions should feel like:
    • "Hey, maybe try this"
    • Not instructions, not therapy
    • Simple, low-effort, doable right now

    Examples:
    • Breathing or grounding exercises
    • Small relaxation practices
    • Writing or reflection prompts
    • Gentle movement or stretching
    • Gratitude or perspective shifts
    • Short mental resets
    • Comfort actions (music, rest, water, stepping outside)
    • Emotional release ideas (journaling, crying safely, talking it out)
    • Motivation or reassurance (without toxic positivity)
    • Take one slow breath with me
    • Stretch your shoulders or unclench your jaw
    • Put on one song that feels safe
    • Drink some water
    • Step outside for 2 minutes
    • Write one sentence about what you're feeling
    • Put your phone down for a moment and rest your eyes

    Relief > fixing.
    """
}