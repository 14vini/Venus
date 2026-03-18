//
//  HomeRecommendationComponents.swift
//  Venus
//

import SwiftUI

struct TodayMoodSummaryCard: View {
    let mood: MoodType
    let intensity: Int?
    let tags: [String]
    let energyLevel: MoodEnergyLevel?
    let availableTime: MoodAvailableTime?
    let controlLevel: MoodControlLevel?
    let affectedArea: MoodAffectedArea?
    let mentalClarity: Int?
    let sleepQuality: MoodSleepQuality?
    let bodySignals: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Seu check-in de hoje")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.text)

            HStack(spacing: 10) {
                Text(mood.emoji)
                    .font(.system(size: 38))

                VStack(alignment: .leading, spacing: 3) {
                    Text(mood.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    Text("Estado atual")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }

                Spacer()

                if let intensity {
                    Text("\(intensity)/10")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(VenusTheme.cardSurfaceStrong))
                        .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))
                    }
            }

            HStack(spacing: 8) {
                if let energyLevel {
                    HomeMetaChip(title: "Energia \(energyLevel.rawValue)")
                }
                if let availableTime {
                    HomeMetaChip(title: "Tempo \(availableTime.rawValue)")
                }
                if let controlLevel {
                    HomeMetaChip(title: "Controle \(controlLevel.rawValue)")
                }
                if let affectedArea {
                    HomeMetaChip(title: "Area \(affectedArea.rawValue)")
                }
                if let mentalClarity {
                    HomeMetaChip(title: "Clareza \(mentalClarity)/10")
                }
                if let sleepQuality {
                    HomeMetaChip(title: "Sono \(sleepQuality.rawValue)")
                }
            }

            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HomeMetaChip(title: tag)
                        }
                    }
                }
            }

            let visibleBodySignals = bodySignals.filter { $0 != "Sem sintomas" }
            if !visibleBodySignals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(visibleBodySignals, id: \.self) { signal in
                            HomeMetaChip(title: signal)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 30)
    }
}

private struct HomeMetaChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(VenusTheme.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Capsule().fill(VenusTheme.cardSurfaceStrong))
            .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))
    }
}

struct WeeklyTrendCard: View {
    let trend: WeeklyEmotionalTrend
    let streakDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(trend.direction.title, systemImage: trend.direction.iconName)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                Spacer()
                Text("Streak \(streakDays)d")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(VenusTheme.cardSurfaceStrong))
                    .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))
            }

            Text(trend.summary)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 30)
    }
}

struct PatternAlertCard: View {
    let alert: PatternAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(alert.title, systemImage: "waveform.path.ecg")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.text)

            Text(alert.detail)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 30)
    }
}

struct WeeklyStrategicInsightsCard: View {
    let insights: WeeklyStrategicInsights

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Inteligencia da semana", systemImage: "brain.head.profile")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.text)

            if let dominantTrigger = insights.dominantTrigger {
                insightLine(icon: "exclamationmark.triangle.fill", text: "Gatilho dominante: \(dominantTrigger)")
            }

            if let bestDay = insights.bestDay {
                insightLine(icon: "sun.max.fill", text: "Melhor dia: \(bestDay)")
            }

            if let criticalWindow = insights.criticalWindow {
                insightLine(icon: "clock.badge.exclamationmark.fill", text: criticalWindow)
            }

            if let counterfactual = insights.sleepCounterfactual {
                insightLine(icon: "moon.zzz.fill", text: counterfactual)
            }

            Text(insights.worstRecurringPattern)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Foco comportamental da semana")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                Text(insights.behavioralFocus)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Alavanca \(Int((insights.leverageScore * 100).rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(VenusTheme.cardSurfaceStrong))
                    .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))
            }

            Text("Qualidade do streak \(Int((insights.streakQualityScore * 100).rounded()))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(VenusTheme.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(VenusTheme.cardSurfaceStrong))
                .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))

            if let recoveryProtocol = insights.recoveryProtocol {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recoveryProtocol.title)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    ForEach(Array(recoveryProtocol.steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(VenusTheme.cardSurfaceStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(VenusTheme.cardBorder, lineWidth: 1)
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 30)
    }

    @ViewBuilder
    private func insightLine(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(Color(hex: "FF5F15"))
                .frame(width: 16, height: 16)
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EmptyRecommendationCard: View {
    let needsCheckIn: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(VenusTheme.text)
                Text("Próxima ação")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
            }

            Text(
                needsCheckIn
                ? "Faca seu check-in para liberar a analise de padrao e a proxima melhor acao."
                : "Ainda nao encontrei uma acao clara. Atualize seu check-in para recalcular."
            )
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(VenusTheme.textSecondary)

            Button(action: action) {
                Text(needsCheckIn ? "Fazer check-in" : "Atualizar analise")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(VenusTheme.cardSurfaceStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(VenusTheme.cardBorder, lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 30)
    }
}

struct NextBestActionCard: View {
    let actionModel: NextBestAction
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Próxima melhor ação", systemImage: actionModel.kind.iconName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Spacer()

                Text("\(actionModel.estimatedMinutes) min")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(VenusTheme.cardSurfaceStrong))
                    .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))
            }

            Text(actionModel.title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(actionModel.detail)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .lineLimit(4)

            Text(actionModel.strategicReason)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .lineLimit(4)

            Button(action: action) {
                Text("Iniciar micro-acao")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 34)
    }
}

struct HomeRecommendationErrorCard: View {
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Nao consegui calcular o padrao", systemImage: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(VenusTheme.text)

            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)

            Button(action: action) {
                Text("Reprocessar analise")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(VenusTheme.cardSurfaceStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(VenusTheme.cardBorder, lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 30)
    }
}
