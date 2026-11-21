//
//  VenusRadialClusterView.swift
//  Venus
//
//  Arranjo radial orgânico dos 6 seixos de vidro translúcido ao redor
//  da pérola central luminosa (nodo de luz biológica no centro da garganta/tórax).
//

import SwiftUI

public struct VenusRadialClusterView: View {
    @Binding public var selectedMode: VenusWellnessMode
    public var onSelectMode: ((VenusWellnessMode) -> Void)? = nil

    @State private var pearlPulse: CGFloat = 1.0
    @State private var haloOpacity: Double = 0.85

    public init(
        selectedMode: Binding<VenusWellnessMode>,
        onSelectMode: ((VenusWellnessMode) -> Void)? = nil
    ) {
        self._selectedMode = selectedMode
        self.onSelectMode = onSelectMode
    }

    public var body: some View {
        ZStack {
            // 1. Feixe de luz suave conectando o nó central ao seixo selecionado
            activeLightBeam

            // 2. Pérola central de luz viva (Vagus / Bio-Energy Node)
            centralLightPearl

            // 3. Os 6 seixos distribuídos na formação de pétalas orgânicas
            pebbleGroup
        }
        .frame(width: 350, height: 280)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.8)
                .repeatForever(autoreverses: true)
            ) {
                pearlPulse = 1.15
                haloOpacity = 0.55
            }
        }
    }

    // MARK: - Pérola Central de Luz

    private var centralLightPearl: some View {
        ZStack {
            // Halo mais amplo
            Circle()
                .fill(selectedMode.activeAuraColor.opacity(0.40 * haloOpacity))
                .frame(width: 64, height: 64)
                .blur(radius: 14)

            // Halo intermediário
            Circle()
                .fill(Color.white.opacity(0.70))
                .frame(width: 28, height: 28)
                .blur(radius: 6)
                .scaleEffect(pearlPulse)

            // Núcleo branco brilhante puro
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .shadow(color: Color.white, radius: 8)
        }
        // Levemente deslocado do centro geométrico para harmonizar com a anatomia
        .offset(x: 4, y: 8)
    }

    // MARK: - Feixe de Conexão Radiante

    @ViewBuilder
    private var activeLightBeam: some View {
        let targetOffset = offset(for: selectedMode)
        let centerPoint = CGPoint(x: 175 + 4, y: 140 + 8)
        let destPoint = CGPoint(x: 175 + targetOffset.x, y: 140 + targetOffset.y)

        Canvas { context, _ in
            var path = Path()
            path.move(to: centerPoint)
            path.addLine(to: destPoint)

            let strokeStyle = StrokeStyle(
                lineWidth: 18,
                lineCap: .round
            )
            context.stroke(
                path,
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.45),
                        selectedMode.activeAuraColor.opacity(0.15),
                        Color.clear
                    ]),
                    center: centerPoint,
                    startRadius: 4,
                    endRadius: 70
                ),
                style: strokeStyle
            )
        }
        .blur(radius: 10)
    }

    // MARK: - Seixos Orgânicos

    private var pebbleGroup: some View {
        ZStack {
            // 1. Sleep (Superior / Topo)
            pebbleItem(
                mode: .sleep,
                offset: CGPoint(x: 8, y: -98),
                size: CGSize(width: 84, height: 56),
                asymmetry: 0.02
            )

            // 2. Stress (Superior Direito - Destaque do Design)
            pebbleItem(
                mode: .stress,
                offset: CGPoint(x: 52, y: -28),
                size: CGSize(width: 96, height: 72),
                asymmetry: 0.07
            )

            // 3. Anxiety (Lateral Direito)
            pebbleItem(
                mode: .anxiety,
                offset: CGPoint(x: 98, y: 22),
                size: CGSize(width: 86, height: 60),
                asymmetry: 0.04
            )

            // 4. Rest / Sleep (Inferior Direito)
            pebbleItem(
                mode: .rest,
                offset: CGPoint(x: 58, y: 74),
                size: CGSize(width: 82, height: 58),
                asymmetry: -0.04
            )

            // 5. Meditation (Inferior Central)
            pebbleItem(
                mode: .meditation,
                offset: CGPoint(x: -12, y: 86),
                size: CGSize(width: 94, height: 62),
                asymmetry: 0.03
            )

            // 6. Burnout (Lateral Esquerdo)
            pebbleItem(
                mode: .burnout,
                offset: CGPoint(x: -86, y: 18),
                size: CGSize(width: 86, height: 60),
                asymmetry: -0.05
            )
        }
    }

    private func pebbleItem(
        mode: VenusWellnessMode,
        offset: CGPoint,
        size: CGSize,
        asymmetry: CGFloat
    ) -> some View {
        VenusPebbleView(
            mode: mode,
            isSelected: selectedMode == mode,
            asymmetry: asymmetry,
            width: size.width,
            height: size.height,
            onTap: {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
                    selectedMode = mode
                }
                onSelectMode?(mode)
            }
        )
        .offset(x: offset.x, y: offset.y)
    }

    private func offset(for mode: VenusWellnessMode) -> CGPoint {
        switch mode {
        case .sleep:      return CGPoint(x: 8, y: -98)
        case .stress:     return CGPoint(x: 52, y: -28)
        case .anxiety:    return CGPoint(x: 98, y: 22)
        case .rest:       return CGPoint(x: 58, y: 74)
        case .meditation: return CGPoint(x: -12, y: 86)
        case .burnout:    return CGPoint(x: -86, y: 18)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "1F2E3A").ignoresSafeArea()
        VenusRadialClusterView(selectedMode: .constant(.stress))
    }
}
