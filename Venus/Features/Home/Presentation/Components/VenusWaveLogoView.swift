//
//  VenusWaveLogoView.swift
//  Venus
//
//  Ícone do logo da Venus no canto superior esquerdo:
//  Linhas fluidas sinusoidais concêntricas formando uma silhueta circular.
//

import SwiftUI

public struct VenusWaveLogoView: View {
    public var size: CGFloat = 36
    public var onTap: (() -> Void)? = nil

    public init(size: CGFloat = 36, onTap: (() -> Void)? = nil) {
        self.size = size
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        } label: {
            ZStack {
                // Brilho difuso suave ao fundo
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: size, height: size)
                    .blur(radius: 6)

                // Desenho vetorial das ondas fluidas
                Canvas { context, canvasSize in
                    let w = canvasSize.width
                    let h = canvasSize.height
                    let center = CGPoint(x: w / 2, y: h / 2)
                    let radius = min(w, h) * 0.42

                    let lineCount = 6
                    let spacing = (radius * 1.8) / CGFloat(lineCount)
                    let startY = center.y - (radius * 0.9)

                    for i in 0..<lineCount {
                        let y = startY + CGFloat(i) * spacing + spacing * 0.5
                        let dy = abs(y - center.y)
                        
                        // Largura da linha limitada pela borda do círculo
                        guard dy < radius else { continue }
                        let halfChord = sqrt(max(0, radius * radius - dy * dy)) * 0.92
                        let startX = center.x - halfChord
                        let endX = center.x + halfChord
                        let lineSpan = endX - startX
                        guard lineSpan > 6 else { continue }

                        var path = Path()
                        path.move(to: CGPoint(x: startX, y: y))

                        // Ondulação sinusoidal suave
                        let waveCount = 2.4
                        let steps = 24
                        let stepDx = lineSpan / CGFloat(steps)

                        for step in 1...steps {
                            let currX = startX + CGFloat(step) * stepDx
                            let progress = CGFloat(step) / CGFloat(steps)
                            let amplitude: CGFloat = 2.2
                            let currY = y + sin(progress * .pi * waveCount + CGFloat(i) * 0.5) * amplitude
                            path.addLine(to: CGPoint(x: currX, y: currY))
                        }

                        let strokeStyle = StrokeStyle(
                            lineWidth: 2.2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                        context.stroke(path, with: .color(Color.white.opacity(0.95)), style: strokeStyle)
                    }
                }
                .frame(width: size, height: size)
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Logo da Venus")
    }
}

#Preview {
    ZStack {
        Color(hex: "1F2E3A").ignoresSafeArea()
        VenusWaveLogoView(size: 44)
    }
}
