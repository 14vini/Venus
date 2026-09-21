//
//  VenusIllustrationComponents.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI

struct VenusIllustrationSymbol: Identifiable {
    let systemName: String
    let tint: Color
    var size: CGFloat = 17

    var id: String { "\(systemName)-\(Int(size))" }
}

struct VenusIllustrationCluster: View {
    let symbols: [VenusIllustrationSymbol]
    var width: CGFloat = 118
    var height: CGFloat = 96

    @State private var animate = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.84),
                            VenusTheme.cardSurface.opacity(0.96),
                            VenusTheme.backgroundSoft.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(VenusTheme.cardBorder.opacity(0.85), lineWidth: 1)

            Circle()
                .fill(VenusTheme.accentOrange.opacity(0.08))
                .frame(width: width * 0.64)
                .blur(radius: 24)
                .offset(x: -width * 0.16, y: -height * 0.1)

            Circle()
                .fill(VenusTheme.accentBlue.opacity(0.08))
                .frame(width: width * 0.52)
                .blur(radius: 26)
                .offset(x: width * 0.2, y: height * 0.16)

            ForEach(Array(symbols.prefix(3).enumerated()), id: \.element.id) { index, symbol in
                VenusIllustrationOrb(symbol: symbol, index: index, animate: animate)
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            guard !animate else { return }
            withAnimation(.easeInOut(duration: 3.1).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

private struct VenusIllustrationOrb: View {
    let symbol: VenusIllustrationSymbol
    let index: Int
    let animate: Bool

    private var orbSize: CGFloat {
        switch index {
        case 0: return 48
        case 1: return 42
        default: return 38
        }
    }

    private var baseOffset: CGSize {
        switch index {
        case 0: return CGSize(width: -26, height: -8)
        case 1: return CGSize(width: 24, height: -18)
        default: return CGSize(width: 12, height: 24)
        }
    }

    private var animatedOffset: CGSize {
        switch index {
        case 0: return CGSize(width: 4, height: -8)
        case 1: return CGSize(width: -6, height: 7)
        default: return CGSize(width: -4, height: -9)
        }
    }

    private var animatedScale: CGFloat {
        switch index {
        case 0: return 1.06
        case 1: return 0.94
        default: return 1.04
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(symbol.tint.opacity(0.14))
                .overlay(
                    Circle()
                        .stroke(symbol.tint.opacity(0.12), lineWidth: 1)
                )

            Image(systemName: symbol.systemName)
                .font(.system(size: symbol.size, weight: .bold))
                .foregroundColor(symbol.tint)
        }
        .frame(width: orbSize, height: orbSize)
        .shadow(color: symbol.tint.opacity(0.14), radius: 12, x: 0, y: 6)
        .offset(
            x: baseOffset.width + (animate ? animatedOffset.width : 0),
            y: baseOffset.height + (animate ? animatedOffset.height : 0)
        )
        .scaleEffect(animate ? animatedScale : 0.96)
    }
}
