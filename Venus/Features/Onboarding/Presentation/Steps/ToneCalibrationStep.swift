//
//  ToneCalibrationStep.swift
//  Venus
//
//  Created by Kaua on 20/09/26.
//

import SwiftUI

private struct ToneCardItem: Identifiable {
    let id: String
    let title: String
    let badge: String
    let quote: String
    let systemImage: String
    let toneValue: String
    let gradientColors: [Color]
    let mood: MoodType
}

struct ToneCalibrationStep: View {
    @Binding var userProfile: UserProfile
    
    private let toneCards: [ToneCardItem] = [
        ToneCardItem(
            id: "gentle",
            title: "Acolhedora & Gentil",
            badge: "EMPATIA & SUPORTE",
            quote: "“Tudo bem não estar 100% hoje. Respira com calma, eu tô aqui com você.”",
            systemImage: "heart.bubble.fill",
            toneValue: "Gentil",
            gradientColors: [VenusTheme.primary, VenusTheme.accentGreen],
            mood: .calm
        ),
        ToneCardItem(
            id: "direct",
            title: "Direta & Prática",
            badge: "CLAREZA & FOCO",
            quote: "“Vamos simplificar isso: qual é a única coisa que podemos resolver agora?”",
            systemImage: "bolt.shield.fill",
            toneValue: "Direto",
            gradientColors: [VenusTheme.accentOrange, VenusTheme.accentPink],
            mood: .energetic
        ),
        ToneCardItem(
            id: "reflective",
            title: "Reflexiva & Socrática",
            badge: "AUTODESCOBERTA",
            quote: "“O que você sente que essa situação está tentando te ensinar sobre seus limites?”",
            systemImage: "brain.head.profile",
            toneValue: "Prático",
            gradientColors: [VenusTheme.accentPurple, VenusTheme.accentBlue],
            mood: .happy
        ),
        ToneCardItem(
            id: "motivational",
            title: "Motivadora & Vibrante",
            badge: "IMPULSO & ÂNIMO",
            quote: "“Você é mais forte do que esse momento. Vamos dar um passo de cada vez!”",
            systemImage: "flame.fill",
            toneValue: "Motivacional",
            gradientColors: [VenusTheme.accentPink, VenusTheme.accentOrange],
            mood: .energetic
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingStepHeader(
                eyebrow: "sintonia",
                title: "Como a Venus deve conversar com você?",
                subtitle: "Toque para escolher a voz que mais te traz clareza e ritmo.",
                systemImage: "waveform.and.sparkles",
                tint: VenusTheme.accentOrange,
                accessory: userProfile.coachingTone.isEmpty ? nil : userProfile.coachingTone
            )
            
            VStack(spacing: 14) {
                ForEach(toneCards) { card in
                    toneCardView(card: card)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .onAppear {
            if userProfile.coachingTone.isEmpty {
                userProfile.coachingTone = "Gentil"
            }
            if userProfile.dailyTimeBudgetMinutes == 0 {
                userProfile.dailyTimeBudgetMinutes = 5
            }
        }
    }
    
    private func toneCardView(card: ToneCardItem) -> some View {
        let isSelected = userProfile.coachingTone == card.toneValue
        
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                userProfile.coachingTone = card.toneValue
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header of card
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                isSelected ?
                                LinearGradient(colors: card.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: card.systemImage)
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(isSelected ? .white : VenusTheme.text)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.badge)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(isSelected ? card.gradientColors.first ?? VenusTheme.accentOrange : VenusTheme.textSecondary)
                        
                        Text(card.title)
                            .font(.system(.headline, design: .rounded).weight(.black))
                            .foregroundStyle(VenusTheme.text)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(isSelected ? card.gradientColors.first ?? VenusTheme.primary : Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(card.gradientColors.first ?? VenusTheme.primary)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                
                // Quote bubble preview
                HStack(alignment: .top, spacing: 10) {
                    Rectangle()
                        .fill(isSelected ? card.gradientColors.first ?? VenusTheme.primary : Color.white.opacity(0.2))
                        .frame(width: 3)
                        .cornerRadius(1.5)
                    
                    Text(card.quote)
                        .font(.system(.subheadline, design: .rounded).italic())
                        .foregroundStyle(isSelected ? VenusTheme.text : VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                .padding(.top, 2)
            }
            .padding(18)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (card.gradientColors.first ?? VenusTheme.accentOrange).opacity(0.18),
                                    (card.gradientColors.last ?? VenusTheme.accentPink).opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(card.gradientColors.first ?? VenusTheme.accentOrange, lineWidth: 1.5)
                        )
                }
            }
            .glassEffect(isSelected ? .clear : .regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: isSelected ? (card.gradientColors.first ?? VenusTheme.accentOrange).opacity(0.16) : .clear, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ToneCalibrationStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
