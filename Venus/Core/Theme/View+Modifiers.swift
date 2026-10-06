//
//  View+Modifiers.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

// MARK: - Neumorphic Style Enum

public enum VenusNeumorphicStyle: Sendable {
    case raised      // Extruded 3D tactile soft card with deep dual shadows
    case flat        // Soft flat surface with dual shadows
    case sunken      // Recessed / carved / pressed cavity with dual inner shadows
    case convex      // Domed 3D tactile card with curved highlight reflection
    case bordered    // Raised with distinct monochrome bevel edge
}

// MARK: - Neumorphic Card Modifier (Pure Black & White - Refined Opacities)

struct NeumorphicCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 26
    var style: VenusNeumorphicStyle = .raised
    var depth: CGFloat = 8
    var showBorder: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool {
        colorScheme == .dark
    }

    // Top-left luminous highlight (Softened White glow)
    private var lightShadowColor: Color {
        isDark
            ? Color.white.opacity(0.09)
            : Color.white.opacity(0.80)
    }

    // Bottom-right deep ambient drop shadow (Pure Deep Black)
    private var darkShadowColor: Color {
        isDark
            ? Color.black.opacity(0.98)
            : Color.black.opacity(0.20)
    }

    // Secondary soft dark shadow in light mode for realistic penumbra
    private var softDarkShadowColor: Color {
        isDark
            ? Color.black.opacity(0.85)
            : Color(hex: "9E9E9E").opacity(0.75)
    }

    // Inner shadow dark tone (Pure Black)
    private var innerDarkShadowColor: Color {
        isDark
            ? Color.black.opacity(0.95)
            : Color.black.opacity(0.25)
    }

    // Inner shadow light highlight tone (Softened White)
    private var innerLightHighlightColor: Color {
        isDark
            ? Color.white.opacity(0.12)
            : Color.white.opacity(0.82)
    }

    // Monochrome tactile rim bevel (Softened subtle edge)
    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(isDark ? 0.14 : 0.65),
                Color.white.opacity(isDark ? 0.03 : 0.20),
                Color.black.opacity(isDark ? 0.60 : 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        switch style {
        case .raised, .bordered:
            content
                .background(
                    shape
                        .fill(VenusTheme.neumorphicRaisedGradient)
                        .overlay(
                            shape.stroke(strokeGradient, lineWidth: isDark ? 0.8 : 0.6)
                        )
                        // Top-left light shadow (softened white highlight)
                        .shadow(color: lightShadowColor, radius: depth * 1.4, x: -depth, y: -depth)
                        // Bottom-right dark drop shadow (deep black)
                        .shadow(color: darkShadowColor, radius: depth * 1.5, x: depth, y: depth)
                        .shadow(color: softDarkShadowColor, radius: depth * 0.8, x: depth * 0.6, y: depth * 0.6)
                )

        case .convex:
            content
                .background(
                    shape
                        .fill(VenusTheme.neumorphicRaisedGradient)
                        .overlay(
                            shape
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isDark ? 0.08 : 0.20),
                                            Color.clear,
                                            Color.black.opacity(isDark ? 0.35 : 0.06)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            shape.stroke(strokeGradient, lineWidth: 0.8)
                        )
                        .shadow(color: lightShadowColor, radius: depth * 1.4, x: -depth, y: -depth)
                        .shadow(color: darkShadowColor, radius: depth * 1.5, x: depth, y: depth)
                )

        case .flat:
            content
                .background(
                    shape
                        .fill(VenusTheme.neumorphicFlatGradient)
                        .overlay(
                            shape.stroke(strokeGradient, lineWidth: 0.6)
                        )
                        .shadow(color: lightShadowColor, radius: depth * 1.1, x: -depth * 0.7, y: -depth * 0.7)
                        .shadow(color: darkShadowColor, radius: depth * 1.2, x: depth * 0.7, y: depth * 0.7)
                )

        case .sunken:
            content
                .background(
                    shape
                        .fill(VenusTheme.neumorphicSunkenGradient)
                        // Top-leading inner dark shadow
                        .overlay(
                            shape
                                .stroke(innerDarkShadowColor, lineWidth: depth * 0.75)
                                .blur(radius: depth * 0.45)
                                .offset(x: depth * 0.45, y: depth * 0.45)
                                .mask(shape)
                        )
                        // Bottom-trailing inner light highlight
                        .overlay(
                            shape
                                .stroke(innerLightHighlightColor, lineWidth: depth * 0.75)
                                .blur(radius: depth * 0.45)
                                .offset(x: -depth * 0.45, y: -depth * 0.45)
                                .mask(shape)
                        )
                        .overlay(
                            shape
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(isDark ? 0.5 : 0.10),
                                            Color.white.opacity(isDark ? 0.08 : 0.35)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                )
        }
    }
}

