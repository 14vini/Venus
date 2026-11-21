//
//  VenusCheckInSkyBackground.swift
//  Venus
//
//  Fundo azul-celeste pastel suave com silhuetas botânicas etéreas,
//  idêntico à atmosfera da referência visual.
//

import SwiftUI

struct VenusCheckInSkyBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var waveShift: CGFloat = 0

    var body: some View {
        ZStack {
            // Gradiente de céu suave principal
            LinearGradient(
                colors: skyColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Silhuetas de curvas orgânicas / botânicas de fundo
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height

                // Curva orgânica 1 (lado esquerdo)
                Path { path in
                    path.move(to: CGPoint(x: -w * 0.2, y: h * 0.45))
                    path.addCurve(
                        to: CGPoint(x: w * 0.55, y: h * 0.85),
                        control1: CGPoint(x: w * 0.1, y: h * 0.50),
                        control2: CGPoint(x: w * 0.25, y: h * 0.78)
                    )
                    path.addCurve(
                        to: CGPoint(x: w * 0.35, y: h * 1.1),
                        control1: CGPoint(x: w * 0.65, y: h * 0.90),
                        control2: CGPoint(x: w * 0.50, y: h * 1.05)
                    )
                }
                .stroke(
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.28),
                    lineWidth: 65
                )
                .blur(radius: 20)

                // Curva orgânica 2 (lado direito)
                Path { path in
                    path.move(to: CGPoint(x: w * 1.2, y: h * 0.15))
                    path.addCurve(
                        to: CGPoint(x: w * 0.50, y: h * 0.55),
                        control1: CGPoint(x: w * 0.85, y: h * 0.22),
                        control2: CGPoint(x: w * 0.70, y: h * 0.42)
                    )
                }
                .stroke(
                    Color.white.opacity(colorScheme == .dark ? 0.06 : 0.22),
                    lineWidth: 50
                )
                .blur(radius: 18)

                // Brilho difuso celestial no topo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                                Color.clear
                            ],
                            center: .top,
                            startRadius: 0,
                            endRadius: w * 0.8
                        )
                    )
                    .frame(width: w * 1.2, height: w * 1.2)
                    .position(x: w * 0.5, y: 0)
            }
            .ignoresSafeArea()
        }
    }

    private var skyColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: "0C1424"),
                Color(hex: "142138"),
                Color(hex: "0A101C")
            ]
        }
        return [
            Color(hex: "B7D3F7"),
            Color(hex: "C6DCF9"),
            Color(hex: "D9E9FC")
        ]
    }
}
