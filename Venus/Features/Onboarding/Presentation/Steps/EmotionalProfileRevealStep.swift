//
//  EmotionalProfileRevealStep.swift
//  Venus
//
//  Created by Kaua on 20/09/26.
//

import SwiftUI

struct EmotionalProfileResult {
    let title: String
    let badge: String
    let subtitle: String
    let strengths: String
    let growthArea: String
    let reassuranceText: String
    let color: Color
    let mascotMood: MoodType
}

struct EmotionalProfileRevealStep: View {
    let userProfile: UserProfile
    var aiProfile: AIOnboardingProfileResponse? = nil
    var onFinish: (() -> Void)? = nil
    
    @State private var cardAppeared = false
    
    private var result: EmotionalProfileResult {
        let name = userProfile.name.isEmpty ? "Você" : userProfile.name
        
        if let ai = aiProfile {
            let color: Color
            let goal = userProfile.primaryGoal
            let mood: MoodType
            if goal.contains("Foco") || userProfile.improvementAreas.contains("Trabalho & Decisões pesadas") {
                color = VenusTheme.accentBlue
                mood = .energetic
            } else if goal.contains("Sono") || userProfile.improvementAreas.contains("Sono & Descanso insuficiente") {
                color = VenusTheme.accentPurple
                mood = .calm
            } else {
                color = VenusTheme.primary
                mood = .happy
            }
            
            return EmotionalProfileResult(
                title: ai.title.isEmpty ? "Seja bem-vindo(a), \(name) 🤍" : ai.title,
                badge: "SEU ESPAÇO ESTÁ PRONTO",
                subtitle: ai.subtitle,
                strengths: ai.strengths,
                growthArea: ai.growthArea,
                reassuranceText: ai.statText.isEmpty ? "Você não precisa carregar tudo sozinho(a). Vamos cuidar de um dia de cada vez." : ai.statText,
                color: color,
                mascotMood: mood
            )
        }
        
        let goal = userProfile.primaryGoal
        
        if goal.contains("Foco") || userProfile.improvementAreas.contains("Trabalho & Decisões pesadas") {
            return EmotionalProfileResult(
                title: "Seja bem-vindo(a), \(name) 🤍",
                badge: "SEU ESPAÇO ESTÁ PRONTO",
                subtitle: "\(name), sua mente tem muita força e vontade de realizar, mas também precisa de pausas.",
                strengths: "Foco, dedicação aos seus objetivos e mente ativa.",
                growthArea: "Proteger seus momentos de descanso e evitar o acúmulo de cobranças ao longo do dia.",
                reassuranceText: "Você não precisa carregar o mundo nas costas. Vamos dar um passo de cada vez.",
                color: VenusTheme.accentBlue,
                mascotMood: .energetic
            )
        } else if goal.contains("Sono") || userProfile.improvementAreas.contains("Sono & Descanso insuficiente") {
            return EmotionalProfileResult(
                title: "Seja bem-vindo(a), \(name) 🤍",
                badge: "SEU ESPAÇO ESTÁ PRONTO",
                subtitle: "\(name), seu corpo tem pedido descanso e sua prioridade agora é recuperar sua vitalidade.",
                strengths: "Sensibilidade, resiliência e busca sincera por equilíbrio.",
                growthArea: "Desacelerar os pensamentos sem culpa e criar uma rotina noturna mais tranquila.",
                reassuranceText: "Aqui você não precisa ter pressa. Este é seu espaço seguro para respirar e descansar.",
                color: VenusTheme.accentPurple,
                mascotMood: .calm
            )
        } else {
            return EmotionalProfileResult(
                title: "Seja bem-vindo(a), \(name) 🤍",
                badge: "SEU ESPAÇO ESTÁ PRONTO",
                subtitle: "\(name), você busca viver com mais leveza e clareza nos seus dias.",
                strengths: "Empatia, constância e vontade de cuidar de quem você é.",
                growthArea: "Perceber seus sentimentos a tempo e ter mais autocompaixão nos dias difíceis.",
                reassuranceText: "Lembre-se: você não precisa dar conta de tudo sozinho(a). Estou aqui com você.",
                color: VenusTheme.primary,
                mascotMood: .happy
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Friendly Welcoming Mascot Header
            VStack(spacing: 8) {
                VenusMoodOrb(
                    mood: result.mascotMood,
                    state: .celebrating,
                    cosmetic: .starHalo,
                    size: 110,
                    showFace: true,
                    showHands: true,
                    showShadow: true,
                    isInteractive: true
                )
                .frame(width: 110, height: 110)
                
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text(result.badge)
                        .font(.system(.caption, design: .rounded).weight(.black))
                }
                .foregroundStyle(result.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: Capsule())
                
                Text(result.title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            
            // Warm Diagnosis Card
            VenusCard(cornerRadius: 28, padding: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(result.subtitle)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(VenusTheme.text)
                        .lineSpacing(3)
                    
                    Divider()
                        .background(Color.white.opacity(0.12))
                    
                    // Strengths
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(result.color)
                            Text("Seus Pontos Fortes")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(VenusTheme.textSecondary)
                        }
                        
                        Text(result.strengths)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundStyle(VenusTheme.text)
                            .lineSpacing(2)
                    }
                    
                    // Growth / Support Focus
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(result.color)
                            Text("Como a Venus vai te apoiar")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(VenusTheme.textSecondary)
                        }
                        
                        Text(result.growthArea)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundStyle(VenusTheme.text)
                            .lineSpacing(2)
                    }
                    
                    // Reassurance Message Box
                    HStack(spacing: 12) {
                        Image(systemName: "hand.raised.heart.fill")
                            .font(.system(size: 22))
                            .foregroundColor(result.color)
                        
                        Text(result.reassuranceText)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(VenusTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(result.color.opacity(0.10))
                    )
                }
            }
            .opacity(cardAppeared ? 1 : 0)
            .scaleEffect(cardAppeared ? 1 : 0.96)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cardAppeared)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cardAppeared = true
            }
        }
    }
}

#Preview {
    EmotionalProfileRevealStep(userProfile: UserProfile(), onFinish: {})
        .background(VenusTheme.backgroundGradient)
}
