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
    case thoughtBubble   // balão de pensamento gráfico, sem texto

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
        case .thoughtBubble: return "bubble"
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
            } else if particle.type == .thoughtBubble {
                // Balão de pensamento desenhado por símbolos — nenhuma palavra.
                ZStack(alignment: .bottomLeading) {
                    Image(systemName: "bubble")
                        .font(.system(size: 15 * particle.scale, weight: .medium))
                    Circle()
                        .fill(particle.color)
                        .frame(width: max(1, 2.2 * particle.scale), height: max(1, 2.2 * particle.scale))
                        .offset(x: 1.5 * particle.scale, y: -1 * particle.scale)
                    Circle()
                        .fill(particle.color)
                        .frame(width: max(0.8, 1.4 * particle.scale), height: max(0.8, 1.4 * particle.scale))
                        .offset(x: -1 * particle.scale, y: 1 * particle.scale)
                }
                .foregroundColor(particle.color)
            } else {
                Image(systemName: particle.type.systemIcon)
                    .font(.system(size: 12 * particle.scale, weight: .bold))
                    .foregroundColor(particle.color)
            }
        }
        // Soft self-glow keeps confetti and listening sparks readable even on
        // the 30pt header orb, without adding any animation loop.
        .shadow(color: particle.color.opacity(0.65), radius: 3 * particle.scale)
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

    // MARK: - Novos fabricantes de reação

    /// Corações que sobem do peito — gratidão e carinho.
    static func makeHeartBurst(count: Int = 6, tint: Color? = nil) -> [MascotParticleItem] {
        let colors: [Color] = [
            Color(hex: "FF6B8B"), Color(hex: "FF477E"),
            Color(hex: "FFA8E8"), tint ?? Color(hex: "FF8E53")
        ]
        return (0..<count).map { i in
            let drift = CGFloat.random(in: -34...34)
            return MascotParticleItem(
                type: .heart,
                color: colors[i % colors.count],
                startOffset: CGSize(width: drift * 0.25, height: CGFloat.random(in: 6...18)),
                endOffset: CGSize(width: drift, height: -CGFloat.random(in: 52...92)),
                scale: CGFloat.random(in: 0.7...1.2),
                opacity: 0.95,
                rotation: Double.random(in: -18...18),
                duration: Double.random(in: 0.9...1.25)
            )
        }
    }

    /// Chuva de estrelas suave para orgulho e descoberta.
    static func makeStarShower(count: Int = 8, tint: Color? = nil) -> [MascotParticleItem] {
        let colors: [Color] = [
            tint ?? Color(hex: "FFE44A"), Color(hex: "FFFAB9"),
            Color(hex: "B9EEFF"), Color(hex: "FFA8E8")
        ]
        return (0..<count).map { i in
            let spread = CGFloat.random(in: -70...70)
            return MascotParticleItem(
                type: .star,
                color: colors[i % colors.count],
                startOffset: CGSize(width: spread * 0.4, height: -CGFloat.random(in: 40...75)),
                endOffset: CGSize(width: spread, height: CGFloat.random(in: 12...45)),
                scale: CGFloat.random(in: 0.6...1.15),
                opacity: 0.95,
                rotation: Double.random(in: 0...180),
                duration: Double.random(in: 0.85...1.2)
            )
        }
    }

    /// Faíscas delicadas — diversão contida e piscadela.
    static func makeSoftSparkles(count: Int = 6, tint: Color? = nil) -> [MascotParticleItem] {
        let colors: [Color] = [
            tint ?? Color(hex: "FFE44A"), Color.white, Color(hex: "B9EEFF")
        ]
        return (0..<count).map { i in
            let angle = Double.random(in: 0...360) * .pi / 180.0
            let dist = CGFloat.random(in: 22...52)
            return MascotParticleItem(
                type: .sparkle,
                color: colors[i % colors.count],
                startOffset: .zero,
                endOffset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                scale: CGFloat.random(in: 0.5...0.9),
                opacity: 0.9,
                rotation: Double.random(in: -25...25),
                duration: Double.random(in: 0.6...0.95)
            )
        }
    }

    /// Bolhas de pensamento sem qualquer texto (somente símbolos gráficos).
    static func makeThoughtBubbles(count: Int = 3, tint: Color? = nil) -> [MascotParticleItem] {
        let color = tint ?? Color(hex: "B9EEFF")
        return (0..<count).map { i in
            let rise = CGFloat(26 + i * 16)
            return MascotParticleItem(
                type: .thoughtBubble,
                color: color.opacity(0.9),
                startOffset: CGSize(width: 12 * CGFloat(i), height: 10),
                endOffset: CGSize(width: 26 + 14 * CGFloat(i), height: -rise),
                scale: CGFloat.random(in: 0.7...1.0),
                opacity: 0.85,
                rotation: Double.random(in: -8...8),
                duration: Double.random(in: 1.0...1.4)
            )
        }
    }
}
