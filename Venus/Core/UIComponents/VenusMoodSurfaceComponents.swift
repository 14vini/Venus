//
//  VenusMoodSurfaceComponents.swift
//  Venus
//
//  Created by Kaua on 24/03/26.
//

import SwiftUI

struct VenusGlassPill: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = VenusTheme.moodMintStrong

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
            }

            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.72 : 0.92)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.10 : 0.06))
                        .blendMode(.overlay)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.14 : 0.22),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .blendMode(.overlay)
                )
        )
    }
}

struct VenusFloatingHintBubble: View {
    let title: String
    var bodyText: String = ""
    var systemImage: String? = nil
    var tint: Color = VenusTheme.moodMintStrong
    var maxWidth: CGFloat = 230

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let systemImage {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 30, height: 30)

                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(tint)
                }
            }

            VStack(alignment: .leading, spacing: bodyText.isEmpty ? 0 : 8) {
                Text(title)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                if !bodyText.isEmpty {
                    Text(bodyText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct VenusMoodWaveform: View {
    var tint: Color = VenusTheme.moodMintStrong
    var secondaryTint: Color = VenusTheme.moodMint
    var barHeights: [CGFloat] = [18, 24, 34, 48, 62, 76, 88, 76, 62, 48, 34, 24, 18]

    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                secondaryTint.opacity(0.1),
                                secondaryTint.opacity(0.34),
                                tint.opacity(index == barHeights.count / 2 ? 0.96 : 0.82)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 8, height: animate ? height : height * 0.9)
                    .opacity(animate ? 1 : 0.82)
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .frame(height: 88)
        .padding(.horizontal, 14)
        .onAppear {
            guard !animate else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct VenusMoodOrb: View {
    var mood: MoodType? = nil
    var state: VenusMascotState = .idle
    var expression: VenusMascotExpression? = nil
    var size: CGFloat = 258
    var showFace: Bool = true
    var isInteractive: Bool = true
    
    @State private var animate = false
    @State private var squishX: CGFloat = 1.0
    @State private var squishY: CGFloat = 1.0
    @State private var orbitAngle: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    
    private var highlightColor: Color {
        guard let mood else { return Color(hex: "D6FFB9") }
        return Color(hex: mood.orbColors.light)
    }
    
    private var baseColor: Color {
        guard let mood else { return Color(hex: "9BF66F") }
        return Color(hex: mood.orbColors.mid)
    }
    
    private var deepColor: Color {
        guard let mood else { return Color(hex: "59D85A") }
        return Color(hex: mood.orbColors.deep)
    }
    
    private var faceColor: Color {
        if let mood {
            return Color(hex: mood.faceColorHex)
        }
        return Color(hex: "27603F")
    }
    
    private var effectiveExpression: VenusMascotExpression {
        if let expression { return expression }
        return VenusMascotExpression(from: mood)
    }

    var body: some View {
        ZStack {
            // Ambient glow / Aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [baseColor.opacity(state == .listening ? 0.45 : 0.32), baseColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * (state == .listening ? 0.62 : 0.5)
                    )
                )
                .blur(radius: 12)
                .scaleEffect(animate ? (state == .listening ? 1.15 : 1.08) : 0.94)
            
            // Orbiting thought sparkles when thinking
            if state == .thinking {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [highlightColor.opacity(0.6), highlightColor.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: size * 0.92, height: size * 0.92)
                        .rotationEffect(.degrees(orbitAngle))
                    
                    Image(systemName: "sparkle")
                        .font(.system(size: max(8, size * 0.08), weight: .bold))
                        .foregroundColor(highlightColor)
                        .offset(x: size * 0.46)
                        .rotationEffect(.degrees(orbitAngle))
                    
                    Image(systemName: "sparkle")
                        .font(.system(size: max(6, size * 0.06), weight: .medium))
                        .foregroundColor(highlightColor.opacity(0.8))
                        .offset(x: -size * 0.46)
                        .rotationEffect(.degrees(orbitAngle))
                }
            }
            
            // Main Orb Body
            Circle()
                .fill(
                    LinearGradient(
                        colors: [highlightColor, baseColor, deepColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.76, height: size * 0.76)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.50), .white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.0, size * 0.012)
                        )
                )
                .overlay(
                    // Inner specular lighting
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.28), Color.clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: size * 0.38
                            )
                        )
                        .frame(width: size * 0.76, height: size * 0.76)
                )
                .shadow(color: baseColor.opacity(0.35), radius: max(6, size * 0.07), x: 0, y: max(3, size * 0.03))
                .scaleEffect(x: squishX, y: squishY)
                .scaleEffect(animate ? (state == .sleeping ? 1.01 : 1.03) : 0.97)
                .overlay(
                    Group {
                        if showFace {
                            VenusMascotFaceView(
                                expression: effectiveExpression,
                                state: state,
                                faceColor: faceColor,
                                size: size * 0.76
                            )
                            .scaleEffect(x: squishX, y: squishY)
                        }
                    }
                )
        }
        .contentShape(Circle())
        .onTapGesture {
            guard isInteractive else { return }
            triggerSquishBounce()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: state == .sleeping ? 3.5 : 2.5).repeatForever(autoreverses: true)) {
                animate = true
            }
            if state == .thinking {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    orbitAngle = 360
                }
            }
        }
        .onChange(of: state) { _, newState in
            if newState == .thinking {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    orbitAngle = 360
                }
            }
        }
    }
    
    private func triggerSquishBounce() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Quick squash
        withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) {
            squishX = 1.14
            squishY = 0.86
        }
        
        // Elastic rebound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.52)) {
                squishX = 1.0
                squishY = 1.0
            }
        }
    }
}
