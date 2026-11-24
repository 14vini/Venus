//
//  VenusChatHeaderView.swift
//  Venus
//
//  Cabeçalho do Chat no estilo da conversa: "Nova conversa" à esquerda, título
//  discreto ao centro com a Venus pequena e um único acesso aos detalhes à
//  direita. Sem barra carregada, sem texto de processo e sem vidro empilhado.
//

import SwiftUI

/// Cabeçalho de três zonas. O título é centralizado de verdade (ZStack + Spacer)
/// para não deslocar quando o botão de voltar aparece numa apresentação modal.
struct VenusChatHeaderView: View {
    let lens: SelfKnowledgeLens
    let isThinking: Bool
    let hasPendingReview: Bool
    /// Aparece apenas quando a tela foi apresentada modalmente.
    var isModal: Bool = false
    /// Zera a sessão atual e abre uma conversa nova (ação local do shell).
    var onNewChat: () -> Void = {}
    let onBack: () -> Void
    let onShowDetails: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                leading
                Spacer(minLength: 8)
                trailing
            }

            center
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, VenusChatVisualStyle.chromeHorizontalInset)
        .padding(.vertical, 8)
        .frame(maxWidth: VenusChatVisualStyle.chromeMaxWidth)
        .frame(maxWidth: .infinity)
        .contentTransition(.opacity)
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: lens)
    }

    // MARK: - Zonas

    private var leading: some View {
        HStack(spacing: 4) {
            if isModal {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(VenusTheme.text)
                        .frame(width: 36, height: 36)
                        .contentShape(Circle())
                }
                .buttonStyle(VenusChatSpringPressStyle())
                .accessibilityLabel("Voltar")
            }

            // Apenas o ícone na toolbar — sem texto e sem container próprio.
            Button(action: onNewChat) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(VenusTheme.text)
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .buttonStyle(VenusChatSpringPressStyle())
            .accessibilityLabel("Nova conversa")
        }
    }

    private var center: some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                VenusMoodOrb(
                    state: isThinking ? .thinking : .idle,
                    size: 26,
                    showHands: false,
                    showShadow: false,
                    isInteractive: false
                )
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: isThinking)

                // Um único Text: peso e tracking idênticos em "Venus" inteiro.
                Text("Venus")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .kerning(0.3)
                    .foregroundStyle(VenusTheme.text)
            }

            VenusChatHeaderArc(lens: lens, isDark: isDark, width: 62, height: 9)
                .accessibilityLabel("Lente: \(lens.shortTitle)")
        }
    }

    private var trailing: some View {
        Button(action: onShowDetails) {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(VenusTheme.text)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
                .overlay(alignment: .topTrailing) {
                    if hasPendingReview {
                        Circle()
                            .fill(VenusChatVisualStyle.lilac)
                            .frame(width: 7, height: 7)
                            .padding(.trailing, 4)
                            .padding(.top, 4)
                    }
                }
        }
        .buttonStyle(VenusChatSpringPressStyle())
        .accessibilityLabel("Detalhes da conversa")
    }
}

// MARK: - Arco de lentes

/// Arco com um ponto por lente. A lente ativa fica em branco com halo suave;
/// as anteriores em lilás e as seguintes discretas — sem nenhum rótulo de texto.
private struct VenusChatHeaderArc: View {
    let lens: SelfKnowledgeLens
    let isDark: Bool
    var width: CGFloat = 78
    var height: CGFloat = 13

    private let total = SelfKnowledgeLens.allCases.count

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
                    lineWidth: 1.2
                )

            VenusChatArcShape(width: width, height: height)
                .trim(from: 0, to: progress)
                .stroke(VenusChatVisualStyle.lilac.opacity(0.9), lineWidth: 1.8)

            ForEach(0..<total, id: \.self) { index in
                let point = arcPoint(at: index)
                let isCurrent = index == currentIndex

                Circle()
                    .fill(dotFill(for: index))
                    .frame(width: isCurrent ? 6 : 4, height: isCurrent ? 6 : 4)
                    .shadow(
                        color: isCurrent ? VenusChatVisualStyle.lilac.opacity(0.6) : .clear,
                        radius: isCurrent ? 5 : 0,
                        y: 1
                    )
                    .position(point)
                    .animation(.spring(response: 0.38, dampingFraction: 0.82), value: currentIndex)
            }
        }
        .frame(width: width, height: height)
    }

    private func dotFill(for index: Int) -> Color {
        if index == currentIndex { return .white }
        if index < currentIndex { return VenusChatVisualStyle.lilac.opacity(0.75) }
        return isDark ? Color.white.opacity(0.28) : Color.white.opacity(0.78)
    }

    private func arcPoint(at index: Int) -> CGPoint {
        let t = total <= 1 ? 0.5 : CGFloat(index) / CGFloat(total - 1)
        let p0 = CGPoint(x: 5, y: height - 3)
        let p1 = CGPoint(x: width * 0.3, y: 2)
        let p2 = CGPoint(x: width * 0.7, y: 2)
        let p3 = CGPoint(x: width - 5, y: height - 3)
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
        path.move(to: CGPoint(x: 5, y: height - 3))
        path.addCurve(
            to: CGPoint(x: width - 5, y: height - 3),
            control1: CGPoint(x: width * 0.3, y: 2),
            control2: CGPoint(x: width * 0.7, y: 2)
        )
        return path
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        VStack(spacing: 24) {
            VenusChatHeaderView(
                lens: .socratic,
                isThinking: false,
                hasPendingReview: true,
                isModal: false,
                onNewChat: {},
                onBack: {},
                onShowDetails: {}
            )
            VenusChatHeaderView(
                lens: .contradictionRadar,
                isThinking: true,
                hasPendingReview: false,
                isModal: true,
                onNewChat: {},
                onBack: {},
                onShowDetails: {}
            )
        }
    }
}
