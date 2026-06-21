//
//  HomeMinimalComponents.swift
//  Venus
//

import SwiftUI
import Charts

struct HomeActionReasonView: View {
    @Environment(\.colorScheme) private var colorScheme

    let actionModel: NextBestAction
    let weeklyInsights: WeeklyStrategicInsights?
    let patternAlert: PatternAlert?
    let actionWhy: ActionWhyInsight?
    let proForecast: ProMoodForecast?
    let isPro: Bool
    let confidenceInsight: ConfidenceImprovementInsight?
    let triggerRecoveryInsight: TriggerRecoveryInsight?
    let alternativeActions: [NextBestAction]
    let exploreSuggestions: [ExploreActionSuggestion]

    @State private var revealContent = false
    @State private var showComingSoon = false

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: actionAccent,
                secondaryAccent: VenusTheme.moodSage,
                tertiaryAccent: VenusTheme.ambientCool
            )

            VStack(spacing: 0) {
                Spacer()

                // Espelho Statement
                Text(mirrorStatement)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(VenusTheme.text)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .opacity(revealContent ? 1 : 0)
                    .offset(y: revealContent ? 0 : 20)

                Spacer()
                
                // Action Button Area
                VStack(spacing: 16) {
                    Button {
                        showComingSoon = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: actionModel.kind.iconName)
                                .font(.system(size: 20, weight: .semibold))
                            Text("Começar")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Spacer()
                            Text("\(actionModel.estimatedMinutes) min")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .opacity(0.8)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .foregroundColor(.white)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [actionAccent, actionAccent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                        .shadow(color: actionAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    
                    Text(actionModel.title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(revealContent ? 1 : 0)
                .offset(y: revealContent ? 0 : 20)
            }
        }
        .sheet(isPresented: $showComingSoon) {
            ComingSoonSheet(actionTitle: actionModel.title)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .background(VenusTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                revealContent = true
            }
        }
    }

    private var actionAccent: Color {
        actionModel.isHighImpactVariant ? VenusTheme.primary : VenusTheme.accentGreen
    }

    private var mirrorStatement: String {
        let why = actionWhy?.summary ?? actionModel.strategicReason
        
        if let trigger = weeklyInsights?.dominantTrigger ?? patternAlert?.title {
            return "Percebi que \(trigger.lowercased()) tem desafiado o seu dia. Por isso, preparei um espaço para você se reconectar."
        }
        
        return why
    }
}

private struct ComingSoonSheet: View {
    let actionTitle: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            VenusMoodOrb(mood: .happy, size: 88)
                .padding(.top, 8)

            VStack(spacing: 10) {
                Text("em breve")
                    .font(.system(.caption, design: .rounded).weight(.black))
                    .foregroundColor(VenusTheme.moodMintStrong)
                    .tracking(1.2)

                Text("a execução guiada tá chegando")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .multilineTextAlignment(.center)

                Text("Logo você vai poder começar \"\(actionTitle)\" direto por aqui, com timer, passos e registro automático.")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                featureRow(icon: "play.circle.fill", text: "execução guiada passo a passo", tint: VenusTheme.accentGreen)
                featureRow(icon: "timer", text: "timer integrado", tint: VenusTheme.accentBlue)
                featureRow(icon: "checkmark.circle.fill", text: "registro automático ao concluir", tint: VenusTheme.accentOrange)
                featureRow(icon: "sparkles", text: "feedback do mascot ao final", tint: VenusTheme.accentPurple)
            }

            Button {
                dismiss()
            } label: {
                Text("entendi")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(VenusTheme.cardSurface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private func featureRow(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 20)
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
            Spacer()
        }
    }
}

private struct HomeReasonSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let content: Content

    init(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(tint)
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                }
                Text(subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
        }
        .venusScrollMotion(.strong)
    }
}

private struct HomeReasonQuickHighlight: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let tint: Color
}

private struct HomeReasonQuickLookCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let highlight: HomeReasonQuickHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(highlight.tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: highlight.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(highlight.tint)
            }

            Text(highlight.title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(highlight.value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? VenusTheme.cardSurfaceStrong : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(VenusTheme.cardBorder, lineWidth: 1)
        )
    }
}

private struct HomeSpotlightMetric: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tint)
            }

            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? VenusTheme.cardSurfaceStrong : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(VenusTheme.cardBorder, lineWidth: 1)
        )
    }
}

private struct HomeEvidenceCard: View {
    let index: Int
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 36, height: 36)

                Text("\(index)")
                    .font(.system(.subheadline, design: .rounded).weight(.black))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)

                Text(detail)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .actionReasonCardStyle(cornerRadius: 24)
    }
}

private struct HomeScenarioChart: View {
    let points: [ReasonChartPoint]
    let accent: Color
    let comparison: Color
    let valueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                HomeLegendPill(label: "Com ação", tint: accent)
                HomeLegendPill(label: "Sem ação", tint: comparison)
            }

            Chart(points) { point in
                AreaMark(
                    x: .value("Dia", point.dayOffset),
                    y: .value(valueLabel, point.score)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    point.scenario == "Com ação"
                    ? accent.opacity(0.18)
                    : comparison.opacity(0.12)
                )

                LineMark(
                    x: .value("Dia", point.dayOffset),
                    y: .value(valueLabel, point.score)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: point.scenario == "Com ação" ? 3 : 2, lineCap: .round))
                .foregroundStyle(point.scenario == "Com ação" ? accent : comparison)

                PointMark(
                    x: .value("Dia", point.dayOffset),
                    y: .value(valueLabel, point.score)
                )
                .foregroundStyle(point.scenario == "Com ação" ? accent : comparison)
                .symbolSize(point.scenario == "Com ação" ? 36 : 24)
            }
            .chartXAxis {
                AxisMarks(values: [1, 3, 7]) { value in
                    AxisGridLine().foregroundStyle(Color.clear)
                    AxisTick().foregroundStyle(VenusTheme.textSecondary.opacity(0.2))
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("D+\(day)")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
        }
    }
}

