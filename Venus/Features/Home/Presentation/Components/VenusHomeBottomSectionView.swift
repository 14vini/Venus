//
//  VenusHomeBottomSectionView.swift
//  Venus
//
//  Seção inferior da Home: Tipografia hero em destaque ("Start Your Stress / Relief Mode"),
//  subtítulo de regulação do sistema nervoso, botão de ação em vidro fosco
//  e barra de prontidão integrada da Venus.
//

import SwiftUI

public struct VenusHomeBottomSectionView: View {
    public let mode: VenusWellnessMode
    public let assessment: ReadinessEnergyAssessment
    public var onStartMode: () -> Void
    public var onReadinessTap: () -> Void
    public var onCheckInTap: () -> Void
    public var onGalaxyTap: () -> Void

    public init(
        mode: VenusWellnessMode,
        assessment: ReadinessEnergyAssessment,
        onStartMode: @escaping () -> Void,
        onReadinessTap: @escaping () -> Void,
        onCheckInTap: @escaping () -> Void,
        onGalaxyTap: @escaping () -> Void
    ) {
        self.mode = mode
        self.assessment = assessment
        self.onStartMode = onStartMode
        self.onReadinessTap = onReadinessTap
        self.onCheckInTap = onCheckInTap
        self.onGalaxyTap = onGalaxyTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Tipografia Hero Exata do Design
            VStack(alignment: .leading, spacing: -2) {
                Text("Start Your \(mode.titleFirst)")
                    .font(.system(size: 33, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(mode.titleSecond)
                    .font(.system(size: 33, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .contentTransition(.numericText())
            }

            // 2. Subtítulo descritivo com foco no sistema nervoso
            Text(mode.subtitle)
                .font(.system(size: 14.5, weight: .regular, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineSpacing(3)
                .padding(.top, 8)
                .contentTransition(.opacity)

            // 3. Botão de Ação Primária em Vidro Especular
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onStartMode()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .medium))

                    Text("Iniciar Modo \(mode.label)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color(hex: "0E1E2B"))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color(hex: "F2F7FA")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 12, y: 4)
                        .shadow(color: mode.activeAuraColor.opacity(0.35), radius: 16, y: 6)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 18)

            // 4. Barra de Telemetria e Prontidão da Venus (Acesso Rápido)
            HStack(spacing: 12) {
                // Pílula de Prontidão
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onReadinessTap()
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "56D2C8"))
                            .frame(width: 7, height: 7)

                        Text("Prontidão \(assessment.percentage100)%")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.85))

                        Text("·")
                            .foregroundStyle(Color.white.opacity(0.5))

                        Text(shortStateTitle)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.70))
                            .lineLimit(1)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.50))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // Botão de Galaxy Emocional
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onGalaxyTap()
                } label: {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Abrir Galaxy Emocional")

                // Botão de Check-in Rápido
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onCheckInTap()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fazer check-in")
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: mode)
    }

    private var shortStateTitle: String {
        let title = assessment.stateTitle
        if title.hasPrefix("Prontidão ") {
            return String(title.dropFirst("Prontidão ".count))
        }
        return title
    }
}

#Preview {
    ZStack {
        Color(hex: "1F2E3A").ignoresSafeArea()
        VenusHomeBottomSectionView(
            mode: .stress,
            assessment: .sampleDefault,
            onStartMode: {},
            onReadinessTap: {},
            onCheckInTap: {},
            onGalaxyTap: {}
        )
    }
}
