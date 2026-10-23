//
//  ChatRepositoryImpl.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

final class ChatRepositoryImpl: ChatRepositoryProtocol {
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
    
    func saveSession(_ session: ChatSession) async throws {
        var sessions = (try? await loadSessions()) ?? []
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        try await saveSessions(sessions)
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
