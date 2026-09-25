//
//  ConstellationCanvas.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import SwiftUI
import UIKit

struct ConstellationCanvas: View {
    let stars: [GalaxyStar]
    @Binding var selectedStar: GalaxyStar?
    var isAnimated: Bool = true
    var showDetailsSheet: Bool = true
    
    @State private var lineProgress: CGFloat = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var backgroundTwinkle: Bool = false
    
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack {
                // 1. Cosmic Deep Space Background
                CosmicStarField(twinkle: backgroundTwinkle)
                
                // 2. Glowing Constellation Connecting Lines
                if stars.count > 1 {
                    ConstellationLinesShape(stars: stars, canvasSize: size)
                        .trim(from: 0, to: lineProgress)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    VenusTheme.primary.opacity(0.8),
                                    VenusTheme.accentBlue.opacity(0.6),
                                    VenusTheme.accentPurple.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4])
                        )
                        .shadow(color: VenusTheme.primary.opacity(0.6), radius: 6, x: 0, y: 0)
                }
                
                // 3. Constellation Star Nodes
                ForEach(stars) { star in
                    let starPos = CGPoint(
                        x: star.position.x * size.width,
                        y: star.position.y * size.height
                    )
                    let isSelected = selectedStar?.id == star.id
                    
                    Button {
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            if selectedStar?.id == star.id {
                                selectedStar = nil
                            } else {
                                selectedStar = star
                            }
                        }
                    } label: {
                        ZStack {
                            // Pulsing Outer Aura
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: star.glowColors,
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: star.size * (isSelected ? 2.4 : 1.6)
                                    )
                                )
                                .frame(width: star.size * (isSelected ? 4.5 : 3.0), height: star.size * (isSelected ? 4.5 : 3.0))
                                .scaleEffect(isSelected ? pulseScale : 1.0)
                            
                            // Core Crystal Star Orb
                            Circle()
                                .fill(star.starColor)
                                .frame(width: star.size * (isSelected ? 1.4 : 1.0), height: star.size * (isSelected ? 1.4 : 1.0))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.8), lineWidth: isSelected ? 2 : 1)
                                )
                                .shadow(color: star.starColor, radius: isSelected ? 12 : 6)
                            
                            // Center Glow White Spark
                            Circle()
                                .fill(Color.white)
                                .frame(width: star.size * 0.35, height: star.size * 0.35)
                        }
                    }
                    .buttonStyle(.plain)
                    .position(starPos)
                }
                
                // 4. Floating Star Detail Badge (When selected)
                if showDetailsSheet, let current = selectedStar {
                    let starPos = CGPoint(
                        x: current.position.x * size.width,
                        y: current.position.y * size.height
                    )
                    
                    StarDetailOverlay(star: current)
                        .position(x: min(max(starPos.x, 140), size.width - 140), y: max(starPos.y - 75, 70))
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
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
                        .foregroundColor(.white)
                    
                    Text(formattedDate)
                        .font(.system(size: 10, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer(minLength: 4)
                
                Text("\(star.intensity)/10")
                    .font(.system(.caption, design: .rounded).weight(.black))
                    .foregroundColor(star.starColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(star.starColor.opacity(0.18), in: Capsule())
            }
            
            if let note = star.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\"\(note)\"")
                    .font(.system(size: 11, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            
            if !star.triggers.isEmpty {
                HStack(spacing: 4) {
                    ForEach(star.triggers.prefix(2), id: \.self) { trigger in
                        Text(trigger)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(width: 250)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(star.starColor.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Cosmic Starfield Background

private struct CosmicStarField: View {
    let twinkle: Bool
    
    // Seeded background stars for cosmos aesthetics
    private let backgroundStars: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = [
        (0.08, 0.15, 2.5, 0.6), (0.22, 0.08, 1.5, 0.4), (0.85, 0.12, 2.0, 0.7),
        (0.92, 0.35, 1.2, 0.3), (0.14, 0.82, 2.8, 0.8), (0.78, 0.88, 1.8, 0.5),
        (0.45, 0.05, 3.0, 0.9), (0.65, 0.25, 1.0, 0.3), (0.32, 0.92, 2.0, 0.6),
        (0.88, 0.65, 1.5, 0.5), (0.05, 0.55, 2.2, 0.7), (0.50, 0.78, 1.2, 0.4)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep Dark Celestial Gradient
                RadialGradient(
                    colors: [
                        Color(hex: "18152E"),
                        Color(hex: "0D0A1A"),
                        Color(hex: "05040A")
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: geo.size.width * 0.8
                )
                
                // Nebula cloud patches
                Circle()
                    .fill(VenusTheme.primary.opacity(0.15))
                    .frame(width: geo.size.width * 0.7)
                    .blur(radius: 50)
                    .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.2)
                
                Circle()
                    .fill(VenusTheme.accentBlue.opacity(0.12))
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 45)
                    .offset(x: geo.size.width * 0.25, y: geo.size.height * 0.2)
                
                // Background Dust Stars
                ForEach(0..<backgroundStars.count, id: \.self) { i in
                    let s = backgroundStars[i]
                    Circle()
                        .fill(Color.white.opacity(twinkle ? s.opacity : s.opacity * 0.5))
                        .frame(width: s.size, height: s.size)
                        .position(x: s.x * geo.size.width, y: s.y * geo.size.height)
                }
            }
        }
    }
}
