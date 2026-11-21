//
//  VenusHomeReadinessPanelView.swift
//  Venus
//
//  F19 — painel de prontidão no estilo "Day 1": gradiente rosa/lilás → branco,
//  número grande, arco com pontos, frase curta e CTA escuro em pill.
//  Substitui o antigo painel de anéis sobre vidro da F10/F12.
//

import SwiftUI

/// Painel inferior da Home. Não é um card pesado: é a continuação suave do fundo.
struct VenusHomeReadinessPanelView: View {
    let assessment: ReadinessEnergyAssessment
    let recentMoodEmojis: [String]
    let onReadinessTap: () -> Void
    let onCheckInTap: () -> Void
    let onChatTap: () -> Void
    var compact: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var progress: CGFloat { CGFloat(max(0.0, min(1.0, assessment.percentage))) }

    var body: some View {
        VStack(spacing: 0) {
            eyebrow

            VenusHomeReadinessArc(progress: progress, tint: accent, isDark: isDark)
                .padding(.top, compact ? 4 : 10)

            score
                .padding(.top, compact ? 2 : 4)

            Text("SEU RITMO DE HOJE")
                .font(.system(size: compact ? 8 : 9, weight: .medium, design: .rounded))
                .kerning(3.2)
                .foregroundStyle(caption)

            Text("Cada escolha sua acende o seu caminho.")
                .font(.system(size: compact ? 12 : 13, weight: .light, design: .rounded))
                .foregroundStyle(bodyText)
                .multilineTextAlignment(.center)
                .padding(.top, compact ? 10 : 16)

            miniatures
                .padding(.top, compact ? 8 : 12)

            detailsButton
                .padding(.top, compact ? 12 : 18)

            footerActions
                .padding(.top, compact ? 10 : 14)
                .padding(.bottom, compact ? 12 : 18)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [gradientTop, gradientMiddle, gradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    // MARK: - Cabeçalho

    private var eyebrow: some View {
        HStack(spacing: 7) {
            VenusHomeSparkleView(size: 10, color: accent, opacity: 0.85)
            Text("SUA PRONTIDÃO")
                .font(.system(size: compact ? 9 : 10, weight: .medium, design: .rounded))
                .kerning(4)
                .foregroundStyle(caption)
        }
        .padding(.top, compact ? 14 : 22)
    }

    private var score: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(assessment.percentage100)")
                .font(.system(size: compact ? 54 : 66, weight: .semibold, design: .rounded))
                .foregroundStyle(numberColor)
                .contentTransition(.numericText())
                .accessibilityLabel("Prontidão \(assessment.percentage100) por cento")

            Text("%")
                .font(.system(size: compact ? 20 : 24, weight: .light, design: .rounded))
                .foregroundStyle(caption)
        }
    }

    // MARK: - Miniaturas sutis

    private var miniatures: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white.opacity(isDark ? 0.10 : 0.66))
                    if recentMoodEmojis.indices.contains(index) {
                        Text(recentMoodEmojis[index])
                            .font(.system(size: 13))
                    } else {
                        VenusHomeSparkleView(size: 9, color: accent, opacity: 0.55)
                    }
                }
                .frame(width: 28, height: 28)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Ações

    private var detailsButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onReadinessTap()
        } label: {
            HStack(spacing: 8) {
                Text("Ver detalhes")
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 44 : 50)
            .background(Capsule(style: .continuous).fill(buttonColor))
            .padding(.horizontal, 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ver detalhes da prontidão")
    }

    private var footerActions: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onCheckInTap()
                } label: {
                    Label("Check-in", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.glass)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onChatTap()
                } label: {
                    Label("Conversar", systemImage: "bubble.left.and.bubble.right")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 26)
        }
    }

    // MARK: - Paleta local

    private var gradientTop: Color {
        isDark ? Color(hex: "3B2A4C") : Color(hex: "E6D8F5")
    }

    private var gradientMiddle: Color {
        isDark ? Color(hex: "2C2039") : Color(hex: "F5DBE9")
    }

    private var gradientBottom: Color {
        isDark ? Color(hex: "17131F") : Color(hex: "FFFFFF")
    }

    private var accent: Color {
        isDark ? Color(hex: "C6B4F2") : Color(hex: "E58FB0")
    }

    private var caption: Color {
        isDark ? Color.white.opacity(0.72) : Color(hex: "9B7997")
    }

    private var numberColor: Color {
        isDark ? Color.white : Color(hex: "2B2130")
    }

    private var bodyText: Color {
        isDark ? Color.white.opacity(0.74) : Color(hex: "6B586E")
    }

    private var buttonColor: Color {
        isDark ? Color(hex: "3B3442") : Color(hex: "241E2B")
    }
}

// MARK: - Arco de progresso com pontos

private struct VenusHomeReadinessArc: View {
    let progress: CGFloat
    let tint: Color
    let isDark: Bool

    private let dotCount = 5

    var body: some View {
        GeometryReader { geometry in
            let rect = geometry.frame(in: .local)

            ZStack {
                VenusHomeJourneyArcShape()
                    .stroke(
                        isDark ? Color.white.opacity(0.16) : Color.white.opacity(0.72),
                        lineWidth: 1.5
                    )

                VenusHomeJourneyArcShape()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .animation(.smooth(duration: 0.6), value: progress)

                ForEach(0..<dotCount, id: \.self) { index in
                    let position = CGFloat(index) / CGFloat(dotCount - 1)
                    let point = bezierPoint(t: position, in: rect)
                    let reached = position <= progress + 0.001

                    Circle()
                        .fill(reached ? Color.white : tint.opacity(isDark ? 0.36 : 0.48))
                        .frame(width: reached ? 11 : 7, height: reached ? 11 : 7)
                        .shadow(
                            color: reached ? tint.opacity(0.7) : .clear,
                            radius: reached ? 8 : 0,
                            y: reached ? 1 : 0
                        )
                        .position(point)
                }
            }
        }
        .frame(height: 52)
    }

    private func bezierPoint(t: CGFloat, in rect: CGRect) -> CGPoint {
        let p0 = CGPoint(x: rect.minX + 6, y: rect.maxY - 6)
        let p1 = CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + 2)
        let p2 = CGPoint(x: rect.minX + rect.width * 0.7, y: rect.minY + 2)
        let p3 = CGPoint(x: rect.maxX - 6, y: rect.maxY - 6)
        let mt = 1 - t
        return CGPoint(
            x: mt * mt * mt * p0.x + 3 * mt * mt * t * p1.x + 3 * mt * t * t * p2.x + t * t * t * p3.x,
            y: mt * mt * mt * p0.y + 3 * mt * mt * t * p1.y + 3 * mt * t * t * p2.y + t * t * t * p3.y
        )
    }
}

private struct VenusHomeJourneyArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 6, y: rect.maxY - 6))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 6, y: rect.maxY - 6),
            control1: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + 2),
            control2: CGPoint(x: rect.minX + rect.width * 0.7, y: rect.minY + 2)
        )
        return path
    }
}

#Preview {
    VenusHomeReadinessPanelView(
        assessment: .sampleDefault,
        recentMoodEmojis: ["😌", "🙂", "✨"],
        onReadinessTap: {},
        onCheckInTap: {},
        onChatTap: {}
    )
}