// MARK: - Circular Neumorphic Modifier (Pure Black & White - Refined Opacities)

struct NeumorphicCircleModifier: ViewModifier {
    var style: VenusNeumorphicStyle = .raised
    var depth: CGFloat = 6

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    private var lightShadowColor: Color {
        isDark ? Color.white.opacity(0.09) : Color.white.opacity(0.80)
    }

    private var darkShadowColor: Color {
        isDark ? Color.black.opacity(0.98) : Color.black.opacity(0.20)
    }

    private var innerDarkShadowColor: Color {
        isDark ? Color.black.opacity(0.95) : Color.black.opacity(0.25)
    }

    private var innerLightHighlightColor: Color {
        isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.82)
    }

    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(isDark ? 0.14 : 0.65),
                Color.black.opacity(isDark ? 0.60 : 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func body(content: Content) -> some View {
        switch style {
        case .raised, .convex, .bordered:
            content
                .background(
                    Circle()
                        .fill(VenusTheme.neumorphicRaisedGradient)
                        .overlay(
                            Circle().stroke(strokeGradient, lineWidth: isDark ? 0.8 : 0.6)
                        )
                        .shadow(color: lightShadowColor, radius: depth * 1.4, x: -depth, y: -depth)
                        .shadow(color: darkShadowColor, radius: depth * 1.5, x: depth, y: depth)
                )
        case .sunken:
            content
                .background(
                    Circle()
                        .fill(VenusTheme.neumorphicSunkenGradient)
                        .overlay(
                            Circle()
                                .stroke(innerDarkShadowColor, lineWidth: depth * 0.75)
                                .blur(radius: depth * 0.45)
                                .offset(x: depth * 0.45, y: depth * 0.45)
                                .mask(Circle())
                        )
                        .overlay(
                            Circle()
                                .stroke(innerLightHighlightColor, lineWidth: depth * 0.75)
                                .blur(radius: depth * 0.45)
                                .offset(x: -depth * 0.45, y: -depth * 0.45)
                                .mask(Circle())
                        )
                )
        case .flat:
            content
                .background(
                    Circle()
                        .fill(VenusTheme.neumorphicFlatGradient)
                        .overlay(
                            Circle().stroke(strokeGradient, lineWidth: 0.6)
                        )
                        .shadow(color: lightShadowColor, radius: depth * 1.1, x: -depth * 0.7, y: -depth * 0.7)
                        .shadow(color: darkShadowColor, radius: depth * 1.2, x: depth * 0.7, y: depth * 0.7)
                )
        }
    }
}

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
    var cornerRadius: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .modifier(
                NeumorphicCardModifier(
                    cornerRadius: cornerRadius,
                    style: .raised,
                    depth: 8,
                    showBorder: true
                )
            )
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
    func neumorphicCard(
        cornerRadius: CGFloat = 26,
        style: VenusNeumorphicStyle = .raised,
        depth: CGFloat = 8,
        showBorder: Bool = true
    ) -> some View {
        modifier(
            NeumorphicCardModifier(
                cornerRadius: cornerRadius,
                style: style,
                depth: depth,
                showBorder: showBorder
            )
        )
    }

    func neumorphicCircle(
        style: VenusNeumorphicStyle = .raised,
        depth: CGFloat = 6
    ) -> some View {
        modifier(
            NeumorphicCircleModifier(
                style: style,
                depth: depth
            )
        )
    }

    func liquidGlass(cornerRadius: CGFloat = 24, opacity: Double = 0.6) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }

    func solidCardStyle(cornerRadius: CGFloat = 26) -> some View {
        modifier(SolidCardStyleModifier(cornerRadius: cornerRadius))
    }

    func venusScrollMotion(_ style: VenusScrollMotionStyle = .gentle) -> some View {
        modifier(VenusScrollMotionModifier(style: style))
    }
}
