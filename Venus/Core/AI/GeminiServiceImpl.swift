//
//  GeminiServiceImpl.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//
// NOTE: GoogleGenerativeAI package must be added via Swift Package Manager
// URL: https://github.com/google/generative-ai-swift

import Foundation
import GoogleGenerativeAI

class GeminiServiceImpl: GeminiServiceProtocol {
    private let model: GenerativeModel
    
    init(apiKey: String = AppConfig.geminiAPIKey, modelName: String = AppConfig.geminiModel) {
        self.model = GenerativeModel(name: modelName, apiKey: apiKey)
    }
    
    func generateSuggestion(mood: MoodType, userContext: UserProfile) async throws -> String {
        let prompt = buildSuggestionPrompt(mood: mood, userContext: userContext)
        let response = try await model.generateContent(prompt)
        
        guard let text = response.text else {
            throw GeminiError.noResponse
        }
        
        return text
    }
    
    func generateGreeting(userName: String, mood: MoodType?) async throws -> String {
        var prompt = "Crie uma saudação acolhedora e personalizada para \(userName) no app Venus, um assistente de bem-estar."
        
        if let mood = mood {
            prompt += " O usuário está se sentindo \(mood.rawValue) hoje."
        }
        
        prompt += " A saudação deve ser curta (máximo 2 linhas) e calorosa."
        
        let response = try await model.generateContent(prompt)
        
        guard let text = response.text else {
            throw GeminiError.noResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Private Helpers
    
    private func buildSuggestionPrompt(mood: MoodType, userContext: UserProfile) -> String {
        var prompt = """
        Você é o Venus, um assistente de bem-estar terapêutico (mas não terapia).
        
        Usuário: \(userContext.name)
        Humor atual: \(mood.rawValue) (\(mood.emoji))
        
        Interesses: \(userContext.interests.joined(separator: ", "))
        Hobbies atuais: \(userContext.currentHobbies.joined(separator: ", "))
        Áreas de melhoria: \(userContext.improvementAreas.joined(separator: ", "))
        
        Com base no humor e perfil do usuário, sugira UMA atividade específica e personalizada que:
        1. Ajude com o humor atual
        2. Se alinhe com os interesses dele
        3. Seja prática e possível de fazer agora
        
        Responda em formato curto (máximo 3 linhas), começando direto com a sugestão.
        Exemplo: "Que tal fazer uma respiração 4-7-8 por 5 minutos? Vai ajudar a acalmar a ansiedade."
        """
        
        return prompt
    }
}

enum GeminiError: Error {
    case noResponse
    case invalidResponse
}
