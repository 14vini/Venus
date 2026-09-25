//
//  GalaxyStar.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import SwiftUI

/// Represents a single check-in node (star) in the user's emotional constellation.
struct GalaxyStar: Identifiable, Sendable {
    let id: UUID
    let mood: Mood
    let date: Date
    let moodType: MoodType
    let intensity: Int
    let energyLevel: MoodEnergyLevel?
    let note: String?
    let triggers: [String]
    
    // Normalized celestial coordinates in canvas space (0.0 to 1.0)
    var position: CGPoint
    var size: CGFloat
    
    init(mood: Mood, index: Int, total: Int) {
        self.id = mood.id
        self.mood = mood
        self.date = mood.timestamp
        self.moodType = mood.type
        self.intensity = mood.intensity ?? 5
        self.energyLevel = mood.energyLevel
        self.note = mood.note
        self.triggers = mood.triggers
        
        // Star size based on intensity & energy
        let baseSize: CGFloat = 16
        let intensityFactor = CGFloat(self.intensity) / 10.0
        self.size = baseSize + (intensityFactor * 12)
        
        // Position generation along an organic cosmic ribbon
        let progress = total > 1 ? CGFloat(index) / CGFloat(total - 1) : 0.5
        let marginX: CGFloat = 0.12
        let marginY: CGFloat = 0.18
        
        let x = marginX + (progress * (1.0 - 2 * marginX))
        
        // Harmonic organic wave for height variation
        let wave = sin(progress * .pi * 2.4 + CGFloat(index) * 0.4)
        let moodVerticalOffset: CGFloat
        switch mood.type {
        case .energetic, .happy: moodVerticalOffset = -0.15
        case .calm: moodVerticalOffset = -0.05
        case .tired: moodVerticalOffset = 0.10
        case .stressed, .sad: moodVerticalOffset = 0.15
        }
        
        let y = 0.50 + (wave * 0.22) + (moodVerticalOffset * 0.5)
        let clampedY = min(max(y, marginY), 1.0 - marginY)
        
        self.position = CGPoint(x: x, y: clampedY)
    }
    
    var starColor: Color {
        switch moodType {
        case .happy:
            return Color(hex: "59D85A")
        case .calm:
            return Color(hex: "6DCFF5")
        case .energetic:
            return Color(hex: "FFE44A")
        case .stressed:
            return Color(hex: "FF9A6C")
        case .sad:
            return Color(hex: "7FA8F5")
        case .tired:
            return Color(hex: "B89AF5")
        }
    }
    
    var glowColors: [Color] {
        [starColor.opacity(0.8), starColor.opacity(0.3), Color.clear]
    }
}
