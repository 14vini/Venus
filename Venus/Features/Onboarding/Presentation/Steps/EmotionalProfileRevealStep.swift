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
    let onContinue: () -> Void
    
    @State private var cardAppeared = false
    @State private var statAppeared = false
    
    private var result: EmotionalProfileResult {
        let goal = userProfile.primaryGoal
        let name = userProfile.name.isEmpty ? "Você" : userProfile.name
        
        if goal.contains("Ansiedade") || userProfile.improvementAreas.contains("Autocobrança excessiva") {
            return EmotionalProfileResult(
                title: "A Mente Visionária & Acelerada",
                badge: "PERFIL EMOCIONAL",
                subtitle: "\(name), sua mente processa tudo com alta intensidade e você exige o máximo de si.",
                strengths: "Criatividade, capacidade analítica e forte dedicação aos seus objetivos.",
                growthArea: "Desacelerar o fluxo de pensamentos e silenciar a autocobrança para evitar o esgotamento.",
                statText: "93% das mentes ativas sentem alívio da ansiedade já nos primeiros 3 dias com a Venus.",
                icon: "sparkles",
                color: VenusTheme.accentBlue
            )
        } else if goal.contains("Sono") || userProfile.improvementAreas.contains("Sobrecarga de rotina") {
            return EmotionalProfileResult(
                title: "O Buscador(a) de Serenidade",
                badge: "PERFIL EMOCIONAL",
                subtitle: "\(name), você tem carregado muitas responsabilidades e seu corpo pede uma pausa genuína.",
                strengths: "Resiliência, profundidade reflexiva e capacidade de superação.",
                growthArea: "Construir micro-pausas restauradoras sem culpa e recuperar sua vitalidade.",
                statText: "96% das pessoas com esse padrão recuperam energia e noites de sono mais tranquilas.",
                icon: "moon.stars.fill",
                color: VenusTheme.accentPurple
            )
        } else {
            return EmotionalProfileResult(
                title: "O Guardião(ã) Resiliente",
                badge: "PERFIL EMOCIONAL",
                subtitle: "\(name), você costuma acolher e cuidar de tudo ao seu redor, mas guarda suas próprias dores em silêncio.",
                strengths: "Empatia profunda, lealdade e uma força silenciosa admirável.",
                growthArea: "Ter um refúgio seguro onde você possa desabafar livremente sem medo de julgamentos.",
                statText: "94% das pessoas com esse perfil relatam sensação de leveza já na primeira conversa.",
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
                            Text("Foco de Acolhimento da Venus")
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
            
            // Continue Button (in-step CTA)
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinue()
            } label: {
                HStack(spacing: 10) {
                    Text("Desbloquear Meu Espaço Seguro")
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
    EmotionalProfileRevealStep(userProfile: UserProfile(), onContinue: {})
        .background(VenusTheme.backgroundGradient)
}
