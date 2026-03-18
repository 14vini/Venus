//
//  HomeScaffoldComponents.swift
//  Venus
//
//  Created by Kaua on 19/02/26.
//

import SwiftUI
import Charts

private enum HomeHealthPalette {
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let cardBorder = Color.black.opacity(0.06)
    static let title = Color(uiColor: .label)
    static let subtitle = Color(uiColor: .secondaryLabel)
    static let tertiary = Color(uiColor: .tertiaryLabel)
    static let blue = Color(uiColor: .systemBlue)
    static let orange = Color(uiColor: .systemOrange)
    static let green = Color(uiColor: .systemGreen)
    static let purple = Color(uiColor: .systemPurple)
}

private struct HomeHealthCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(HomeHealthPalette.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(HomeHealthPalette.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func homeHealthCardStyle(cornerRadius: CGFloat = 24) -> some View {
        modifier(HomeHealthCardModifier(cornerRadius: cornerRadius))
    }

    func homeHighlightListRow(top: CGFloat = 8, bottom: CGFloat = 8) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    func homeHeaderListRow(top: CGFloat = 10, bottom: CGFloat = 4) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 20, bottom: bottom, trailing: 20))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

struct HomePremiumTestToggleButton: View {
    let isPremiumEnabled: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Modo premium (teste)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.subtitle)
                    .textCase(.uppercase)

                Text(isPremiumEnabled ? "Ativo: Venus Pro" : "Ativo: Free")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.title)
            }

            Spacer()

            Button(isPremiumEnabled ? "Desativar" : "Ativar", action: action)
                .buttonStyle(.borderedProminent)
                .tint(HomeHealthPalette.purple)
                .controlSize(.regular)
        }
        .homeHealthCardStyle(cornerRadius: 20)
    }
}

struct HomeSummaryHeaderCard: View {
    let userName: String
    let summaryLine: String
    let completedSteps: Int
    let moodEmoji: String?
    let streakDays: Int

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.setLocalizedDateFormatFromTemplate("EEEE, d 'de' MMMM")
        return formatter.string(from: Date()).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hoje")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(HomeHealthPalette.orange)
                    Text(formattedDate)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.black.opacity(0.75))
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(moodEmoji ?? "🙂")
                        .font(.system(size: 28))

                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(HomeHealthPalette.orange)
                        Text("\(streakDays) dias")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.black.opacity(0.82))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.6)))
                }
            }

            Text("Olá, \(userName). \(summaryLine)")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Label("\(completedSteps)/3 etapas", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.55)))

                Label("Streak ativo", systemImage: "bolt.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.55)))
            }

            HomeStreakFlameWave(intensity: min(1.0, max(0.3, Double(streakDays) / 14.0)))
                .frame(height: 24)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "B9B6FF"), Color(hex: "F6C7B4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 28))
    }
}

private struct HomeStreakFlameWave: View {
    let intensity: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let baseY = size.height * 0.62
                let amplitude = max(1.8, size.height * 0.28 * intensity)
                let width = max(1, size.width)

                var primaryPath = Path()
                primaryPath.move(to: CGPoint(x: 0, y: baseY))

                var x: CGFloat = 0
                while x <= width {
                    let progress = Double(x / width)
                    let attenuation = max(0.55, 1.0 - progress * 0.35)
                    let y = baseY - sin(progress * 11.2 + time * 4.7) * amplitude * attenuation
                    primaryPath.addLine(to: CGPoint(x: x, y: y))
                    x += 2
                }

                var secondaryPath = Path()
                secondaryPath.move(to: CGPoint(x: 0, y: baseY + 2))

                x = 0
                while x <= width {
                    let progress = Double(x / width)
                    let attenuation = max(0.55, 1.0 - progress * 0.30)
                    let y = baseY + 2 - sin(progress * 8.0 + time * 3.3 + 0.7) * (amplitude * 0.55) * attenuation
                    secondaryPath.addLine(to: CGPoint(x: x, y: y))
                    x += 2
                }

                context.stroke(
                    primaryPath,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "FFB347"), Color(hex: "FF7A1A"), Color(hex: "FF4D00")]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: 0)
                    ),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                )
                context.stroke(
                    secondaryPath,
                    with: .color(Color.white.opacity(0.45)),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }
}

