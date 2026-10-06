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
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isDark ? mintColor : tealAccent)

                        Text("Ritmo de Energia Hoje")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(curve.currentPhaseName)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(isDark ? mintColor : tealAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(isDark ? mintColor.opacity(0.12) : tealAccent.opacity(0.10))
                            )

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(VenusTheme.textTertiary)
                    }
                }

                // Mini Wave Chart
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
                                let x = (CGFloat(idx) / CGFloat(points.count - 1)) * (width - 24) + 12
                                let normalizedY = CGFloat((pt.estimatedScore - minScore) / range)
                                let y = height - (normalizedY * (height - 18) + 8)
                                return CGPoint(x: x, y: max(6, min(height - 6, y)))
                            }

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
                                        (isDark ? mintColor : tealAccent).opacity(isDark ? 0.25 : 0.15),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            // Stroke Curve Line
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
                                        isDark ? mintColor.opacity(0.6) : tealAccent.opacity(0.6),
                                        isDark ? mintColor : tealAccent
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                            )

                            // Milestone Nodes
                            ForEach(0..<coordinates.count, id: \.self) { idx in
                                let pt = points[idx]
                                let coord = coordinates[idx]

                                Circle()
                                    .fill(pt.isPastOrCurrent ? (isDark ? mintColor : tealAccent) : (isDark ? Color.white.opacity(0.25) : Color.black.opacity(0.2)))
                                    .frame(width: pt.isPastOrCurrent ? 7 : 5, height: pt.isPastOrCurrent ? 7 : 5)
                                    .position(coord)
                                    .shadow(
                                        color: pt.isPastOrCurrent ? (isDark ? mintColor : tealAccent).opacity(0.6) : .clear,
                                        radius: 3
                                    )
                            }
                        }
                    }
                    .frame(height: 52)
                }

                // Time labels under chart
                HStack {
                    ForEach(curve.points) { pt in
                        Text(pt.timeLabel)
                            .font(.system(size: 10, weight: pt.isPastOrCurrent ? .semibold : .regular, design: .rounded))
                            .foregroundColor(pt.isPastOrCurrent ? VenusTheme.text : VenusTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)

                // Current Phase Hint
                Text(curve.currentPhaseSuggestion)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(14)
            .neumorphicCard(cornerRadius: 18, style: .raised, depth: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    IntradayEnergyCurveView(curve: .sampleDefault, baseScore: 8.0)
        .padding()
        .preferredColorScheme(.dark)
}
