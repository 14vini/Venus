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
    
    var systemIcon: String {
        switch self {
        case .heart: return "heart.fill"
        case .star: return "sparkle"
        case .stardustPuff: return "circle.fill"
        case .zzz: return "z.circle"
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
    static func makePettingHearts(count: Int = 4, origin: CGSize = .zero) -> [MascotParticleItem] {
        (0..<count).map { _ in
            let angle = Double.random(in: (-110.0)...(-70.0)) * .pi / 180.0
            let dist = CGFloat.random(in: 40...85)
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
                scale: CGFloat.random(in: 0.8...1.4),
                opacity: Double.random(in: 0.8...1.0),
                rotation: Double.random(in: -25...25),
                duration: Double.random(in: 0.75...1.1)
            )
        }
    }
    
    static func makeLandingPuff(count: Int = 6, baseline: CGFloat) -> [MascotParticleItem] {
        (0..<count).map { i in
            let isLeft = i % 2 == 0
            let spread = CGFloat.random(in: 28...65) * (isLeft ? -1 : 1)
            let colors: [Color] = [Color.white.opacity(0.8), Color(hex: "D6FFB9").opacity(0.7), Color(hex: "FFE44A").opacity(0.8)]
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
    
    static func makeSparkleBurst(count: Int = 8) -> [MascotParticleItem] {
        (0..<count).map { i in
            let angle = Double(i) * (360.0 / Double(count)) * .pi / 180.0
            let dist = CGFloat.random(in: 45...80)
            let colors: [Color] = [
                Color(hex: "FFE44A"), Color(hex: "FFFAB9"), Color(hex: "9BF66F"), Color(hex: "B9EEFF"), Color(hex: "FF8E53")
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
}
