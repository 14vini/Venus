//
//  MoodRepositoryProtocol.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol MoodRepositoryProtocol {
    func save(mood: Mood) async throws
    func getTodayMood() async throws -> Mood?
    func getAllMoods() async throws -> [Mood]
}
