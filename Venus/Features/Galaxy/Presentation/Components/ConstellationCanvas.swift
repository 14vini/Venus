//
//  ConstellationCanvas.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//
//  F15 — mesma constelação, atmosfera suave e seleção com haptic + transição.
//

import SwiftUI
import UIKit

struct ConstellationCanvas: View {
    let stars: [GalaxyStar]
    @Binding var selectedStar: GalaxyStar?
    var isAnimated: Bool = true
    var showDetailsSheet: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    @State private var lineProgress: CGFloat = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var backgroundTwinkle: Bool = false

    private let impact = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                // Céu suave, sem preto profundo.
                CosmicStarField(twinkle: backgroundTwinkle)

                // Linhas que ligam os check-ins.
                if stars.count > 1 {
                    ConstellationLinesShape(stars: stars, canvasSize: size)
                        .trim(from: 0, to: lineProgress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    VenusTheme.primary.opacity(colorScheme == .dark ? 0.85 : 0.55),
                                    VenusTheme.accentPink.opacity(colorScheme == .dark ? 0.55 : 0.45),
                                    VenusTheme.accentPurple.opacity(colorScheme == .dark ? 0.80 : 0.50)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round, dash: [3, 5])
                        )
                }

                // Estrelas: toque com haptic e escala elástica.
                ForEach(stars) { star in
                    let starPos = CGPoint(
                        x: star.position.x * size.width,
                        y: star.position.y * size.height
                    )
                    let isSelected = selectedStar?.id == star.id

                    Button {
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            if selectedStar?.id == star.id {
                                selectedStar = nil
                            } else {
                                selectedStar = star
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: star.glowColors,
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: star.size * (isSelected ? 2.4 : 1.6)
                                    )
                                )
                                .frame(
                                    width: star.size * (isSelected ? 4.5 : 3.0),
                                    height: star.size * (isSelected ? 4.5 : 3.0)
                                )
                                .scaleEffect(isSelected ? pulseScale : 1.0)

                            Circle()
                                .fill(star.starColor)
                                .frame(
                                    width: star.size * (isSelected ? 1.4 : 1.0),
                                    height: star.size * (isSelected ? 1.4 : 1.0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            Color.white.opacity(colorScheme == .dark ? 0.8 : 0.55),
                                            lineWidth: isSelected ? 2 : 1
                                        )
                                )

                            Circle()
                                .fill(Color.white)
                                .frame(width: star.size * 0.35, height: star.size * 0.35)
                        }
                    }
                    .buttonStyle(.plain)
                    .position(starPos)
                    .accessibilityLabel("Estrela de \(star.moodType.rawValue), intensidade \(star.intensity) de 10")
                }

                // Detalhe do ponto selecionado em vidro real.
                if showDetailsSheet, let current = selectedStar {
                    let starPos = CGPoint(
                        x: current.position.x * size.width,
                        y: current.position.y * size.height
                    )

                    StarDetailOverlay(star: current)
                        .position(x: min(max(starPos.x, 140), size.width - 140), y: max(starPos.y - 75, 70))
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                        .zIndex(20)
                }
            }
            .onAppear {
                impact.prepare()
                if isAnimated {
                    withAnimation(.easeOut(duration: 1.6)) {
                        lineProgress = 1.0
                    }
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulseScale = 1.15
                    }
                    withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                        backgroundTwinkle = true
                    }
                } else {
                    lineProgress = 1.0
                }
            }
        }
    }
}

// MARK: - Constellation Path Lines

private struct ConstellationLinesShape: Shape {
    let stars: [GalaxyStar]
    let canvasSize: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard stars.count > 1 else { return path }

        let first = stars[0]
        path.move(to: CGPoint(x: first.position.x * canvasSize.width, y: first.position.y * canvasSize.height))

        for i in 1..<stars.count {
            let next = stars[i]
            let point = CGPoint(x: next.position.x * canvasSize.width, y: next.position.y * canvasSize.height)
            path.addLine(to: point)
        }

        return path
    }
}

// MARK: - Star Detail Overlay

private struct StarDetailOverlay: View {
    let star: GalaxyStar

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd 'de' MMMM"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: star.date).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(star.moodType.emoji)
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 1) {
                    Text(star.moodType.rawValue)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(VenusTheme.text)

                    Text(formattedDate)
                        .font(.system(size: 10, design: .rounded).weight(.regular))
                        .foregroundStyle(VenusTheme.textSecondary)
                }

                Spacer(minLength: 4)

                Text("\(star.intensity)/10")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(star.starColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(.regular, in: Capsule(style: .continuous))
            }

            if let note = star.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\"\(note)\"")
                    .font(.system(size: 11, design: .rounded).weight(.regular))
                    .foregroundStyle(VenusTheme.text)
                    .lineLimit(2)
                    .padding(.top, 2)
            }

            if !star.triggers.isEmpty {
                HStack(spacing: 4) {
                    ForEach(star.triggers.prefix(2), id: \.self) { trigger in
                        Text(trigger)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(VenusTheme.textSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .glassEffect(.regular, in: Capsule(style: .continuous))
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(width: 250)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Cosmic Starfield Background

private struct CosmicStarField: View {
    let twinkle: Bool

    @Environment(\.colorScheme) private var colorScheme

    // Seeded background stars for cosmos aesthetics
    private let backgroundStars: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = [
        (0.08, 0.15, 2.5, 0.6), (0.22, 0.08, 1.5, 0.4), (0.85, 0.12, 2.0, 0.7),
        (0.92, 0.35, 1.2, 0.3), (0.14, 0.82, 2.8, 0.8), (0.78, 0.88, 1.8, 0.5),
        (0.45, 0.05, 3.0, 0.9), (0.65, 0.25, 1.0, 0.3), (0.32, 0.92, 2.0, 0.6),
        (0.88, 0.65, 1.5, 0.5), (0.05, 0.55, 2.2, 0.7), (0.50, 0.78, 1.2, 0.4)
    ]

    private var dustColor: Color {
        colorScheme == .dark ? Color.white : VenusTheme.primaryDark
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadialGradient(
                    colors: colorScheme == .dark
                        ? [Color(hex: "2E2845"), Color(hex: "252037"), Color.clear]
                        : [Color(hex: "E6EAF9").opacity(0.55), Color(hex: "F4E5F1").opacity(0.45), Color.clear],
                    center: .center,
                    startRadius: 40,
                    endRadius: geo.size.width * 0.85
                )

                Circle()
                    .fill(VenusTheme.primary.opacity(colorScheme == .dark ? 0.12 : 0.10))
                    .frame(width: geo.size.width * 0.7)
                    .blur(radius: 45)
                    .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.18)

                Circle()
                    .fill(Color(hex: "E9A8D8").opacity(colorScheme == .dark ? 0.10 : 0.14))
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 40)
                    .offset(x: geo.size.width * 0.22, y: geo.size.height * 0.2)

                ForEach(0..<backgroundStars.count, id: \.self) { i in
                    let s = backgroundStars[i]
                    Circle()
                        .fill(dustColor.opacity(twinkle ? s.opacity : s.opacity * 0.5))
                        .frame(width: s.size, height: s.size)
                        .position(x: s.x * geo.size.width, y: s.y * geo.size.height)
                }
            }
        }
    }
}
