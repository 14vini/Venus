//
//  ChatRepository.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol ChatRepositoryProtocol {
    func saveSessions(_ sessions: [ChatSession]) async throws
    func loadSessions() async throws -> [ChatSession]
    func deleteSession(id: UUID) async throws
}

class ChatRepositoryImpl: ChatRepositoryProtocol {
    private let fileManager = FileManager.default
    private let fileName = "chat_sessions.json"
    
    private var fileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }
    
    func saveSessions(_ sessions: [ChatSession]) async throws {
        let data = try JSONEncoder().encode(sessions)
        try data.write(to: fileURL)
    }
    
    func loadSessions() async throws -> [ChatSession] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([ChatSession].self, from: data)
    }
    
    func deleteSession(id: UUID) async throws {
        var sessions = try await loadSessions()
        sessions.removeAll { $0.id == id }
        try await saveSessions(sessions)
    }
}