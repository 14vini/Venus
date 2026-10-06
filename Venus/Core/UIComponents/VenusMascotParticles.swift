//
//  VenusMascotParticles.swift
//  Venus
//
//  Created by Kaua on 21/09/26.
//

import SwiftUI

// MARK: - Particle Types

enum MascotParticleType: Equatable {
    case heart
    case star
    case stardustPuff
    case zzz
    case musicNote
    case soundWave
    case confetti
    case sparkle
    
    var systemIcon: String {
        switch self {
        case .heart: return "heart.fill"
        case .star: return "sparkle"
        case .stardustPuff: return "circle.fill"
        case .zzz: return "z.circle"
        case .musicNote: return "music.note"
        case .soundWave: return "waveform"
        case .confetti: return "star.fill"
        case .sparkle: return "sparkles"
        }
    }
}

// MARK: - Particle Model

struct MascotParticleItem: Identifiable {
    let id = UUID()
    let type: MascotParticleType
    let color: Color
    var startOffset: CGSize
    var endOffset: CGSize
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
    var duration: Double
    
    var systemIcon: String {
        type.systemIcon
    }
}

// MARK: - Particle Emitter View

struct MascotParticleEmitterView: View {
    let particles: [MascotParticleItem]
    
    var body: some View {
        ZStack {
            ForEach(particles) { p in
                SingleParticleView(particle: p)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SingleParticleView: View {
    let particle: MascotParticleItem
    
    @State private var isEmitted = false
    
    var body: some View {
        Group {
            if particle.type == .zzz {
                Text("z")
                    .font(.system(size: 14 * particle.scale, weight: .bold, design: .rounded))
                    .foregroundColor(particle.color)
            } else {
                Image(systemName: particle.type.systemIcon)
                    .font(.system(size: 12 * particle.scale, weight: .bold))
                    .foregroundColor(particle.color)
            }
        }
        .scaleEffect(isEmitted ? particle.scale : 0.2)
        .opacity(isEmitted ? 0 : particle.opacity)
        .rotationEffect(.degrees(isEmitted ? particle.rotation + 45 : particle.rotation))
        .offset(
            x: isEmitted ? particle.endOffset.width : particle.startOffset.width,
            y: isEmitted ? particle.endOffset.height : particle.startOffset.height
        )
        .onAppear {
            withAnimation(.easeOut(duration: particle.duration)) {
                isEmitted = true
            }
        }
    }
}

// MARK: - Particle Factory Generator

enum MascotParticleFactory {
    static func makePettingHearts(count: Int = 5, origin: CGSize = .zero) -> [MascotParticleItem] {
        (0..<count).map { _ in
            let angle = Double.random(in: (-120.0)...(-60.0)) * .pi / 180.0
            let dist = CGFloat.random(in: 40...95)
            let colorList: [Color] = [
                Color(hex: "FF6B8B"), Color(hex: "FF8E53"), Color(hex: "FFA8E8"), Color(hex: "FF477E")
            ]
            return MascotParticleItem(
                type: .heart,
                color: colorList.randomElement() ?? Color(hex: "FF6B8B"),
                startOffset: CGSize(
                    width: origin.width + CGFloat.random(in: -16...16),
                    height: origin.height + CGFloat.random(in: -12...0)
                ),
                endOffset: CGSize(
                    width: origin.width + cos(angle) * dist + CGFloat.random(in: -20...20),
                    height: origin.height + sin(angle) * dist
                ),
                scale: CGFloat.random(in: 0.85...1.45),
                opacity: Double.random(in: 0.85...1.0),
                rotation: Double.random(in: -25...25),
                duration: Double.random(in: 0.75...1.15)
            )
        }
    }
    
    static func makeLandingPuff(count: Int = 6, baseline: CGFloat) -> [MascotParticleItem] {
        (0..<count).map { i in
            let isLeft = i % 2 == 0
            let spread = CGFloat.random(in: 28...65) * (isLeft ? -1 : 1)
            let colors: [Color] = [Color.white.opacity(0.85), Color(hex: "D6FFB9").opacity(0.75), Color(hex: "FFE44A").opacity(0.85)]
            return MascotParticleItem(
                type: .star,
                color: colors.randomElement() ?? .white,
                startOffset: CGSize(width: CGFloat.random(in: -10...10), height: baseline),
                endOffset: CGSize(width: spread, height: baseline - CGFloat.random(in: 8...24)),
                scale: CGFloat.random(in: 0.6...1.1),
                opacity: 0.9,
                rotation: Double.random(in: 0...360),
                duration: Double.random(in: 0.45...0.65)
            )
        }
    }
    
    static func makeSparkleBurst(count: Int = 8, tint: Color? = nil) -> [MascotParticleItem] {
        (0..<count).map { i in
            let angle = Double(i) * (360.0 / Double(count)) * .pi / 180.0
            let dist = CGFloat.random(in: 45...85)
            let colors: [Color] = [
                tint ?? Color(hex: "FFE44A"),
                Color(hex: "FFFAB9"),
                tint ?? Color(hex: "9BF66F"),
                Color(hex: "B9EEFF"),
                Color(hex: "FF8E53")
            ]
            return MascotParticleItem(
                type: .star,
                color: colors[i % colors.count],
                startOffset: .zero,
                endOffset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                scale: CGFloat.random(in: 0.9...1.5),
                opacity: 1.0,
                rotation: Double.random(in: 0...180),
                duration: Double.random(in: 0.55...0.85)
            )
        }
    }
    
    static func makeVoiceListeningWaves(count: Int = 4, tint: Color = Color(hex: "9BF66F")) -> [MascotParticleItem] {
        (0..<count).map { i in
            let angle = (Double(i) * 90.0 + Double.random(in: -15...15)) * .pi / 180.0
            let dist = CGFloat.random(in: 35...65)
            return MascotParticleItem(
                type: .sparkle,
                color: tint.opacity(0.85),
                startOffset: .zero,
                endOffset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                scale: CGFloat.random(in: 0.7...1.2),
                opacity: 0.95,
                rotation: Double.random(in: -20...20),
                duration: Double.random(in: 0.6...0.9)
            )
        }
    }
    
    static func makeCheeringConfetti(count: Int = 12) -> [MascotParticleItem] {
        (0..<count).map { i in
            let angle = Double.random(in: (-160.0)...(-20.0)) * .pi / 180.0
            let dist = CGFloat.random(in: 55...110)
            let colors: [Color] = [
                Color(hex: "FFE44A"), Color(hex: "FF6B8B"), Color(hex: "59D85A"),
                Color(hex: "64D2FF"), Color(hex: "BF5AF2"), Color(hex: "FF9F0A")
            ]
            return MascotParticleItem(
                type: .confetti,
                color: colors[i % colors.count],
                startOffset: CGSize(width: CGFloat.random(in: -15...15), height: 10),
                endOffset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                scale: CGFloat.random(in: 0.8...1.5),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                duration: Double.random(in: 0.8...1.3)
            )
        }
    }
}
