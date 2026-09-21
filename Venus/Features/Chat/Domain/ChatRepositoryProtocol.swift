//
//  ChatRepositoryProtocol.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol ChatRepositoryProtocol: Sendable {
    func saveSessions(_ sessions: [ChatSession]) async throws
    func loadSessions() async throws -> [ChatSession]
    func deleteSession(id: UUID) async throws
}
