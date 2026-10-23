//
//  HomeHeroMascotView.swift
//  Venus
//
//  Created by Kaua on 21/09/26.
//

import SwiftUI

struct HomeHeroMascotView: View {
    let userName: String
    let dayMoment: DayMoment
    let streakDays: Int
    let todayMood: MoodType?
    let hasCheckedInToday: Bool
    var customAIGreeting: String? = nil
    let onCheckInTap: () -> Void
    let onChatTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var effectiveMood: MoodType {
        todayMood ?? dayMoment.defaultMascotMood ?? .calm
    }
    
    private var unlockedCosmetic: VenusCosmeticItem {
        if streakDays >= 30 { return .saturnRing }
        if streakDays >= 14 { return .cosmicHeadphones }
        if streakDays >= 7 { return .astralWings }
        if streakDays >= 3 { return .starHalo }
        if dayMoment == .night { return .nightCap }
        return .none
    }
    
    private var currentPhrase: String {
        if let aiGreeting = customAIGreeting, !aiGreeting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return aiGreeting
        }
        
        if !hasCheckedInToday {
            switch dayMoment {
            case .dawn:
                return "Bom dia cedo, \(userName)! 🌅 Como você acordou?"
            case .morning:
                return "Bom dia, \(userName)! ☀️ Como você está começando o seu dia?"
            case .afternoon:
                return "Boa tarde, \(userName)! 🌤️ Como estão as coisas por aí?"
            case .evening:
                return "Boa noite, \(userName)! 🌇 Como foi o seu dia?"
            case .night:
                return "Já é noite, \(userName) 🌙 Que tal desacelerar e refletir um pouco?"
            }
        } else {
            if let mood = todayMood {
                return "Seu check-in de hoje foi registrado como \(mood.rawValue) \(mood.emoji). Estou aqui para o que precisar!"
            } else {
                return "Check-in de hoje concluído! Como posso te apoiar agora?"
            }
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            // Interactive 2.5D Mascot
            VenusMoodOrb(
                mood: effectiveMood,
                state: .idle,
                cosmetic: unlockedCosmetic,
                size: 94,
                showFace: true,
                showHands: true,
                showShadow: true,
                isInteractive: true
            )
            .frame(width: 94, height: 94)
            
            // Contextual Speech Bubble
            VStack(alignment: .leading, spacing: 8) {
                Text(currentPhrase)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.text)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 10) {
                    if !hasCheckedInToday {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onCheckInTap()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Check-in de Hoje")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                VenusTheme.primaryGradient,
                                in: Capsule()
                            )
                            .shadow(color: VenusTheme.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onChatTap()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Conversar")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(VenusTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(VenusTheme.primary.opacity(0.12))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .neumorphicCard(cornerRadius: 22, style: .raised, depth: 6)
        }
    }
}
