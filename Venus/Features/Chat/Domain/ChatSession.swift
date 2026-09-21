//
//  ChatSession.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct ChatSession: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var title: String
    var createdAt: Date
    var lastMessageAt: Date
    var messages: [ChatMessage]
    var userInsights: [String]
    
    init(
        id: UUID = UUID(),
        title: String = "Nova Conversa",
        createdAt: Date = Date(),
        lastMessageAt: Date = Date(),
        messages: [ChatMessage] = [],
        userInsights: [String] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
        self.messages = messages
        self.userInsights = userInsights
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

struct ChatMessage: Identifiable, Codable, Sendable, Equatable {
    var id: UUID
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var reaction: String?
    var replyToId: UUID?
    var replyToContent: String?
    
    // AI-generated check-in metadata
    var summary: String?
    var tags: [String]?
    var reminder: String?
    
    init(
        id: UUID = UUID(),
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        reaction: String? = nil,
        replyToId: UUID? = nil,
        replyToContent: String? = nil,
        summary: String? = nil,
        tags: [String]? = nil,
        reminder: String? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.reaction = reaction
        self.replyToId = replyToId
        self.replyToContent = replyToContent
        self.summary = summary
        self.tags = tags
        self.reminder = reminder
    }
}
