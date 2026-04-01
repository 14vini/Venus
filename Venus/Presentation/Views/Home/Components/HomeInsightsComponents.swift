//
//  HomeInsightsComponents.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI
import Charts

enum HomeVisualInsightKind: String {
    case trend
    case alert
    case forecast
    case forecastLocked
    case triggerRecovery
    case confidence
}

struct HomeVisualInsight: Identifiable {
    let kind: HomeVisualInsightKind
    let label: String
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    var badgeText: String? = nil
    var progress: Double? = nil
    var sparklineValues: [Double]? = nil

    var id: String { kind.rawValue }
}

struct HomeInsightsSection: View {
    let insights: [HomeVisualInsight]
    let suggestions: [ExploreActionSuggestion]
    let onTapInsight: (HomeVisualInsight) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seu momento agora")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text("Painel visual para bater o olho.")
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                }

                Spacer()

                VenusIllustrationCluster(
                    symbols: [
                        VenusIllustrationSymbol(systemName: "chart.bar.fill", tint: VenusTheme.accentBlue, size: 16),
                        VenusIllustrationSymbol(systemName: "sparkles", tint: VenusTheme.accentOrange, size: 16),
                        VenusIllustrationSymbol(systemName: "heart.fill", tint: VenusTheme.accentPink, size: 14)
                    ],
                    width: 108,
                    height: 84
                )
            }

            if insights.isEmpty {
                VenusCard {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Seu resumo aparece aqui")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.text)

                            Text("Faça um check-in e eu monto esse painel para você.")
                                .font(.system(.footnote, design: .rounded).weight(.medium))
                                .foregroundColor(VenusTheme.textSecondary)
                        }

                        Spacer(minLength: 8)

                        VenusIllustrationCluster(
                            symbols: [
                                VenusIllustrationSymbol(systemName: "heart.text.square.fill", tint: VenusTheme.accentBlue, size: 16),
                                VenusIllustrationSymbol(systemName: "waveform.path.ecg", tint: VenusTheme.accentPink, size: 14),
                                VenusIllustrationSymbol(systemName: "sparkles", tint: VenusTheme.accentOrange, size: 14)
                            ],
                            width: 98,
                            height: 80
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(insights) { insight in
                        HomeVisualInsightCard(insight: insight)
                            .onTapGesture {
                                onTapInsight(insight)
                            }
                    }
                }
            }

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Outras ideias para hoje")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)

                        Text("Rotas parecidas para variar sem pensar muito.")
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(suggestions) { suggestion in
                                ChipView(
                                    title: suggestion.activityTitle,
                                    subtitle: "\(suggestion.durationMinutes) min · \(suggestion.activityCategory)",
                                    icon: suggestion.iconName
                                )
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 2)
                    }
                    .scrollClipDisabled()
                }
            }
        }
    }
}

private struct HomeVisualInsightCard: View {
    let insight: HomeVisualInsight

    private var isProCard: Bool {
        insight.kind == .forecastLocked
    }

    var body: some View {
        Group {
            if isProCard {
                cardContent
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .venusProGlassCardStyle(cornerRadius: 24)
            } else {
                VenusCard(cornerRadius: 24, padding: 16) {
                    cardContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill((isProCard ? VenusTheme.accentPurple : insight.tint).opacity(0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: insight.systemImage)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isProCard ? VenusTheme.accentPurple : insight.tint)
                }

                Spacer()

                if isProCard {
                    VenusProBadge(compact: true)
                } else if let badgeText = insight.badgeText {
                    Text(badgeText)
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(insight.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(insight.tint.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Text(insight.label)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(insight.title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            if let progress = insight.progress {
                InsightGaugeView(value: progress, tint: insight.tint)
            } else if let values = insight.sparklineValues {
                InsightSparklineView(values: values, tint: insight.tint)
            }

            Text(insight.detail)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct HomeMiniProgressBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let clampedValue = max(0, min(value, 1))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(VenusTheme.cardBorder.opacity(0.4))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.55), tint],
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

private struct InsightGaugeView: View {
    let value: Double
    let tint: Color
    @State private var appeared = false

    private var label: String {
        if value >= 0.7 { return "alto" }
        if value >= 0.45 { return "médio" }
        return "baixo"
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.15), lineWidth: 5)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: appeared ? max(0.04, value) : 0)
                    .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.75), value: appeared)

                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(tint.opacity(0.12))
                        Capsule()
                            .fill(LinearGradient(colors: [tint.opacity(0.5), tint], startPoint: .leading, endPoint: .trailing))
                            .frame(width: appeared ? max(12, geo.size.width * value) : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1), value: appeared)
                    }
                }
                .frame(height: 6)

                Text(label)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(tint)
            }
        }
        .onAppear { appeared = true }
    }
}

private struct InsightSparklineView: View {
    let values: [Double]
    let tint: Color
    @State private var appeared = false

    private struct SparkPoint: Identifiable {
        let id: Int
        let value: Double
    }

    private var points: [SparkPoint] {
        values.enumerated().map { SparkPoint(id: $0.offset, value: $0.element) }
    }

    private var trend: String {
        guard let first = values.first, let last = values.last else { return "" }
        let delta = last - first
        if delta > 0.05 { return "↗ subindo" }
        if delta < -0.05 { return "↘ caindo" }
        return "→ estável"
    }
    private var trendColor: Color {
        guard let first = values.first, let last = values.last else { return VenusTheme.textSecondary }
        let delta = last - first
        if delta > 0.05 { return tint }
        if delta < -0.05 { return VenusTheme.accentPink }
        return VenusTheme.textSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Chart(points) { point in
                AreaMark(
                    x: .value("Dia", point.id),
                    y: .value("Val", appeared ? point.value : 0)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(tint.opacity(0.15))

                LineMark(
                    x: .value("Dia", point.id),
                    y: .value("Val", appeared ? point.value : 0)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .foregroundStyle(tint)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 32)
            .animation(.spring(response: 0.9, dampingFraction: 0.8), value: appeared)
            .onAppear { appeared = true }

            HStack {
                Text("7 dias")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                Spacer()
                Text(trend)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(trendColor)
            }
        }
    }
}

private struct ChipView: View {
    let title: String
    let subtitle: String
    let icon: String

    private var iconTint: Color {
        switch icon {
        case let value where value.contains("heart"):
            return VenusTheme.accentPink
        case let value where value.contains("leaf") || value.contains("figure") || value.contains("wind"):
            return VenusTheme.accentGreen
        case let value where value.contains("timer") || value.contains("clock") || value.contains("calendar"):
            return VenusTheme.accentBlue
        case let value where value.contains("moon") || value.contains("sparkles") || value.contains("star"):
            return VenusTheme.accentPurple
        default:
            return VenusTheme.accentOrange
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconTint.opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(iconTint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                Text(subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
//        .background(VenusTheme.surface)
//        .clipShape(Capsule())
    }
}
