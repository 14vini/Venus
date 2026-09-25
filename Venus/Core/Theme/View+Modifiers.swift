//
//  View+Modifiers.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

// MARK: - Liquid Glass Modifier

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var opacity: Double = 0.6

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.16),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.overlay)
                    )
            )
    }
}

// MARK: - Solid Card Style Modifier

struct SolidCardStyleModifier: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(VenusTheme.cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(VenusTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Scroll Motion Modifier

enum VenusScrollMotionStyle {
    case gentle
    case strong

    var scale: CGFloat {
        switch self {
        case .gentle: return 0.985
        case .strong: return 0.97
        }
    }

    var opacity: Double {
        switch self {
        case .gentle: return 0.92
        case .strong: return 0.85
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .gentle: return 6
        case .strong: return 12
        }
    }
}

private struct VenusScrollMotionModifier: ViewModifier {
    let style: VenusScrollMotionStyle

    func body(content: Content) -> some View {
        let opacity = style.opacity
        let scale = style.scale
        let yOffset = style.yOffset

        content.scrollTransition(.animated(.smooth(duration: 0.35))) { view, phase in
            view
                .opacity(phase.isIdentity ? 1 : opacity)
                .scaleEffect(phase.isIdentity ? 1 : scale)
                .offset(y: phase.isIdentity ? 0 : yOffset)
        }
    }
}

// MARK: - View Extensions

extension View {
    func liquidGlass(cornerRadius: CGFloat = 24, opacity: Double = 0.6) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }

    func solidCardStyle(cornerRadius: CGFloat = 24) -> some View {
        modifier(SolidCardStyleModifier(cornerRadius: cornerRadius))
    }

    func venusScrollMotion(_ style: VenusScrollMotionStyle = .gentle) -> some View {
        modifier(VenusScrollMotionModifier(style: style))
    }
}