struct HomeHealthSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(HomeHealthPalette.title)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HomeHealthPalette.blue)
            }
        }
    }
}

struct HomeHealthMoodHighlightCard: View {
    let hasCheckedInToday: Bool
    let mood: MoodType?
    let intensity: Int?
    let energyLevel: MoodEnergyLevel?
    let dayOverDayTrend: DayOverDayTrendSummary?
    let allowance: CheckInAllowance
    let isCheckInUpgradeCTA: Bool
    let checkInActionTitle: String
    let primaryActionTitle: String
    let isPrimaryActionDisabled: Bool
    let onCheckInTap: () -> Void
    let onPrimaryActionTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                title: "Check-in de humor",
                systemImage: "heart.text.square.fill",
                tint: HomeHealthPalette.blue
            )

            Text(headline)
                .font(.title3.weight(.bold))
                .foregroundStyle(HomeHealthPalette.title)
                .fixedSize(horizontal: false, vertical: true)

            if hasCheckedInToday {
                Divider()
                    .overlay(HomeHealthPalette.cardBorder)

                LabeledContent("Estado de hoje") {
                    Text(todayValueLabel)
                        .fontWeight(.semibold)
                }

                LabeledContent("Energia") {
                    Text(energyLevel?.rawValue ?? "Sem dado")
                        .fontWeight(.semibold)
                }

                LabeledContent("Comparado a ontem") {
                    Text(dayOverDayTrend?.label ?? "Sem base ainda")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: dayOverDayTrend?.direction.colorHex ?? "6B7280"))
                }
            } else {
                Text("Faça seu check-in para liberar recomendações personalizadas e projeções da semana.")
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .overlay(HomeHealthPalette.cardBorder)

            HStack(spacing: 10) {
                Button(checkInActionTitle, action: onCheckInTap)
                    .buttonStyle(.borderedProminent)
                    .tint(isCheckInUpgradeCTA ? HomeHealthPalette.purple : HomeHealthPalette.blue)
                    .controlSize(.regular)

                if hasCheckedInToday {
                    Button(primaryActionTitle, action: onPrimaryActionTap)
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .disabled(isPrimaryActionDisabled)
                }
            }

            Text(quotaLabel)
                .font(.caption)
                .foregroundStyle(HomeHealthPalette.tertiary)
        }
        .homeHealthCardStyle(cornerRadius: 26)
    }

    private var headline: String {
        guard hasCheckedInToday, let mood else {
            return "Nenhum check-in registrado hoje."
        }
        return "Você está \(mood.rawValue.lowercased()) hoje."
    }

    private var todayValueLabel: String {
        guard let intensity else { return "Sem intensidade" }
        return "\(intensity)/10"
    }

    private var quotaLabel: String {
        if allowance.isUnlimited {
            return "\(allowance.usedToday) check-ins usados hoje."
        }
        let limit = allowance.dailyLimit ?? CheckInAllowance.defaultFreeDailyLimit
        return "\(allowance.usedToday) de \(limit) check-ins usados hoje."
    }
}

