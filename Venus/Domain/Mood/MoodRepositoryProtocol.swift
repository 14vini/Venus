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
    func getMoodCount(on date: Date) async throws -> Int
    func getAllMoods() async throws -> [Mood]
    func getMoods(from startDate: Date, to endDate: Date) async throws -> [Mood]
}
