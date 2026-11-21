//
//  VenusHomeSparkleView.swift
//  Venus
//
//  F10 — sparkle de quatro pontas usado nos pontos de luz da Home.
//

import SwiftUI

/// Sparkle de quatro pontas com lados côncavos (estrela de luz suave).
struct VenusHomeSparkleView: View {
    let size: CGFloat
    var color: Color = .white
    var opacity: Double = 0.85

    var body: some View {
        VenusHomeSparkleShape()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .allowsHitTesting(false)
    }
}

// MARK: - Shape

struct VenusHomeSparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()

        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: rect.maxY), control: center)
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: rect.minY), control: center)

        return path
    }
}

#Preview {
    ZStack {
        Color(hex: "C9CFEE")
        VenusHomeSparkleView(size: 40)
    }
}
