//
//  MirrorInsightView.swift
//  Venus
//

import SwiftUI

struct MirrorInsightView: View {
    let weeklyTrend: WeeklyEmotionalTrend?
    let weeklyInsights: WeeklyStrategicInsights?
    let patternAlert: PatternAlert?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var hasEnoughData: Bool {
        guard let trend = weeklyTrend else { return false }
        return !trend.summary.contains("Ainda estou")
    }

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.moodMintStrong,
                secondaryAccent: VenusTheme.moodSage,
                tertiaryAccent: VenusTheme.accentGreen,
                isAnimated: true
            )

            VStack(spacing: 0) {
                // Header (Close Button)
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(VenusTheme.textSecondary)
                            .padding(12)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                if hasEnoughData {
                    // Detailed Dashboard
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Main Title
                            VStack(spacing: 8) {
                                Text("O Espelho")
                                    .font(.system(.subheadline, design: .rounded).weight(.black))
                                    .foregroundColor(VenusTheme.moodMintStrong)
                                    .tracking(1.5)
                                    .textCase(.uppercase)

                                Text("Reflexão do seu Cérebro")
                                    .font(.system(.title2, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.text)
                            }
                            .padding(.top, 10)

                            // 1. Weekly Trend Card
                            if let trend = weeklyTrend {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(VenusTheme.moodMintStrong.opacity(0.15))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: trend.direction.iconName)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(VenusTheme.moodMintStrong)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(trend.direction.title)
                                                .font(.system(.headline, design: .rounded).weight(.bold))
                                                .foregroundColor(VenusTheme.text)
                                            
                                            Text("Índice de bem-estar: \(Int(trend.currentWeekScore * 100))%")
                                                .font(.caption)
                                                .foregroundColor(VenusTheme.textSecondary)
                                        }
                                        Spacer()
                                    }

                                    Text(trend.summary)
                                        .font(.system(.body, design: .serif))
                                        .foregroundColor(VenusTheme.text)
                                        .lineSpacing(6)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.6))
                                        .background(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(VenusTheme.moodMintStrong.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // 2. Pattern Indicators Card
                            if let insights = weeklyInsights {
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Fatores de Impacto")
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        .foregroundColor(VenusTheme.moodMintStrong)
                                        .tracking(0.5)

                                    VStack(spacing: 16) {
                                        if let trigger = insights.dominantTrigger {
                                            rowDetail(title: "Gatilho Dominante", detail: trigger, icon: "bolt.fill")
                                        }
                                        
                                        if let bestDay = insights.bestDay {
                                            rowDetail(title: "Dia mais Equilibrado", detail: bestDay, icon: "calendar.badge.clock")
                                        }
                                        
                                        if let window = insights.criticalWindow {
                                            rowDetail(title: "Janela Crítica", detail: window, icon: "clock.fill")
                                        }
                                        
                                        if !insights.worstRecurringPattern.isEmpty {
                                            rowDetail(title: "Padrão Recorrente", detail: insights.worstRecurringPattern, icon: "exclamationmark.triangle.fill")
                                        }
                                        
                                        if !insights.behavioralFocus.isEmpty {
                                            rowDetail(title: "Foco de Ajuste", detail: insights.behavioralFocus, icon: "sparkles")
                                        }
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.6))
                                        .background(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(VenusTheme.moodMintStrong.opacity(0.15), lineWidth: 1)
                                )
                            }

                            // 3. Active Pattern Alerts Card
                            if let alert = patternAlert {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 18, weight: .bold))
                                        Text(alert.title)
                                            .font(.system(.headline, design: .rounded).weight(.bold))
                                            .foregroundColor(VenusTheme.text)
                                    }

                                    Text(alert.detail)
                                        .font(.system(.subheadline, design: .serif))
                                        .foregroundColor(VenusTheme.textSecondary)
                                        .lineSpacing(5)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Color.orange.opacity(0.06))
                                        .background(.ultraThinMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                } else {
                    // Baseline / Not Enough Data State
                    VStack(spacing: 32) {
                        Spacer()

                        ZStack {
                            Circle()
                                .stroke(VenusTheme.moodMintStrong.opacity(0.15), lineWidth: 3)
                                .frame(width: 96, height: 96)
                            
                            Circle()
                                .fill(VenusTheme.moodMintStrong.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(VenusTheme.moodMintStrong)
                        }

                        VStack(spacing: 12) {
                            Text("O Espelho está se formando")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.text)
                                .multilineTextAlignment(.center)

                            Text("Para eu me tornar um reflexo fiel do seu cérebro, preciso conhecer seus ritmos emocionais um pouco melhor.")
                                .font(.system(.body, design: .serif))
                                .foregroundColor(VenusTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .padding(.horizontal, 16)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(VenusTheme.moodMintStrong)
                                    .font(.system(size: 16))
                                Text("Registrar auras diárias de sentimentos")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundColor(VenusTheme.text)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "circle.dotted")
                                    .foregroundColor(VenusTheme.textSecondary)
                                    .font(.system(size: 16))
                                Text("Completar pelo menos 3 dias diferentes")
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundColor(VenusTheme.textSecondary)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "circle.dotted")
                                    .foregroundColor(VenusTheme.textSecondary)
                                    .font(.system(size: 16))
                                Text("Somar 4 check-ins de humor no total")
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundColor(VenusTheme.textSecondary)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.white.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(VenusTheme.moodMintStrong.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 32)

                        Spacer()
                        Spacer()
                    }
                }
            }
        }
    }

    private func rowDetail(title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(VenusTheme.moodMintStrong.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(VenusTheme.moodMintStrong)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(detail)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundColor(VenusTheme.text)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

#Preview {
    MirrorInsightView(
        weeklyTrend: WeeklyEmotionalTrend(
            direction: .improving,
            summary: "Sua semana foi muito boa comparada com a anterior.",
            currentWeekScore: 0.78,
            previousWeekScore: 0.65
        ),
        weeklyInsights: WeeklyStrategicInsights(
            dominantTrigger: "Trabalho produtivo",
            bestDay: "Quarta-feira",
            criticalWindow: "14h - 16h",
            sleepCounterfactual: nil,
            worstRecurringPattern: "Cansaço no fim de tarde",
            behavioralFocus: "Evitar telas após as 22h",
            leverageScore: 0.8,
            streakQualityScore: 0.9,
            recoveryProtocol: nil,
            confidence: 0.85
        ),
        patternAlert: PatternAlert(
            title: "Alerta de Estresse",
            detail: "Detectamos picos de estresse recorrentes na quinta-feira à tarde."
        )
    )
}