struct HomeHealthActionHighlightCard: View {
    let isLoading: Bool
    let hasCheckedInToday: Bool
    let actionModel: NextBestAction?
    let actionWhySummary: String?
    let errorMessage: String?
    let hasActionStartedToday: Bool
    let isHighImpactSelected: Bool
    let isHighRiskRecommended: Bool
    let primaryActionTitle: String
    let onActionIntensityChange: (Bool) -> Void
    let onWhyTap: () -> Void
    let onPrimaryActionTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                title: "Próxima ação inteligente",
                systemImage: actionModel?.kind.iconName ?? "bolt.heart.fill",
                tint: HomeHealthPalette.orange
            )

            if isLoading {
                ProgressView("Analisando seus sinais emocionais...")
                    .foregroundStyle(HomeHealthPalette.subtitle)
            } else if let actionModel {
                Text(actionModel.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(HomeHealthPalette.title)
                    .fixedSize(horizontal: false, vertical: true)

                Text(actionModel.detail)
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Menu {
                        Button {
                            onActionIntensityChange(false)
                        } label: {
                            Label("Microação (5-15 min)", systemImage: isHighImpactSelected ? "circle" : "checkmark")
                        }
                        Button {
                            onActionIntensityChange(true)
                        } label: {
                            Label("Ação alta (25-35 min)", systemImage: isHighImpactSelected ? "checkmark" : "circle")
                        }
                    } label: {
                        Label(
                            isHighImpactSelected ? "Modo: Ação alta" : "Modo: Microação",
                            systemImage: "slider.horizontal.3"
                        )
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Spacer()
                }

                if isHighRiskRecommended {
                    Label(
                        "Risco alto detectado. Hoje o modo de ação alta é recomendado.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.purple)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Divider()
                    .overlay(HomeHealthPalette.cardBorder)

                LabeledContent("Duração") {
                    Text("\(actionModel.estimatedMinutes) min")
                        .fontWeight(.semibold)
                }

                LabeledContent("Status") {
                    Text(hasActionStartedToday ? "Já iniciada hoje" : "Ainda não iniciada")
                        .fontWeight(.semibold)
                }

                if let reasonText = actionWhySummary, !reasonText.isEmpty {
                    LabeledContent("Por que agora") {
                        Text(reasonText)
                            .font(.caption.weight(.semibold))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(HomeHealthPalette.subtitle)
                    }
                }

                HStack(spacing: 10) {
                    Button("Por que isso?", action: onWhyTap)
                        .buttonStyle(.bordered)

                    Button(hasActionStartedToday ? "Refazer" : "Iniciar", action: onPrimaryActionTap)
                        .buttonStyle(.borderedProminent)
                        .tint(HomeHealthPalette.orange)
                }
            } else if !hasCheckedInToday {
                Text("Conclua o check-in para receber sua próxima melhor ação.")
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
            } else {
                Text(errorMessage ?? "Ainda não há ação clara. Atualize a análise para recalcular.")
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)

                Button(primaryActionTitle, action: onPrimaryActionTap)
                    .buttonStyle(.borderedProminent)
                    .tint(HomeHealthPalette.orange)
            }
        }
        .homeHealthCardStyle(cornerRadius: 26)
    }
}

private struct HomeTrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let score: Double
    let tint: Color
}

struct HomeHealthTrendHighlightCard: View {
    let weeklyTrend: WeeklyEmotionalTrend?
    let patternAlert: PatternAlert?
    let weeklyInsights: WeeklyStrategicInsights?
    let streakDays: Int

    private var trendPoints: [HomeTrendPoint] {
        guard let weeklyTrend else { return [] }

        var points: [HomeTrendPoint] = []
        if let previous = weeklyTrend.previousWeekScore {
            points.append(HomeTrendPoint(label: "Anterior", score: previous, tint: Color.gray.opacity(0.45)))
        }
        points.append(HomeTrendPoint(label: "Atual", score: weeklyTrend.currentWeekScore, tint: HomeHealthPalette.green))
        return points
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                title: "Tendência da semana",
                systemImage: "waveform.path.ecg",
                tint: HomeHealthPalette.green
            )

            Text(weeklyTrend?.direction.title ?? "Sem dados suficientes nesta semana")
                .font(.title3.weight(.bold))
                .foregroundStyle(HomeHealthPalette.title)
                .fixedSize(horizontal: false, vertical: true)

            if let summary = weeklyTrend?.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if trendPoints.count >= 2 {
                Chart(trendPoints) { point in
                    BarMark(
                        x: .value("Semana", point.label),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(point.tint)
                    .cornerRadius(5)
                }
                .chartYAxis(.hidden)
                .frame(height: 90)
            }

            Divider()
                .overlay(HomeHealthPalette.cardBorder)

            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(HomeHealthPalette.orange)
                Text("Streak atual: \(streakDays) dias")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.title)
                Spacer()
            }

            if let confidence = weeklyInsights?.confidence {
                LabeledContent("Confiabilidade do modelo") {
                    Text("\(Int((confidence * 100).rounded()))%")
                        .fontWeight(.semibold)
                }
            }

            if let trigger = weeklyInsights?.dominantTrigger {
                LabeledContent("Gatilho dominante") {
                    Text(trigger)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.trailing)
                }
            } else if let patternAlert {
                LabeledContent(patternAlert.title) {
                    Text(patternAlert.detail)
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(HomeHealthPalette.subtitle)
                }
            }
        }
        .homeHealthCardStyle(cornerRadius: 26)
    }
}

