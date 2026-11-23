//
//  VenusChatHeaderView.swift
//  Venus
//
//  Cabeçalho do Chat na linguagem da jornada: a Venus, a marca em tipografia
//  fina com negrito seletivo e um arco de pontos sutil no lugar de texto.
//  A lente ativa continua acessível nos detalhes; aqui ela só tinta o arco.
//

import SwiftUI

/// Cabeçalho minimalista do chat: a Venus pequena, o arco de lentes e o único
/// acesso secundário aos detalhes da conversa.
struct VenusChatHeaderView: View {
    let lens: SelfKnowledgeLens
    let isThinking: Bool
    let hasPendingReview: Bool
    let onBack: () -> Void
    let onShowDetails: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(VenusTheme.text)
                    .frame(width: 44, height: 44)
                    .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Voltar")

            HStack(spacing: 10) {
                VenusMoodOrb(
                    state: isThinking ? .thinking : .idle,
                    size: 30,
                    showHands: false,
                    showShadow: false,
                    isInteractive: false
                )
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: isThinking)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Ven\(Text("us").fontWeight(.semibold))")
                        .fontWeight(.light)
                        .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .contentTransition(.opacity)

                    VenusChatHeaderArc(lens: lens, isDark: isDark)
                        .frame(width: 78, height: 13)
                        .accessibilityLabel("Lente: \(lens.shortTitle)")
                }
            }

            Spacer(minLength: 8)

            Button(action: onShowDetails) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(VenusTheme.text)
                    .frame(width: 44, height: 44)
                    .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                    .clipShape(Circle())
                    .contentShape(Circle())
                    .overlay(alignment: .topTrailing) {
                        if hasPendingReview {
                            Circle()
                                .fill(VenusChatVisualStyle.lilac)
                                .frame(width: 7, height: 7)
                                .padding(.trailing, 5)
                                .padding(.top, 5)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Detalhes da conversa")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentTransition(.opacity)
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: lens)
    }
}

// MARK: - Arco de lentes

/// Arco com um ponto por lente. A lente ativa fica em branco com halo suave;
/// as anteriores em lilás e as seguintes discretas — sem nenhum rótulo de texto.
private struct VenusChatHeaderArc: View {
    let lens: SelfKnowledgeLens
    let isDark: Bool

    private let total = SelfKnowledgeLens.allCases.count
    private let width: CGFloat = 78
    private let height: CGFloat = 13

    private var currentIndex: Int {
        SelfKnowledgeLens.allCases.firstIndex(of: lens) ?? 0
    }

    private var progress: CGFloat {
        total <= 1 ? 1 : CGFloat(currentIndex) / CGFloat(total - 1)
    }

    var body: some View {
        ZStack {
            VenusChatArcShape(width: width, height: height)
                .stroke(
                    isDark ? Color.white.opacity(0.16) : Color.white.opacity(0.62),
                    lineWidth: 1.4
                )

            VenusChatArcShape(width: width, height: height)
                .trim(from: 0, to: progress)
                .stroke(VenusChatVisualStyle.lilac.opacity(0.9), lineWidth: 2.2)

            ForEach(0..<total, id: \.self) { index in
                let point = arcPoint(at: index)
                let isCurrent = index == currentIndex

                Circle()
                    .fill(dotFill(for: index))
                    .frame(width: isCurrent ? 8 : 5, height: isCurrent ? 8 : 5)
                    .shadow(
                        color: isCurrent ? VenusChatVisualStyle.lilac.opacity(0.6) : .clear,
                        radius: isCurrent ? 6 : 0,
                        y: 1
                    )
                    .position(point)
                    .animation(.spring(response: 0.38, dampingFraction: 0.82), value: currentIndex)
            }
        }
    }

    private func dotFill(for index: Int) -> Color {
        if index == currentIndex { return .white }
        if index < currentIndex { return VenusChatVisualStyle.lilac.opacity(0.75) }
        return isDark ? Color.white.opacity(0.28) : Color.white.opacity(0.78)
    }

    private func arcPoint(at index: Int) -> CGPoint {
        let t = total <= 1 ? 0.5 : CGFloat(index) / CGFloat(total - 1)
        let p0 = CGPoint(x: 6, y: height - 4)
        let p1 = CGPoint(x: width * 0.3, y: 2)
        let p2 = CGPoint(x: width * 0.7, y: 2)
        let p3 = CGPoint(x: width - 6, y: height - 4)
        let mt = 1 - t
        return CGPoint(
            x: mt * mt * mt * p0.x + 3 * mt * mt * t * p1.x + 3 * mt * t * t * p2.x + t * t * t * p3.x,
            y: mt * mt * mt * p0.y + 3 * mt * mt * t * p1.y + 3 * mt * t * t * p2.y + t * t * t * p3.y
        )
    }
}

private struct VenusChatArcShape: Shape {
    let width: CGFloat
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 6, y: height - 4))
        path.addCurve(
            to: CGPoint(x: width - 6, y: height - 4),
            control1: CGPoint(x: width * 0.3, y: 2),
            control2: CGPoint(x: width * 0.7, y: 2)
        )
        return path
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        VenusChatHeaderView(
            lens: .socratic,
            isThinking: false,
            hasPendingReview: true,
            onBack: {},
            onShowDetails: {}
        )
    }
}
