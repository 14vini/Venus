//
//  VenusPebbleShape.swift
//  Venus
//
//  Forma orgânica de seixo de vidro / pedra de rio polida,
//  com cantos arredondados contínuos e suave curvatura orgânica.
//

import SwiftUI

public struct VenusPebbleShape: Shape {
    /// Variação sutil de assimetria para dar sensação de pedras de rio naturais
    public var asymmetry: CGFloat = 0.05
    public var cornerRadiusRatio: CGFloat = 0.38

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        let cr = min(w, h) * cornerRadiusRatio
        let dx = w * asymmetry
        let dy = h * asymmetry * 0.5
        
        // Ponto superior esquerdo com leve recuo orgânico
        let topLeft = CGPoint(x: rect.minX + cr - dx * 0.5, y: rect.minY + dy)
        let topRight = CGPoint(x: rect.maxX - cr + dx * 0.5, y: rect.minY - dy * 0.3)
        let bottomRight = CGPoint(x: rect.maxX - cr - dx * 0.4, y: rect.maxY - dy)
        let bottomLeft = CGPoint(x: rect.minX + cr + dx * 0.3, y: rect.maxY + dy * 0.4)
        
        path.move(to: CGPoint(x: topLeft.x, y: rect.minY + dy))
        
        // Borda superior
        path.addLine(to: CGPoint(x: topRight.x, y: rect.minY - dy * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX + dx * 0.2, y: rect.minY + cr),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        
        // Borda direita
        path.addLine(to: CGPoint(x: rect.maxX - dx * 0.1, y: rect.maxY - cr))
        path.addQuadCurve(
            to: CGPoint(x: bottomRight.x, y: rect.maxY - dy),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        
        // Borda inferior
        path.addLine(to: CGPoint(x: bottomLeft.x, y: rect.maxY + dy * 0.4))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX - dx * 0.2, y: rect.maxY - cr),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        
        // Borda esquerda
        path.addLine(to: CGPoint(x: rect.minX + dx * 0.1, y: rect.minY + cr))
        path.addQuadCurve(
            to: CGPoint(x: topLeft.x, y: rect.minY + dy),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        
        path.closeSubpath()
        return path
    }
}
