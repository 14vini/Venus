//
//  ConversationContextManager.swift
//  Venus
//
//  Manages conversation context and memory for personalized interactions
//

import Foundation

class ConversationContextManager {
    private var conversationTopics: Set<String> = []
    private var emotionalPatterns: [EmotionType: Int] = [:]
    private var userPreferences: [String: Any] = [:]
    private var sessionInsights: [String] = []
    
    // MARK: - Topic Tracking
    
    func addTopic(_ topic: String) {
        conversationTopics.insert(topic.lowercased())
    }
    
    func hasDiscussedTopic(_ topic: String) -> Bool {
        return conversationTopics.contains(topic.lowercased())
    }
    
    func getRecentTopics() -> [String] {
        return Array(conversationTopics.suffix(5))
    }
    
    // MARK: - Emotional Pattern Tracking
    
    func recordEmotion(_ emotion: EmotionType) {
        emotionalPatterns[emotion, default: 0] += 1
    }
    
    func getDominantEmotion() -> EmotionType? {
        return emotionalPatterns.max(by: { $0.value < $1.value })?.key
    }
    
    func getEmotionalTrend() -> String {
        let totalEmotions = emotionalPatterns.values.reduce(0, +)
        guard totalEmotions > 0 else { return "Ainda conhecendo você" }
        
        let positiveEmotions: Set<EmotionType> = [.happy, .excited, .grateful]
        let challengingEmotions: Set<EmotionType> = [.sad, .anxious, .angry, .stressed, .lonely, .frustrated]
        
        let positiveCount = emotionalPatterns.filter { positiveEmotions.contains($0.key) }.values.reduce(0, +)
        let challengingCount = emotionalPatterns.filter { challengingEmotions.contains($0.key) }.values.reduce(0, +)
        
        let positiveRatio = Double(positiveCount) / Double(totalEmotions)
        
        if positiveRatio > 0.6 {
            return "Você tem mostrado muita positividade!"
        } else if positiveRatio < 0.3 {
            return "Percebo que você tem enfrentado alguns desafios emocionais"
        } else {
            return "Você tem equilibrado bem seus altos e baixos"
        }
    }
    
    // MARK: - User Preferences
    
    func setPreference(key: String, value: Any) {
        userPreferences[key] = value
    }
    
    func getPreference(key: String) -> Any? {
        return userPreferences[key]
    }
    
    // MARK: - Session Insights
    
    func addInsight(_ insight: String) {
        if !sessionInsights.contains(insight) {
            sessionInsights.append(insight)
        }
    }
    
    func getSessionInsights() -> [String] {
        return sessionInsights
    }
    
    // MARK: - Contextual Response Generation
    
    func generateContextualGreeting() -> String? {
        let recentTopics = getRecentTopics()
        let dominantEmotion = getDominantEmotion()
        
        if recentTopics.contains("trabalho") && dominantEmotion == .stressed {
            return "Oi! Como tem sido o trabalho desde nossa última conversa?"
        }
        
        if recentTopics.contains("ansiedade") {
            return "Olá! Como você está se sentindo em relação à ansiedade hoje?"
        }
        
        if let emotion = dominantEmotion {
            switch emotion {
            case .sad:
                return "Oi! Espero que você esteja se sentindo um pouco melhor hoje."
            case .anxious:
                return "Olá! Como está sua respiração hoje? Lembra dos exercícios que praticamos?"
            case .happy:
                return "Oi! Que bom te ver novamente! Como está essa energia positiva?"
            default:
                break
            }
        }
        
        return nil
    }
    
    func shouldSuggestProfessionalHelp() -> Bool {
        let challengingEmotions: Set<EmotionType> = [.sad, .anxious, .angry, .stressed]
        let challengingCount = emotionalPatterns.filter { challengingEmotions.contains($0.key) }.values.reduce(0, +)
        let totalEmotions = emotionalPatterns.values.reduce(0, +)
        
        guard totalEmotions >= 5 else { return false }
        
        let challengingRatio = Double(challengingCount) / Double(totalEmotions)
        return challengingRatio > 0.7
    }
    
    // MARK: - Reset and Cleanup
    
    func resetSession() {
        sessionInsights.removeAll()
    }
    
    func clearAllData() {
        conversationTopics.removeAll()
        emotionalPatterns.removeAll()
        userPreferences.removeAll()
        sessionInsights.removeAll()
    }
}

// MARK: - Topic Extraction Helper

extension ConversationContextManager {
    func extractTopicsFromMessage(_ message: String) {
        let lowercased = message.lowercased()
        
        let topicKeywords = [
            "trabalho": ["trabalho", "emprego", "chefe", "colega", "escritório", "reunião"],
            "família": ["família", "pai", "mãe", "irmão", "irmã", "filho", "filha", "parente"],
            "relacionamento": ["namorado", "namorada", "marido", "esposa", "relacionamento", "amor"],
            "saúde": ["saúde", "médico", "hospital", "doença", "dor", "sintoma"],
            "estudos": ["escola", "universidade", "prova", "estudar", "curso", "faculdade"],
            "dinheiro": ["dinheiro", "financeiro", "conta", "salário", "gasto", "economia"],
            "futuro": ["futuro", "planos", "objetivo", "meta", "sonho", "carreira"]
        ]
        
        for (topic, keywords) in topicKeywords {
            if keywords.contains(where: { lowercased.contains($0) }) {
                addTopic(topic)
            }
        }
    }
}