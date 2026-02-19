//
//  ChatSession.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct ChatSession: Identifiable, Codable {
    let id = UUID()
    let title: String
    let createdAt: Date
    var lastMessageAt: Date
    var messages: [ChatMessage]
    var userInsights: [String]
    
    init(title: String = "Nova Conversa") {
        self.title = title
        self.createdAt = Date()
        self.lastMessageAt = Date()
        self.messages = []
        self.userInsights = []
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastMessageAt = Date()
        
        if message.isFromUser {
            extractInsights(from: message.content)
        }
    }
    
    private mutating func extractInsights(from content: String) {
        let lowercased = content.lowercased()
        
        let difficulties = [
            ("ansiedade", "Relatou ansiedade"),
            ("estresse", "Mencionou estresse"),
            ("insônia", "Dificuldades com sono"),
            ("tristeza", "Expressou tristeza"),
            ("cansaço", "Relatou cansaço"),
            ("solidão", "Mencionou solidão")
        ]
        
        for (keyword, insight) in difficulties {
            if lowercased.contains(keyword) && !userInsights.contains(insight) {
                userInsights.append(insight)
            }
        }
    }
    
    var summary: String {
        let userMessages = messages.filter { $0.isFromUser }.count
        return "\(userMessages) mensagens • \(userInsights.count) insights"
    }
}

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(content: String, isFromUser: Bool) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
}