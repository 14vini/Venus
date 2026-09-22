//
//  VenusCosmetics.swift
//  Venus
//
//  Created by Kaua on 21/09/26.
//

import SwiftUI

// MARK: - Cosmetic Item Model

enum VenusCosmeticItem: String, CaseIterable, Sendable {
    case none
    case starHalo           // 3-day streak
    case astralWings        // 7-day streak
    case cosmicHeadphones   // 14-day streak
    case saturnRing         // 30-day streak
    case nightCap           // Night moment
    
    var title: String {
        switch self {
        case .none: return "Nenhum"
        case .starHalo: return "Auréola Estelar"
        case .astralWings: return "Asinhas Astrais"
        case .cosmicHeadphones: return "Fones Cósmicos"
        case .saturnRing: return "Anel de Saturno"
        case .nightCap: return "Gorro dos Sonhos"
        }
    }
    
    var requiredStreakDays: Int? {
        switch self {
        case .starHalo: return 3
        case .astralWings: return 7
        case .cosmicHeadphones: return 14
        case .saturnRing: return 30
        default: return nil
        }
    }
}

// MARK: - Cosmetic Accessory View

struct VenusCosmeticAccessoryView: View {
    let item: VenusCosmeticItem
    let size: CGFloat
    let mood: MoodType?
    
    @State private var animateHalo = false
    @State private var flapWings = false
    @State private var pulseHeadphones = false
    @State private var spinSaturnRing = false
    
    private var scale: CGFloat { size / 100.0 }

    var body: some View {
        ZStack {
            switch item {
            case .none:
                EmptyView()
                
            case .starHalo:
                // Floating golden/starlight halo above head
                ZStack {
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FFE44A"), Color(hex: "FFFAB9"), Color(hex: "F5C800")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3 * scale
                        )
                        .frame(width: 44 * scale, height: 16 * scale)
                        .shadow(color: Color(hex: "FFE44A").opacity(0.8), radius: 6 * scale)
                    
                    // Star jewel on halo
                    Image(systemName: "sparkle")
                        .font(.system(size: 8 * scale, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 18 * scale, y: -2 * scale)
                }
                .rotation3DEffect(.degrees(25), axis: (x: 1, y: 0, z: 0))
                .offset(y: -44 * scale + (animateHalo ? -3 * scale : 2 * scale))
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        animateHalo = true
                    }
                }
                
            case .astralWings:
                // Fluttering translucent cute wings behind/beside body
                HStack(spacing: 64 * scale) {
                    AstralWingShape(isRight: false)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.85), Color(hex: "B9EEFF").opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24 * scale, height: 32 * scale)
                        .rotationEffect(.degrees(flapWings ? -18 : 8), anchor: .bottomTrailing)
                    
                    AstralWingShape(isRight: true)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.85), Color(hex: "B9EEFF").opacity(0.6)],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .frame(width: 24 * scale, height: 32 * scale)
                        .rotationEffect(.degrees(flapWings ? 18 : -8), anchor: .bottomLeading)
                }
                .offset(y: -4 * scale)
                .shadow(color: Color(hex: "B9EEFF").opacity(0.4), radius: 6 * scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                        flapWings = true
                    }
                }
                
            case .cosmicHeadphones:
                // Glowing cute over-ear headphones
                ZStack {
                    // Headband
                    Circle()
                        .trim(from: 0.58, to: 0.92)
                        .stroke(
                            LinearGradient(
                                colors: [VenusTheme.accentPurple, VenusTheme.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4 * scale, lineCap: .round)
                        )
                        .frame(width: 78 * scale, height: 78 * scale)
                        .offset(y: -14 * scale)
                    
                    // Ear cups
                    HStack(spacing: 66 * scale) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [VenusTheme.accentPink, VenusTheme.accentPurple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 12 * scale, height: 26 * scale)
                            .overlay(
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 5 * scale, height: 5 * scale)
                            )
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [VenusTheme.accentPink, VenusTheme.accentPurple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 12 * scale, height: 26 * scale)
                            .overlay(
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 5 * scale, height: 5 * scale)
                            )
                    }
                    .offset(y: -2 * scale)
                    .scaleEffect(pulseHeadphones ? 1.06 : 0.96)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                        pulseHeadphones = true
                    }
                }
                
            case .saturnRing:
                // Tilted planetary dust ring
                ZStack {
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFB347").opacity(0.9),
                                    Color(hex: "8D5CFF").opacity(0.7),
                                    Color(hex: "FFE44A").opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 5 * scale
                        )
                        .frame(width: 110 * scale, height: 28 * scale)
                        .rotation3DEffect(.degrees(55), axis: (x: 1, y: -0.3, z: 0.2))
                        .shadow(color: Color(hex: "FFB347").opacity(0.5), radius: 8 * scale)
                    
                    // Orbiting micro satellite
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5 * scale, height: 5 * scale)
                        .offset(x: 48 * scale, y: 0)
                        .rotationEffect(.degrees(spinSaturnRing ? 360 : 0))
                }
                .offset(y: 4 * scale)
                .onAppear {
                    withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                        spinSaturnRing = true
                    }
                }
                
            case .nightCap:
                // Cozy sleepy night cap
                NightCapShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "5C8DFF"), Color(hex: "8D5CFF")],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 44 * scale, height: 38 * scale)
                    .overlay(
                        // Fluffy pompom at tip
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10 * scale, height: 10 * scale)
                            .offset(x: 22 * scale, y: 14 * scale)
                    )
                    .rotationEffect(.degrees(16))
                    .offset(x: 16 * scale, y: -38 * scale)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Wing & Cap Shapes

struct AstralWingShape: Shape {
    let isRight: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startX = isRight ? rect.minX : rect.maxX
        let tipX = isRight ? rect.maxX : rect.minX
        
        path.move(to: CGPoint(x: startX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: tipX, y: rect.minY),
            control: CGPoint(x: isRight ? rect.maxX : rect.minX, y: rect.midY - rect.height * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: startX, y: rect.maxY),
            control: CGPoint(x: startX, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

struct NightCapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}
