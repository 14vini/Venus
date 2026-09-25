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
    let statText: String
    let icon: String
    let color: Color
}

struct EmotionalProfileRevealStep: View {
    let userProfile: UserProfile
    var aiProfile: AIOnboardingProfileResponse? = nil
    let onFinish: () -> Void
    
    @State private var cardAppeared = false
    @State private var statAppeared = false
    
    private var result: EmotionalProfileResult {
        let name = userProfile.name.isEmpty ? "Você" : userProfile.name
        
        if let ai = aiProfile {
            let color: Color
            let goal = userProfile.primaryGoal
            if goal.contains("Foco") || userProfile.improvementAreas.contains("Trabalho & Decisões pesadas") {
                color = VenusTheme.accentBlue
            } else if goal.contains("Sono") || userProfile.improvementAreas.contains("Sono & Descanso não restaurador") {
                color = VenusTheme.accentPurple
            } else {
                color = VenusTheme.primary
            }
            
            return EmotionalProfileResult(
                title: ai.title,
                badge: ai.badge,
                subtitle: ai.subtitle,
                strengths: ai.strengths,
                growthArea: ai.growthArea,
                statText: ai.statText,
                icon: "sparkles",
                color: color
            )
        }
        
        let goal = userProfile.primaryGoal
        
        if goal.contains("Foco") || userProfile.improvementAreas.contains("Trabalho & Decisões pesadas") {
            return EmotionalProfileResult(
                title: "O Estrategista de Alta Demanda",
                badge: "PERFIL DE PRONTIDÃO",
                subtitle: "\(name), sua mente opera em alta intensidade e busca máxima eficiência diária.",
                strengths: "Capacidade analítica, rapidez de raciocínio e forte dedicação.",
                growthArea: "Blindar sua energia contra decisões consecutivas para evitar quedas bruscas no fim do dia.",
                statText: "93% dos usuários com esse perfil aumentam a consistência de foco logo na primeira semana.",
                icon: "bolt.fill",
                color: VenusTheme.accentBlue
            )
        } else if goal.contains("Sono") || userProfile.improvementAreas.contains("Sono & Descanso não restaurador") {
            return EmotionalProfileResult(
                title: "O Restaurador de Energia",
                badge: "PERFIL DE PRONTIDÃO",
                subtitle: "\(name), seu corpo tem acumulado carga e sua prioridade é restaurar sua vitalidade.",
                strengths: "Resiliência, profundidade de reflexão e capacidade de recuperação.",
                growthArea: "Proteger momentos de desaceleração sem culpa e otimizar a qualidade do seu descanso.",
                statText: "96% das pessoas com esse padrão recuperam energia e noites de sono mais tranquilas.",
                icon: "moon.stars.fill",
                color: VenusTheme.accentPurple
            )
        } else {
            return EmotionalProfileResult(
                title: "O Guardião do Equilíbrio",
                badge: "PERFIL DE PRONTIDÃO",
                subtitle: "\(name), você mantém um ritmo constante, mas costuma absorver mais carga do que deveria.",
                strengths: "Empatia, consistência e admirável equilíbrio sob pressão.",
                growthArea: "Identificar quando desacelerar a tempo e preservar sua bateria para o que realmente importa.",
                statText: "94% relatam sensação imediata de clareza e controle do seu ritmo com a Venus.",
                icon: "shield.heart.fill",
                color: VenusTheme.primary
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(result.badge)
                        .font(.system(.caption, design: .rounded).weight(.black))
                }
                .foregroundStyle(result.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .glassEffect(.regular, in: Capsule())
                
                Text(result.title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            
            // Diagnosis Card
            VenusCard(cornerRadius: 28, padding: 22) {
                VStack(alignment: .leading, spacing: 18) {
                    // Subtitle / Diagnosis
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
                    }
                    
                    // Growth / Relief Focus
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(result.color)
                            Text("Foco de Calibração da Venus")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(VenusTheme.textSecondary)
                        }
                        
                        Text(result.growthArea)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundStyle(VenusTheme.text)
                    }
                    
                    // Social Proof / Validation Stat Box
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(result.color)
                        
                        Text(result.statText)
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(VenusTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(result.color.opacity(0.12))
                    )
                }
            }
            .opacity(cardAppeared ? 1 : 0)
            .scaleEffect(cardAppeared ? 1 : 0.94)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cardAppeared)
            
            // Single Final CTA - Enter App Directly
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onFinish()
            } label: {
                HStack(spacing: 10) {
                    Text("Entrar no Meu Espaço")
                        .font(.system(.headline, design: .rounded).weight(.black))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .black))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [result.color, result.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .shadow(color: result.color.opacity(0.35), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cardAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                statAppeared = true
            }
        }
    }
}

#Preview {
    EmotionalProfileRevealStep(userProfile: UserProfile(), onFinish: {})
        .background(VenusTheme.backgroundGradient)
}
