//
//  VenusPebbleView.swift
//  Venus
//
//  Seixo translúcido de vidro fosco (glassmorphism orgânico) representando
//  um modo de bem-estar. Possui reflexo especular de borda, halo luminoso ao ser
//  selecionado e suporte a física tátil.
//

import SwiftUI

public struct VenusPebbleView: View {
    public let mode: VenusWellnessMode
    public let isSelected: Bool
    public var asymmetry: CGFloat = 0.05
    public var width: CGFloat = 88
    public var height: CGFloat = 62
    public var onTap: () -> Void

    @State private var isPressed: Bool = false
    @State private var floatPhase: CGFloat = 0

    public init(
        mode: VenusWellnessMode,
        isSelected: Bool,
        asymmetry: CGFloat = 0.05,
        width: CGFloat = 88,
        height: CGFloat = 62,
        onTap: @escaping () -> Void
    ) {
        self.mode = mode
        self.isSelected = isSelected
        self.asymmetry = asymmetry
        self.width = width
        self.height = height
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        } label: {
            ZStack {
                let shape = VenusPebbleShape(asymmetry: asymmetry, cornerRadiusRatio: 0.36)

                // 1. Halo de iluminação externa quando ativo
                if isSelected {
                    shape
                        .fill(mode.activeAuraColor.opacity(0.65))
                        .frame(width: width * 1.25, height: height * 1.25)
                        .blur(radius: 18)
                }

                // 2. Sombra suave para relevo táctil sobre a névoa
                shape
                    .fill(Color(hex: "0A2234").opacity(isSelected ? 0.28 : 0.20))
                    .frame(width: width, height: height)
                    .offset(y: isSelected ? 8 : 6)
                    .blur(radius: isSelected ? 12 : 10)

                // 3. Superfície de vidro fosco (Vidro líquido esbranquiçado)
                if isSelected {
                    // Estado ativo: vidro iluminado com calor interno
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.92),
                                    mode.activeAuraColor.opacity(0.88),
                                    Color.white.opacity(0.80)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: width, height: height)
                        // Borda especular brilhante
                        .overlay(
                            shape
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            Color.white.opacity(0.60)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                } else {
                    // Estado inativo: vidro translúcido fosco e etéreo
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    Color(hex: "B7D1E2").opacity(0.18),
                                    Color.white.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: width, height: height)
                        // Borda especular delicada
                        .overlay(
                            shape
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.65),
                                            Color.white.opacity(0.18)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                }

                // 4. Conteúdo: Ícone + Rótulo
                VStack(spacing: 3) {
                    Image(systemName: mode.iconSystemName)
                        .font(.system(size: isSelected ? 16 : 14, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected ? Color(hex: "17202A") : Color.white.opacity(0.92)
                        )

                    Text(mode.label)
                        .font(.system(size: isSelected ? 12 : 11, weight: isSelected ? .semibold : .medium, design: .rounded))
                        .foregroundStyle(
                            isSelected ? Color(hex: "17202A") : Color.white.opacity(0.92)
                        )
                        .lineLimit(1)
                }
            }
            .scaleEffect(isSelected ? 1.07 : (isPressed ? 0.96 : 1.0))
            .offset(y: isSelected ? -2 : sin(floatPhase) * 2.0)
            .animation(.spring(response: 0.38, dampingFraction: 0.74), value: isSelected)
        }
        .buttonStyle(.plain)
        .onAppear {
            let randomDelay = Double.random(in: 0...2.0)
            withAnimation(
                .easeInOut(duration: Double.random(in: 3.5...5.0))
                .repeatForever(autoreverses: true)
                .delay(randomDelay)
            ) {
                floatPhase = .pi * 2
            }
        }
        .accessibilityLabel("\(mode.label), modo \(isSelected ? "selecionado" : "não selecionado")")
    }
}

#Preview {
    ZStack {
        Color(hex: "1F2E3A").ignoresSafeArea()
        HStack(spacing: 20) {
            VenusPebbleView(mode: .stress, isSelected: true, onTap: {})
            VenusPebbleView(mode: .sleep, isSelected: false, onTap: {})
            VenusPebbleView(mode: .burnout, isSelected: false, onTap: {})
        }
    }
}