private struct HomeMiniMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(VenusTheme.cardSurfaceStrong.opacity(0.85))
        )
    }
}

private struct HomeMiniMetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.5), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 14, height: 4)
            }

            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(value)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .actionReasonCardStyle(cornerRadius: 20)
    }
}

private struct HomeContextCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Capsule()
                    .fill(tint.opacity(0.75))
                    .frame(width: 14, height: 4)
            }

            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .actionReasonCardStyle(cornerRadius: 20)
    }
}

private struct HomeNarrativeCard: View {
    let eyebrow: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(tint)

            Text(title)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .actionReasonCardStyle(cornerRadius: 26)
    }
}

private struct HomeStepRow: View {
    let index: Int
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 28, height: 28)

                Text("\(index)")
                    .font(.system(.caption, design: .rounded).weight(.black))
                    .foregroundColor(tint)
            }

            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct HomeLegendPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? VenusTheme.cardSurfaceStrong : Color.white)
        )
    }
}

private struct HomePillBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? tint.opacity(0.18) : tint.opacity(0.12))
        )
    }
}

private struct HomeLockedInsightCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VenusProBadge(compact: true)

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(VenusTheme.accentPurple)

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
            }

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .venusProGlassCardStyle(cornerRadius: 26)
    }
}

private struct HomeActionDecisionCard: View {
    let title: String
    let detail: String
    let badge: String
    let duration: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(badge)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(tint.opacity(0.12)))

                Spacer()

                Text(duration)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .actionReasonCardStyle(cornerRadius: 24)
    }
}

private struct HomeExploreSuggestionPill: View {
    let suggestion: ExploreActionSuggestion

    private var tint: Color {
        switch suggestion.activityCategory.lowercased() {
        case let value where value.contains("mov"):
            return VenusTheme.accentGreen
        case let value where value.contains("sono"), let value where value.contains("auto"):
            return VenusTheme.primary
        case let value where value.contains("conex"), let value where value.contains("rel"):
            return VenusTheme.accentBlue
        default:
            return VenusTheme.moodMintStrong
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: suggestion.iconName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tint)

                Text("\(suggestion.durationMinutes) min")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            Text(suggestion.activityTitle)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(suggestion.activityCategory)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(12)
        .frame(width: 160, alignment: .leading)
        .actionReasonCardStyle(cornerRadius: 20)
    }
}

private struct HomeProtocolLibraryCard: View {
    let suggestion: ExploreActionSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: suggestion.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(VenusTheme.accentBlue)

                Spacer()

                Text(suggestion.matchScore >= 0.7 ? "combina muito" : "pode funcionar")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.moodMintStrong)
            }

            Text(suggestion.activityTitle)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(suggestion.recommendationReason)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(suggestion.durationMinutes) min · \(suggestion.activityCategory)")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .actionReasonCardStyle(cornerRadius: 24)
    }
}

private struct HomeConfidenceScoreCard: View {
    let confidence: Double
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(VenusTheme.cardBorder.opacity(0.55), lineWidth: 6)
                        .frame(width: 58, height: 58)

                    Circle()
                        .trim(from: 0, to: max(0.04, min(confidence, 1)))
                        .stroke(
                            LinearGradient(
                                colors: [VenusTheme.primary, VenusTheme.moodMintStrong],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 58, height: 58)

                    Text("\(Int((confidence * 100).rounded()))%")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.text)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("o quanto eu confio nisso")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text(summary)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HomeConfidenceLinearBar(value: confidence, tint: VenusTheme.moodMintStrong)
        }
        .padding(18)
        .actionReasonCardStyle(cornerRadius: 24)
    }
}

private struct HomeConfidenceLinearBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let clampedValue = max(0, min(value, 1))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(VenusTheme.cardBorder.opacity(0.35))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.45), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(18, geometry.size.width * clampedValue))
            }
        }
        .frame(height: 8)
    }
}

private struct HomeFlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(chunkedItems, id: \.self) { row in
                HStack(alignment: .top, spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunkedItems: [[Data.Element]] {
        var rows: [[Data.Element]] = []
        var currentRow: [Data.Element] = []

        for (index, item) in items.enumerated() {
            currentRow.append(item)
            if index.isMultiple(of: 2) == false {
                rows.append(currentRow)
                currentRow = []
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

private struct HomeExpandedActionOption {
    let title: String
    let detail: String
    let estimatedMinutes: Int
}

private struct ReasonChartPoint: Identifiable {
    let id = UUID()
    let dayOffset: Int
    let scenario: String
    let score: Double
}

private struct HomeActionReasonCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(colorScheme == .dark ? VenusTheme.cardSurface : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(VenusTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: 18, x: 0, y: 10)
    }
}

private extension View {
    func actionReasonCardStyle(cornerRadius: CGFloat = 28) -> some View {
        modifier(HomeActionReasonCardStyle(cornerRadius: cornerRadius))
    }
}
