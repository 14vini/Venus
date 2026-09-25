//
//  ReadinessInsightCards.swift
//  Venus
//
//  Breakdown explicável + tendência 7d + próxima ação.
//

import SwiftUI

// MARK: - Breakdown explicável ("Por que estou assim?")

struct ReadinessBreakdownView: View {
    let assessment: ReadinessEnergyAssessment
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Por que estou assim?")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(assessment.percentage100)%")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(assessment.tintColor)
            }

            if let b = assessment.breakdown {
                breakdownRow(label: "Check-in", value: b.subjectiveScore, weight: 1 - b.biometricWeight)
                if let bio = b.biometricScore {
                    breakdownRow(label: "Biometria", value: bio, weight: b.biometricWeight)
                } else {
                    Text("Sem biometria — score 100% subjetivo. Conecte o Apple Watch para calibrar.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
                if abs(b.weeklyAdjustment) >= 0.1 {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Tendência 7d: \(b.weeklyAdjustment >= 0 ? "+" : "")\(String(format: "%.1f", b.weeklyAdjustment))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                if b.chatDelta != 0 {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Conversa: \(b.chatDelta >= 0 ? "+" : "")\(String(format: "%.1f", b.chatDelta))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                if b.ecgCapped {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Ritmo observado — priorize descanso. Não é diagnóstico médico.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                if assessment.dataStale {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Dados biométricos desatualizados (>36h).")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                if !b.hasReliableBiometrics && assessment.biometricsUsed {
                    Text("Baseline HRV com \(b.baselineDays)d — precisa de 3d+ para confiança total.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Calibrando breakdown…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(VenusTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(VenusTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func breakdownRow(label: String, value: Double, weight: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                Spacer()
                Text("\(String(format: "%.1f", value)) · \(Int((weight * 100).rounded()))%")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 6)
                    Capsule()
                        .fill(assessment.tintColor)
                        .frame(width: geo.size.width * CGFloat(max(0, min(10, value)) / 10), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Tendência 7d (sparkline)

struct ReadinessTrendCard: View {
    let history: [Double]
    let weeklyTrend: WeeklyEmotionalTrend?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Últimos 7 check-ins")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .textCase(.uppercase)
                Spacer()
                if let trend = weeklyTrend {
                    Label(trend.direction.title, systemImage: trend.direction.iconName)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
            if history.isEmpty {
                Text("Faça 3+ check-ins para ver sua curva.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                sparkline
                    .frame(height: 44)
                if let trend = weeklyTrend {
                    Text(trend.summary)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(VenusTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(VenusTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private var sparkline: some View {
        GeometryReader { geo in
            let vals = history.map { max(1.0, min(10.0, $0)) }
            let maxV: Double = 10, minV: Double = 1
            let stepX = history.count > 1 ? geo.size.width / CGFloat(history.count - 1) : geo.size.width
            Path { path in
                for (i, v) in vals.enumerated() {
                    let x = CGFloat(i) * stepX
                    let norm = CGFloat((v - minV) / (maxV - minV))
                    let y = geo.size.height - norm * geo.size.height
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(VenusTheme.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Próxima ação (PatternEngine -> Home)

struct NextBestActionCard: View {
    let snapshot: PatternInsightsSnapshot?
    let onOpenChat: () -> Void

    var body: some View {
        guard let snap = snapshot else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("Próxima ação")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .textCase(.uppercase)
                HStack(spacing: 12) {
                    Image(systemName: snap.nextBestAction.kind.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(VenusTheme.primary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(VenusTheme.primary.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snap.nextBestAction.title)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                        Text(snap.nextBestAction.detail)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        Text("\(snap.nextBestAction.estimatedMinutes) min · \(snap.nextBestAction.strategicReason)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                if let alert = snap.patternAlert {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.title).font(.system(.caption, design: .rounded).weight(.bold))
                            Text(alert.detail).font(.system(.caption, design: .rounded)).foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.10)))
                }
                if let window = snap.weeklyInsights?.criticalWindow, !window.isEmpty {
                    Label("Queda recorrente: \(window)", systemImage: "clock.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Button(action: onOpenChat) {
                    Text("Pedir ajuda à Venus")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(VenusTheme.primaryGradient, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(VenusTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(VenusTheme.cardBorder, lineWidth: 1)
                    )
            )
        )
    }
}

#Preview("InsightCards") {
    VStack(spacing: 16) {
        ReadinessBreakdownView(assessment: .sampleDefault)
        ReadinessTrendCard(history: [6.5, 7.2, 5.8, 8.1, 7.4], weeklyTrend: nil)
    }
    .padding()
}
