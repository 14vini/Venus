//
//  ReadinessEnergyGaugeView.swift
//  Venus
//
//  Created by Kaua on 23/09/26.
//

import SwiftUI
import UIKit

// MARK: - Main View

public struct ReadinessEnergyGaugeView: View {
    let assessment: ReadinessEnergyAssessment

    @State private var animatedProgress: Double = 0.0
    @State private var animatedScore: Double = 0.0
    @State private var detailsOpacity: Double = 0.0
    @State private var isPulsingGlow: Bool = false
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.0
    @State private var lastLevelKey: String = ""
    @State private var pendingWork: DispatchWorkItem?

    @Environment(\.colorScheme) private var colorScheme

    // Layout Constants
    private let arcStartAngle: Double = 160.0
    private let arcSweepAngle: Double = 220.0
    private let strokeWidth: CGFloat = 26.0

    public init(assessment: ReadinessEnergyAssessment = .sampleDefault) {
        self.assessment = assessment
    }

    public var body: some View {
        VStack(spacing: 18) {
            gaugeCardSurface
        }
        .onAppear(perform: handleOnAppear)
        .onChange(of: assessment.id) { _, _ in triggerFillAnimation() }
        .onChange(of: assessment.score) { _, _ in triggerFillAnimation() }
    }
}

// MARK: - Subviews