struct HomeHealthConfidenceHighlightCard: View {
    let insight: ConfidenceImprovementInsight?

    @State private var selectedHorizon = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                title: "Evolução da autoconfiança",
                systemImage: "person.crop.circle.badge.checkmark",
                tint: HomeHealthPalette.blue
            )

            if let insight {
                HStack {
                    Text("Projeção personalizada")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HomeHealthPalette.title)

                    Spacer()

                    Menu {
                        Button("7 dias") { selectedHorizon = 7 }
                        Button("14 dias") { selectedHorizon = 14 }
                    } label: {
                        Label("Horizonte \(selectedHorizon)d", systemImage: "calendar")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                let current = insight.currentConfidence
                let projected = selectedHorizon == 14
                    ? insight.projectedConfidence14Days
                    : insight.projectedConfidence7Days
                let gain = projected - current

                Gauge(value: projected, in: 0...1) {
                    Text("Confiança")
                } currentValueLabel: {
                    Text("\(Int((projected * 100).rounded()))%")
                        .font(.title3.weight(.bold))
                } minimumValueLabel: {
                    Text("Hoje \(Int((current * 100).rounded()))%")
                        .font(.caption2)
                } maximumValueLabel: {
                    Text("Meta")
                        .font(.caption2)
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(Gradient(colors: [HomeHealthPalette.blue, HomeHealthPalette.purple]))
                .frame(maxWidth: .infinity, alignment: .leading)

                LabeledContent("Ganho estimado") {
                    Text(String(format: "%+.0f%%", gain * 100))
                        .fontWeight(.semibold)
                        .foregroundStyle(HomeHealthPalette.green)
                }

                Text(insight.personalizedSummary)
                    .font(.caption)
                    .foregroundStyle(HomeHealthPalette.subtitle)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(HomeHealthPalette.cardBorder)

                Text("Alavancas recomendadas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.tertiary)
                    .textCase(.uppercase)

                ForEach(Array(insight.keyLevers.prefix(3)), id: \.self) { lever in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(HomeHealthPalette.blue)
                            .font(.caption)
                        Text(lever)
                            .font(.caption)
                            .foregroundStyle(HomeHealthPalette.subtitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                Text("Precisamos de mais check-ins para projetar sua evolução de autoconfiança.")
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
            }
        }
        .homeHealthCardStyle(cornerRadius: 26)
    }
}

private struct HomeTriggerChartPoint: Identifiable {
    let id = UUID()
    let dayOffset: Int
    let scenario: String
    let score: Double
}

struct HomeHealthTriggerRecoveryCard: View {
    let insight: TriggerRecoveryInsight?
    let isPro: Bool
    let onUpgradeTap: () -> Void

    @State private var focusMetric: String = "7 dias"

    private var chartPoints: [HomeTriggerChartPoint] {
        guard let insight else { return [] }
        return insight.highlightedProjection.flatMap { point in
            [
                HomeTriggerChartPoint(dayOffset: point.dayOffset, scenario: "Sem ação", score: point.scoreWithoutAction),
                HomeTriggerChartPoint(dayOffset: point.dayOffset, scenario: "Com ação", score: point.scoreWithAction)
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                title: "Recuperação por gatilho",
                systemImage: "flame.fill",
                tint: HomeHealthPalette.orange
            )

            if let insight {
                HStack {
                    Text("Gatilho em destaque: \(insight.highlightedTrigger)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HomeHealthPalette.title)

                    Spacer()

                    Menu {
                        Button("3 dias") { focusMetric = "3 dias" }
                        Button("7 dias") { focusMetric = "7 dias" }
                    } label: {
                        Label(focusMetric, systemImage: "scope")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Text(insight.highlightedSummary)
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
                    .fixedSize(horizontal: false, vertical: true)

                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Dia", point.dayOffset),
                        y: .value("Índice", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: point.scenario == "Com ação" ? 2.8 : 1.8))
                    .foregroundStyle(by: .value("Cenário", point.scenario))

                    PointMark(
                        x: .value("Dia", point.dayOffset),
                        y: .value("Índice", point.score)
                    )
                    .foregroundStyle(by: .value("Cenário", point.scenario))
                    .symbolSize(point.scenario == "Com ação" ? 56 : 38)
                }
                .chartForegroundStyleScale([
                    "Sem ação": Color.gray.opacity(0.55),
                    "Com ação": HomeHealthPalette.orange
                ])
                .chartXAxis {
                    AxisMarks(values: [1, 3, 7]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(HomeHealthPalette.cardBorder)
                        AxisValueLabel {
                            if let day = value.as(Int.self) {
                                Text("D+\(day)")
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 170)

                if let point = insight.highlightedProjection.first(where: { $0.dayOffset == (focusMetric == "3 dias" ? 3 : 7) }) {
                    LabeledContent("Melhora esperada em \(focusMetric)") {
                        Text(String(format: "%+.0f%%", point.delta * 100))
                            .fontWeight(.semibold)
                            .foregroundStyle(HomeHealthPalette.green)
                    }
                }

                if isPro && !insight.additionalAreaProjections.isEmpty {
                    Divider()
                        .overlay(HomeHealthPalette.cardBorder)

                    Text("Outras áreas")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HomeHealthPalette.tertiary)
                        .textCase(.uppercase)

                    ForEach(insight.additionalAreaProjections.prefix(4)) { projection in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(projection.area)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(HomeHealthPalette.title)
                                Text("Confiança \(Int((projection.confidence * 100).rounded()))%")
                                    .font(.caption2)
                                    .foregroundStyle(HomeHealthPalette.tertiary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("D+3 \(String(format: "%+.0f%%", projection.day3Delta * 100))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(HomeHealthPalette.subtitle)
                                Text("D+7 \(String(format: "%+.0f%%", projection.day7Delta * 100))")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(HomeHealthPalette.green)
                            }
                        }
                    }
                } else if !isPro, insight.lockedAdditionalAreasCount > 0 {
                    Divider()
                        .overlay(HomeHealthPalette.cardBorder)

                    Label(
                        "\(insight.lockedAdditionalAreasCount) áreas extras de projeção disponíveis no Venus Pro.",
                        systemImage: "lock.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.purple)

                    Button("Desbloquear Venus Pro", action: onUpgradeTap)
                        .buttonStyle(.borderedProminent)
                        .tint(HomeHealthPalette.blue)
                }
            } else {
                Text("Precisamos de mais dados para prever a recuperação dos seus gatilhos.")
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
            }
        }
        .homeHealthCardStyle(cornerRadius: 26)
    }
}

struct HomeHealthExploreSuggestionsCard: View {
    let suggestions: [ExploreActionSuggestion]

    @State private var selectedCategory: String = "Todas"

    private var categories: [String] {
        let uniques = Array(Set(suggestions.map(\.activityCategory))).sorted()
        return ["Todas"] + uniques
    }

    private var filteredSuggestions: [ExploreActionSuggestion] {
        guard selectedCategory != "Todas" else { return suggestions }
        return suggestions.filter { $0.activityCategory == selectedCategory }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                title: "Práticas inteligentes do Explorar",
                systemImage: "sparkles.rectangle.stack",
                tint: HomeHealthPalette.purple
            )

            if !suggestions.isEmpty {
                HStack {
                    Text("Selecionadas pelo seu contexto atual")
                        .font(.caption)
                        .foregroundStyle(HomeHealthPalette.subtitle)
                    Spacer()

                    Menu {
                        ForEach(categories, id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                        }
                    } label: {
                        Label(selectedCategory, systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                ForEach(Array(filteredSuggestions.prefix(3).enumerated()), id: \.element.id) { index, suggestion in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(suggestion.activityTitle, systemImage: suggestion.iconName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HomeHealthPalette.title)

                            Spacer()

                            Text("\(suggestion.durationMinutes) min")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(HomeHealthPalette.subtitle)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color(uiColor: .systemGray6)))
                        }

                        Text(suggestion.recommendationReason)
                            .font(.caption)
                            .foregroundStyle(HomeHealthPalette.subtitle)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            Text(suggestion.activityCategory)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(HomeHealthPalette.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(HomeHealthPalette.blue.opacity(0.12)))

                            Spacer()

                            Text("Aderência \(Int((suggestion.matchScore * 100).rounded()))%")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(HomeHealthPalette.tertiary)
                        }
                    }

                    if index < min(filteredSuggestions.count, 3) - 1 {
                        Divider()
                            .overlay(HomeHealthPalette.cardBorder)
                    }
                }

                Text("Todas as práticas completas continuam disponíveis na aba Explorar.")
                    .font(.caption2)
                    .foregroundStyle(HomeHealthPalette.tertiary)
            } else {
                Text("Ainda sem recomendações do Explorar. Continue registrando seu check-in para liberar sugestões mais precisas.")
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .homeHealthCardStyle(cornerRadius: 26)
    }
}

struct HomeHealthForecastHighlightCard: View {
    let isLoading: Bool
    let forecast: ProMoodForecast?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                title: "Projeção emocional",
                systemImage: "chart.line.uptrend.xyaxis",
                tint: HomeHealthPalette.orange
            )

            if isLoading, forecast == nil {
                ProgressView("Calculando projeção para 1, 3 e 7 dias...")
                    .foregroundStyle(HomeHealthPalette.subtitle)
            } else if let forecast {
                Text("Com a ação recomendada, sua tendência emocional deve melhorar ao longo da semana.")
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
                    .fixedSize(horizontal: false, vertical: true)

                Chart {
                    ForEach(forecast.points) { point in
                        LineMark(
                            x: .value("Dia", point.dayOffset),
                            y: .value("Score", point.projectedScore)
                        )
                        .foregroundStyle(by: .value("Cenário", "Sem ação"))

                        LineMark(
                            x: .value("Dia", point.dayOffset),
                            y: .value("Score", point.projectedScoreWithAction)
                        )
                        .foregroundStyle(by: .value("Cenário", "Com ação"))

                        PointMark(
                            x: .value("Dia", point.dayOffset),
                            y: .value("Score", point.projectedScoreWithAction)
                        )
                        .foregroundStyle(by: .value("Cenário", "Com ação"))
                    }
                }
                .chartForegroundStyleScale([
                    "Sem ação": Color.gray.opacity(0.55),
                    "Com ação": HomeHealthPalette.orange
                ])
                .chartXAxis {
                    AxisMarks(values: forecast.points.map(\.dayOffset)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(HomeHealthPalette.cardBorder)
                        AxisValueLabel {
                            if let day = value.as(Int.self) {
                                Text("D+\(day)")
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 180)

                if let firstPoint = forecast.points.first(where: { $0.dayOffset == 1 }) {
                    LabeledContent("Impacto em 24h") {
                        Text(firstPoint.actionDelta.formatted(.number.precision(.fractionLength(2))))
                            .fontWeight(.semibold)
                            .foregroundStyle(HomeHealthPalette.orange)
                    }
                }

                LabeledContent("Confiabilidade do modelo") {
                    Text("\(Int((forecast.confidence * 100).rounded()))%")
                        .fontWeight(.semibold)
                }

                if let riskAlert = forecast.riskAlert {
                    Text(riskAlert)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HomeHealthPalette.subtitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Sem projeção disponível neste momento.")
                    .font(.subheadline)
                    .foregroundStyle(HomeHealthPalette.subtitle)
            }
        }
        .homeHealthCardStyle(cornerRadius: 26)
    }
}

struct HomeHealthForecastUpsellCard: View {
    let onUpgradeTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow(
                title: "Previsão Pro",
                systemImage: "crown.fill",
                tint: HomeHealthPalette.purple
            )

            Text("Desbloqueie previsão emocional de 1, 3 e 7 dias, com impacto da ação recomendada.")
                .font(.subheadline)
                .foregroundStyle(HomeHealthPalette.subtitle)
                .fixedSize(horizontal: false, vertical: true)

            Button("Desbloquear Venus Pro", action: onUpgradeTap)
                .buttonStyle(.borderedProminent)
                .tint(HomeHealthPalette.blue)
        }
        .homeHealthCardStyle(cornerRadius: 26)
    }
}

struct HomeHealthShowAllHighlightsRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HomeHealthPalette.blue)

                Text("Ver todos os destaques")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.title)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HomeHealthPalette.tertiary)
            }
        }
        .buttonStyle(.plain)
        .homeHealthCardStyle(cornerRadius: 22)
    }
}

private func headerRow(
    title: String,
    systemImage: String,
    tint: Color
) -> some View {
    HStack(spacing: 8) {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)

        Spacer()

        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(HomeHealthPalette.tertiary)
    }
}
