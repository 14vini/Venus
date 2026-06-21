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
    var size: CGFloat = 258
    
    @State private var animate = false
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

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [baseColor.opacity(0.32), baseColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .blur(radius: 12)
                .scaleEffect(animate ? 1.08 : 0.94)
            
            // Inner glowing core
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
                        .stroke(LinearGradient(
                            colors: [.white.opacity(0.45), .white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1.5)
                )
                .shadow(color: baseColor.opacity(0.3), radius: 18, x: 0, y: 8)
                .scaleEffect(animate ? 1.03 : 0.97)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