private extension ReadinessEnergyGaugeView {
    var headerSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.batteryblock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isDark ? neonMint : VenusTheme.primary)

                Text("Prontidão & Energia")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)
                    .textCase(.uppercase)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    var gaugeCardSurface: some View {
        VStack(spacing: 12) {
            archGaugeView
                .padding(.top)

            dividerLine
                .padding(.vertical)

            pillarsSection
                .padding(.horizontal, 10)
                .padding(.bottom, 16)
        }
    }

    var archGaugeView: some View {
        ZStack {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let centerX = width / 2.0
                let centerY = height * 0.76
                let radius = min(width * 0.38, 105.0)

                // Background Arch Track
                GaugeArcShape(startAngle: arcStartAngle, sweepAngle: arcSweepAngle)
                    .stroke(
                        trackColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: centerX, y: centerY)

                // Soft Energy Glow Behind Active Track
                GaugeArcShape(startAngle: arcStartAngle, sweepAngle: arcSweepAngle)
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        glowGradient,
                        style: StrokeStyle(lineWidth: strokeWidth * 0.95, lineCap: .round, lineJoin: .round)
                    )
                    .blur(radius: isDark ? 8 : 4)
                    .opacity(min(1.0, animatedProgress * 15.0) * (isDark ? 0.65 : 0.35))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: centerX, y: centerY)

                // Active Filling Track
                GaugeArcShape(startAngle: arcStartAngle, sweepAngle: arcSweepAngle)
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        activeGradient,
                        style: StrokeStyle(lineWidth: strokeWidth * 0.9, lineCap: .round, lineJoin: .round)
                    )
                    .opacity(min(1.0, animatedProgress * 20.0))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: centerX, y: centerY)

                // Thumb Indicator (smoothly follows circular path)
                thumbIndicator
                    .opacity(min(1.0, animatedProgress * 15.0))
                    .modifier(
                        ArcThumbPositionModifier(
                            progress: animatedProgress,
                            centerX: centerX,
                            centerY: centerY,
                            radius: radius,
                            startAngle: arcStartAngle,
                            sweepAngle: arcSweepAngle
                        )
                    )
            }
            .frame(height: 148)

            gaugeScoreLabels
                .offset(y: 12)
        }
    }

    var thumbIndicator: some View {
        ZStack {
            // Arrival Ripple Wave
            Circle()
                .stroke((isDark ? neonMint : accentTeal).opacity(ringOpacity), lineWidth: 1.5)
                .frame(width: 28, height: 28)
                .scaleEffect(ringScale)

            // Outer Glow Aura
            Circle()
                .fill((isDark ? neonMint : accentTeal).opacity(isDark ? 0.55 : 0.35))
                .frame(width: 28, height: 28)
                .blur(radius: isPulsingGlow ? 6 : 4)

            // Core Orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: isDark
                            ? [Color.white, neonMint, Color(hex: "1BE3B0")]
                            : [Color.white, accentTeal, lightTeal],
                        center: .center,
                        startRadius: 1,
                        endRadius: 9
                    )
                )
                .frame(width: 17, height: 17)
                .shadow(color: (isDark ? neonMint : accentTeal).opacity(0.8), radius: 6, x: 0, y: 0)
        }
    }

    var gaugeScoreLabels: some View {
        VStack(spacing: 2) {
            AnimatableScoreView(
                score: animatedScore,
                isInteger: isScoreInteger,
                font: .system(size: 44, weight: .bold, design: .rounded),
                color: primaryGaugeColor
            )
            .shadow(color: (isDark ? neonMint : accentTeal).opacity(isDark ? 0.25 : 0.1), radius: 8, x: 0, y: 2)

            Text(assessment.stateTitle)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundColor(primaryGaugeColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .opacity(detailsOpacity)
                .scaleEffect(detailsOpacity > 0.5 ? 1.0 : 0.95)
        }
    }

    var pillarsSection: some View {
        HStack(alignment: .center, spacing: 0) {
            ReadinessPillarColumn(metric: assessment.focusMetric) {
                ScopeRadarIcon(isDark: isDark)
            }

            DottedVerticalDivider(isDark: isDark)
                .frame(height: 44)

            ReadinessPillarColumn(metric: assessment.bodyMetric) {
                FourRingClusterIcon(isDark: isDark)
            }

            DottedVerticalDivider(isDark: isDark)
                .frame(height: 44)

            ReadinessPillarColumn(metric: assessment.sleepMetric) {
                BedSleepIcon(isDark: isDark)
            }
        }
        .opacity(detailsOpacity)
        .offset(y: detailsOpacity > 0.5 ? 0 : 6)
    }

    var dividerLine: some View {
        Rectangle()
            .fill(isDark ? Color.white.opacity(0.06) : accentTeal.opacity(0.12))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}

// MARK: - Computed Properties & Animations

private extension ReadinessEnergyGaugeView {
    var isDark: Bool {
        colorScheme == .dark
    }

    var normalizedScore: Double {
        let clamped = max(0.0, min(10.0, assessment.score))
        return clamped / 10.0
    }

    var isScoreInteger: Bool {
        assessment.score.truncatingRemainder(dividingBy: 1) == 0
    }

    var neonMint: Color { Color(hex: "00F5D4") }
    var lightTeal: Color { Color(hex: "0F766E") }
    var accentTeal: Color { Color(hex: "0D9488") }
    var primaryGaugeColor: Color { isDark ? neonMint : lightTeal }

    var activeGradient: LinearGradient {
        LinearGradient(
            colors: [
                isDark ? Color(hex: "0D4E42") : Color(hex: "5EEAD4"),
                isDark ? Color(hex: "1BE3B0") : accentTeal,
                isDark ? neonMint : lightTeal
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var glowGradient: LinearGradient {
        LinearGradient(
            colors: [
                isDark ? Color(hex: "0D4E42").opacity(0.35) : Color(hex: "5EEAD4").opacity(0.35),
                isDark ? neonMint.opacity(0.7) : accentTeal.opacity(0.6)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var trackColor: Color {
        isDark ? Color(hex: "0E3A33").opacity(0.78) : Color(hex: "B7EADE").opacity(0.65)
    }

    func handleOnAppear() {
        triggerFillAnimation()
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            isPulsingGlow = true
        }
    }

    func triggerFillAnimation() {
        // Debounce + animação incremental: se delta < 0.3, só interpola sem reset total
        pendingWork?.cancel()
        let targetProgress = normalizedScore
        let targetScore = assessment.score
        let delta = abs(targetScore - animatedScore)
        let isFirst = animatedProgress == 0 && animatedScore == 0

        if !isFirst && delta < 0.3 {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
                animatedProgress = targetProgress
                animatedScore = targetScore
            }
            return
        }

        // Reset states (só para mudanças relevantes)
        animatedProgress = isFirst ? 0.0 : animatedProgress
        if isFirst { animatedScore = 0.0 }
        detailsOpacity = detailsOpacity == 0 ? 0.0 : 1.0
        ringScale = 1.0
        ringOpacity = 0.0

        // Slight initial pause to let view layout settle before fluid fill
        let work = DispatchWorkItem {
            // Fluid progressive fill animation
            withAnimation(.spring(response: 1.25, dampingFraction: 0.82, blendDuration: 0.08)) {
                animatedProgress = targetProgress
                animatedScore = targetScore
            }

            // Staggered reveal for labels and pillar details
            withAnimation(.easeOut(duration: 0.45).delay(0.6)) {
                detailsOpacity = 1.0
            }

            // Arrival haptic SÓ em mudança de faixa (evita vibração a cada tick biométrico)
            let levelKey = assessment.level.rawValue
            let shouldHaptic = levelKey != lastLevelKey
            lastLevelKey = levelKey
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.88) {
                if shouldHaptic {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                ringScale = 0.8
                ringOpacity = 0.85
                withAnimation(.easeOut(duration: 0.65)) {
                    ringScale = 1.65
                    ringOpacity = 0.0
                }
            }
        }
        pendingWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
    }
}

// MARK: - Shapes & Animatable Modifiers

private struct GaugeArcShape: Shape {
    let startAngle: Double
    let sweepAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2.0
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(degrees: startAngle),
            endAngle: Angle(degrees: startAngle + sweepAngle),
            clockwise: false
        )
        return path
    }
}

private struct ArcThumbPositionModifier: AnimatableModifier {
    var progress: Double
    let centerX: CGFloat
    let centerY: CGFloat
    let radius: CGFloat
    let startAngle: Double
    let sweepAngle: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let angleRad = (startAngle + (sweepAngle * max(0.0, min(1.0, progress)))) * .pi / 180.0
        let x = centerX + radius * cos(angleRad)
        let y = centerY + radius * sin(angleRad)

        content
            .position(x: x, y: y)
    }
}

private struct AnimatableScoreView: View, Animatable {
    var score: Double
    var isInteger: Bool
    var font: Font
    var color: Color

    var animatableData: Double {
        get { score }
        set { score = newValue }
    }

    var body: some View {
        Text(formattedScore)
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
    }

    private var formattedScore: String {
        if isInteger {
            return "\(Int(round(score)))"
        } else {
            return String(format: "%.1f", score)
        }
    }
}

private struct ReadinessPillarColumn<Icon: View>: View {
    let metric: ReadinessPillarMetric
    @ViewBuilder let icon: () -> Icon
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var checkmarkBlue: Color { isDark ? Color(hex: "38BDF8") : Color(hex: "0284C7") }

    var body: some View {
        VStack(spacing: 8) {
            icon()
                .frame(height: 22)

            Image(systemName: metric.isCompleted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(metric.isCompleted ? checkmarkBlue : VenusTheme.accentOrange)
                .shadow(
                    color: metric.isCompleted ? checkmarkBlue.opacity(isDark ? 0.4 : 0.2) : .clear,
                    radius: 3,
                    x: 0,
                    y: 1
                )

            Text(metric.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(isDark ? .white.opacity(0.6) : VenusTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Icons

private struct ScopeRadarIcon: View {
    let isDark: Bool

    private var strokeColor: Color {
        isDark ? Color.white.opacity(0.85) : Color(hex: "134E4A")
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(strokeColor, lineWidth: 1.5)
                .frame(width: 18, height: 18)

            Circle()
                .stroke(strokeColor, lineWidth: 1.2)
                .frame(width: 10, height: 10)

            Circle()
                .fill(strokeColor)
                .frame(width: 3.5, height: 3.5)

            Rectangle()
                .fill(strokeColor)
                .frame(width: 1.2, height: 18)

            Rectangle()
                .fill(strokeColor)
                .frame(width: 18, height: 1.2)
        }
    }
}

private struct FourRingClusterIcon: View {
    let isDark: Bool

    private var strokeColor: Color {
        isDark ? Color.white.opacity(0.85) : Color(hex: "134E4A")
    }

    private let offsets: [CGPoint] = [
        CGPoint(x: -5.0, y: 0.0),
        CGPoint(x: 5.0, y: 0.0),
        CGPoint(x: 0.0, y: -5.0),
        CGPoint(x: 0.0, y: 5.0)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<offsets.count, id: \.self) { index in
                Circle()
                    .stroke(strokeColor, lineWidth: 1.4)
                    .frame(width: 6.5, height: 6.5)
                    .offset(x: offsets[index].x, y: offsets[index].y)
            }
        }
        .frame(width: 20, height: 20)
    }
}

private struct BedSleepIcon: View {
    let isDark: Bool

    private var tintColor: Color {
        isDark ? Color.white.opacity(0.85) : Color(hex: "134E4A")
    }

    var body: some View {
        Image(systemName: "bed.double.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(tintColor)
    }
}

private struct DottedVerticalDivider: View {
    let isDark: Bool

    private var dotColor: Color {
        isDark ? Color.white.opacity(0.2) : Color(hex: "0D9488").opacity(0.25)
    }

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<6, id: \.self) { _ in
                Circle()
                    .fill(dotColor)
                    .frame(width: 1.5, height: 1.5)
            }
        }
    }
}

// MARK: - Previews

#Preview("Dark Mode") {
    ZStack {
        Color.black.ignoresSafeArea()
        ReadinessEnergyGaugeView(assessment: .sampleDefault)
            .padding(20)
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    ZStack {
        VenusTheme.backgroundSoft.ignoresSafeArea()
        ReadinessEnergyGaugeView(assessment: .sampleDefault)
            .padding(20)
    }
    .preferredColorScheme(.light)
}
