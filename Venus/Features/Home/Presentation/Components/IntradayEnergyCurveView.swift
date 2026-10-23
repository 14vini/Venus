//
//  IntradayEnergyCurveView.swift
//  Venus
//
//  Created by Kaua on 29/09/26.
//

import SwiftUI

public struct IntradayEnergyCurveView: View {
    let curve: IntradayEnergyCurve
    let baseScore: Double
    var onDetailTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: CGFloat = 0.0
    @State private var pulseWave: Bool = false

    private var isDark: Bool { colorScheme == .dark }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealAccent: Color { Color(hex: "0D9488") }

    public init(
        curve: IntradayEnergyCurve = .sampleDefault,
        baseScore: Double = 8.0,
        onDetailTap: (() -> Void)? = nil
    ) {
        self.curve = curve
        self.baseScore = baseScore
        self.onDetailTap = onDetailTap
    }

    public var body: some View {
        Button {
            onDetailTap?()
        } label: {
            VStack(alignment: .leading, spacing: 18) {
                // Header (No emojis)
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isDark ? mintColor : tealAccent)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill((isDark ? mintColor : tealAccent).opacity(0.14))
                            )
                            .scaleEffect(pulseWave ? 1.08 : 0.95)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Ritmo de Energia Hoje")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(VenusTheme.text)

                            Text("Oscilação circadiana prevista para o dia")
                                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(curve.currentPhaseName)
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(isDark ? mintColor : tealAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill((isDark ? mintColor : tealAccent).opacity(isDark ? 0.16 : 0.12))
                            )

                        if onDetailTap != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(VenusTheme.textTertiary)
                        }
                    }
                }

                // Extra Large & Thick Wave Chart (Height: 120px)
                ZStack {
                    GeometryReader { geo in
                        let width = geo.size.width
                        let height = geo.size.height
                        let points = curve.points

                        if points.count >= 2 {
                            let minScore: Double = 3.0
                            let maxScore: Double = 10.0
                            let range = max(1.0, maxScore - minScore)

                            let coordinates: [CGPoint] = points.enumerated().map { idx, pt in
                                let x = (CGFloat(idx) / CGFloat(points.count - 1)) * (width - 32) + 16
                                let normalizedY = CGFloat((pt.estimatedScore - minScore) / range)
                                let y = height - (normalizedY * (height - 28) + 14)
                                return CGPoint(x: x, y: max(8, min(height - 8, y)))
                            }

                            // Horizontal baseline grid lines
                            VStack(spacing: 0) {
                                Divider().opacity(isDark ? 0.08 : 0.15)
                                Spacer()
                                Divider().opacity(isDark ? 0.08 : 0.15)
                                Spacer()
                                Divider().opacity(isDark ? 0.08 : 0.15)
                            }
                            .padding(.horizontal, 8)

                            // Fill gradient under curve
                            Path { path in
                                path.move(to: CGPoint(x: coordinates[0].x, y: height))
                                path.addLine(to: coordinates[0])
                                for i in 1..<coordinates.count {
                                    let prev = coordinates[i - 1]
                                    let curr = coordinates[i]
                                    let midX = (prev.x + curr.x) / 2
                                    path.addCurve(
                                        to: curr,
                                        control1: CGPoint(x: midX, y: prev.y),
                                        control2: CGPoint(x: midX, y: curr.y)
                                    )
                                }
                                path.addLine(to: CGPoint(x: coordinates.last!.x, y: height))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (isDark ? mintColor : tealAccent).opacity(isDark ? 0.35 : 0.22),
                                        (isDark ? mintColor : tealAccent).opacity(0.02)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            // Thicker Stroke Curve Line (3.8px)
                            Path { path in
                                path.move(to: coordinates[0])
                                for i in 1..<coordinates.count {
                                    let prev = coordinates[i - 1]
                                    let curr = coordinates[i]
                                    let midX = (prev.x + curr.x) / 2
                                    path.addCurve(
                                        to: curr,
                                        control1: CGPoint(x: midX, y: prev.y),
                                        control2: CGPoint(x: midX, y: curr.y)
                                    )
                                }
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        isDark ? mintColor.opacity(0.7) : tealAccent.opacity(0.7),
                                        isDark ? mintColor : tealAccent
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 3.8, lineCap: .round, lineJoin: .round)
                            )

                            // Milestone Nodes
                            ForEach(0..<coordinates.count, id: \.self) { idx in
                                let pt = points[idx]
                                let coord = coordinates[idx]

                                ZStack {
                                    Circle()
                                        .fill(pt.isPastOrCurrent ? (isDark ? mintColor : tealAccent) : (isDark ? Color.white.opacity(0.25) : Color.black.opacity(0.2)))
                                        .frame(width: pt.isPastOrCurrent ? 10 : 7, height: pt.isPastOrCurrent ? 10 : 7)

                                    if pt.isPastOrCurrent {
                                        Circle()
                                            .stroke((isDark ? mintColor : tealAccent).opacity(0.4), lineWidth: 4.5)
                                            .frame(width: 19, height: 19)
                                    }
                                }
                                .position(coord)
                            }
                        }
                    }
                    .frame(height: 120)
                }

                // Time labels under chart
                HStack {
                    ForEach(curve.points) { pt in
                        Text(pt.timeLabel)
                            .font(.system(size: 11.5, weight: pt.isPastOrCurrent ? .bold : .medium, design: .rounded))
                            .foregroundColor(pt.isPastOrCurrent ? VenusTheme.text : VenusTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)

                // Current Phase Hint
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isDark ? mintColor : tealAccent)

                    Text(curve.currentPhaseSuggestion)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isDark ? Color(hex: "131313") : Color(hex: "DADADA"))
                )
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isDark ? Color(hex: "171717") : Color(hex: "E8E8E8"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(isDark ? 0.07 : 0.4), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedProgress = 1.0
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseWave = true
            }
        }
    }
}

#Preview {
    IntradayEnergyCurveView(curve: .sampleDefault, baseScore: 8.0)
        .padding()
        .preferredColorScheme(.dark)
}
