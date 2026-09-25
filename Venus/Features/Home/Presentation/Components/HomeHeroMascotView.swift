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
    
    @State private var quoteIndex: Int = 0
    @State private var isBouncingQuote: Bool = false
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
    
    private var phrases: [String] {
        var list: [String] = []
        
        if let aiGreeting = customAIGreeting, !aiGreeting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list.append(aiGreeting)
        }
        
        if !hasCheckedInToday {
            switch dayMoment {
            case .dawn:
                list.append("Bom dia cedo, \(userName)! 🌅 Como você acordou?")
            case .morning:
                list.append("Bom dia, \(userName)! ☀️ Como você está começando o seu dia?")
            case .afternoon:
                list.append("Boa tarde, \(userName)! 🌤️ Como estão as coisas por aí?")
            case .evening:
                list.append("Boa noite, \(userName)! 🌇 Como foi o seu dia?")
            case .night:
                list.append("Já é noite, \(userName) 🌙 Que tal desacelerar e refletir um pouco?")
            }
            list.append("Dedique 1 minutinho para você hoje. Seu ritual está pronto!")
        } else {
            if let mood = todayMood {
                list.append("Seu check-in de hoje foi registrado como \(mood.rawValue) \(mood.emoji). Estou aqui para o que precisar!")
            } else {
                list.append("Check-in de hoje concluído! Como posso te apoiar agora?")
            }
            list.append("Se quiser desabafar ou refletir, é só me chamar no chat ✨")
        }
        
        if streakDays >= 3 {
            list.append("🔥 Incrível! Você está em uma sequência de \(streakDays) dias de autoconhecimento.")
        }
        
        list.append("Dica: Toque em mim duas vezes para um salto mortal ou faça cafuné! 💖")
        
        return list
    }
    
    private var currentPhrase: String {
        guard !phrases.isEmpty else { return "Olá, \(userName)!" }
        return phrases[quoteIndex % phrases.count]
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
                    .foregroundColor(colorScheme == .dark ? .white : VenusTheme.text)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText())
                
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
                    
                    // Tap to cycle hint
                    Button(action: cycleQuote) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(VenusTheme.textSecondary.opacity(0.75))
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(VenusTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.18 : 0.60),
                                        VenusTheme.cardBorder.opacity(colorScheme == .dark ? 0.0 : 0.6),
                                        Color.white.opacity(colorScheme == .dark ? 0.06 : 0.30)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 10, x: 0, y: 4)
            .scaleEffect(isBouncingQuote ? 0.97 : 1.0)
            .onTapGesture {
                cycleQuote()
            }
        }
        .padding(.vertical, 6)
    }
    
    private func cycleQuote() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isBouncingQuote = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            quoteIndex += 1
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isBouncingQuote = false
            }
        }
    }
}

#Preview {
    ZStack {
        VenusTheme.backgroundGradient.ignoresSafeArea()
        HomeHeroMascotView(
            userName: "Kauã",
            dayMoment: .morning,
            streakDays: 7,
            todayMood: .happy,
            hasCheckedInToday: false,
            onCheckInTap: {},
            onChatTap: {}
        )
        .padding(20)
    }
}
