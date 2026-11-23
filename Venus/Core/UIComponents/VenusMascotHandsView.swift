//
//  VenusMascotHandsView.swift
//  Venus
//
//  Created by Kaua on 21/09/26.
//

import SwiftUI

enum VenusHandPose: Equatable, Sendable {
    case floatingIdle
    case waving
    case thinking
    case coveringCheeks
    case tucked
    case clapping
    case curiousPeek
    case supportive

    // MARK: Novas reações (aditivas)
    case heartHands   // mãos reunidas junto ao peito — carinho/gratidão
    case cheer        // mãos erguidas — celebração suave
}

struct VenusMascotHandsView: View {
    let pose: VenusHandPose
    let tint: Color
    let highlightTint: Color
    let size: CGFloat
    
    @State private var waveAngle: Double = -14
    @State private var clapOffset: CGFloat = 0
    @State private var idleFloat = false
    
    private var scale: CGFloat { size / 100.0 }
    
    // Hands float just beyond the ghost form, rather than reading as a separate outlined object.
    private var flankX: CGFloat { size * 0.38 }

    var body: some View {
        ZStack {
            switch pose {
            case .floatingIdle:
                // Chubby cute paws peeking from left & right sides (NOT covering the face)
                HStack(spacing: 0) {
                    singlePaw(isRight: false)
                        .offset(x: -flankX + (idleFloat ? -1.5 * scale : 1.5 * scale), y: 14 * scale + (idleFloat ? -2 * scale : 2 * scale))
                    
                    Spacer(minLength: 0)
                    
                    singlePaw(isRight: true)
                        .offset(x: flankX + (idleFloat ? 1.5 * scale : -1.5 * scale), y: 14 * scale + (idleFloat ? 2 * scale : -2 * scale))
                }
                .frame(width: size * 0.96)
                
            case .waving:
                // Left paw rests on flank, right paw waves up high beside the head
                HStack(spacing: 0) {
                    singlePaw(isRight: false)
                        .offset(x: -flankX, y: 16 * scale)
                    
                    Spacer(minLength: 0)
                    
                    singlePaw(isRight: true)
                        .rotationEffect(.degrees(waveAngle), anchor: .bottomLeading)
                        .offset(x: flankX + 4 * scale, y: -16 * scale)
                }
                .frame(width: size * 0.96)
                
            case .thinking:
                // Left paw on flank, right paw resting gently on bottom edge of cheek
                HStack(spacing: 0) {
                    singlePaw(isRight: false)
                        .offset(x: -flankX, y: 16 * scale)
                    
                    Spacer(minLength: 0)
                    
                    singlePaw(isRight: true)
                        .rotationEffect(.degrees(-28))
                        .offset(x: size * 0.18, y: 16 * scale)
                }
                .frame(width: size * 0.96)
                
            case .coveringCheeks:
                // Paws placed cutely on lower flank edges of cheeks without covering eyes
                HStack(spacing: 0) {
                    singlePaw(isRight: false)
                        .rotationEffect(.degrees(22))
                        .offset(x: -size * 0.26, y: 14 * scale)
                    
                    Spacer(minLength: 0)
                    
                    singlePaw(isRight: true)
                        .rotationEffect(.degrees(-22))
                        .offset(x: size * 0.26, y: 14 * scale)
                }
                .frame(width: size * 0.88)
                
            case .tucked:
                // Little paws tucked together at the bottom center
                HStack(spacing: 6 * scale) {
                    singlePaw(isRight: false)
                        .rotationEffect(.degrees(12))
                    singlePaw(isRight: true)
                        .rotationEffect(.degrees(-12))
                }
                .offset(y: size * 0.32)
                
            case .clapping:
                // Quick playful clapping animation
                HStack(spacing: max(2, 8 * scale + clapOffset)) {
                    singlePaw(isRight: false)
                        .rotationEffect(.degrees(18))
                    singlePaw(isRight: true)
                        .rotationEffect(.degrees(-18))
                }
                .offset(y: size * 0.28)
                
            case .curiousPeek:
                // Resting paws at bottom edge peeking upwards
                HStack(spacing: size * 0.38) {
                    singlePaw(isRight: false)
                        .rotationEffect(.degrees(8))
                    singlePaw(isRight: true)
                        .rotationEffect(.degrees(-8))
                }
                .offset(y: size * 0.30)
                
            case .supportive:
                // Gentle open paws extended forward
                HStack(spacing: size * 0.44) {
                    singlePaw(isRight: false)
                        .rotationEffect(.degrees(32))
                    singlePaw(isRight: true)
                        .rotationEffect(.degrees(-32))
                }
                .offset(y: size * 0.22)

            case .heartHands:
                // Paws meet over the chest, holding a small wordless heart.
                ZStack {
                    HStack(spacing: 4 * scale) {
                        singlePaw(isRight: false)
                            .rotationEffect(.degrees(28))
                        singlePaw(isRight: true)
                            .rotationEffect(.degrees(-28))
                    }

                    Image(systemName: "heart.fill")
                        .font(.system(size: max(5, 7 * scale), weight: .bold))
                        .foregroundColor(Color(hex: "FF6B8B").opacity(0.85))
                        .shadow(color: Color(hex: "FF6B8B").opacity(0.6), radius: 3 * scale)
                        .offset(y: -3 * scale)
                        .scaleEffect(idleFloat ? 1.08 : 0.96)
                }
                .offset(y: size * 0.26)

            case .cheer:
                // Both paws lifted beside the head — joyful, never frantic.
                HStack(spacing: size * 0.62) {
                    singlePaw(isRight: false)
                        .rotationEffect(.degrees(-38))
                        .offset(y: -26 * scale)
                    singlePaw(isRight: true)
                        .rotationEffect(.degrees(38))
                        .offset(y: -26 * scale)
                }
                .offset(y: -size * 0.02)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                idleFloat = true
            }
            if pose == .waving {
                withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
                    waveAngle = 24
                }
            } else if pose == .clapping {
                withAnimation(.easeInOut(duration: 0.16).repeatForever(autoreverses: true)) {
                    clapOffset = -6 * scale
                }
            }
        }
        .onChange(of: pose) { _, newPose in
            if newPose == .waving {
                withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
                    waveAngle = 24
                }
            } else if newPose == .clapping {
                withAnimation(.easeInOut(duration: 0.16).repeatForever(autoreverses: true)) {
                    clapOffset = -6 * scale
                }
            }
        }
        // Transição suave entre poses: as mãos não "saltam" de posição.
        .phaseAnimator([false, true], trigger: pose) { content, phase in
            content
                .opacity(phase ? 1.0 : 0.45)
                .scaleEffect(phase ? 1.0 : 0.92)
        } animation: { _ in
            .spring(response: 0.42, dampingFraction: 0.8)
        }
    }
    
    // MARK: - Paw Component
    
    private func singlePaw(isRight: Bool) -> some View {
        ZStack {
            // A soft bloom seats each paw inside Venus's own aura, so the
            // hands read as luminous extensions of the body — not as two
            // detached beads. Same tints, same positions, same size.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            highlightTint.opacity(0.28),
                            tint.opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12 * scale
                    )
                )
                .frame(width: 26 * scale, height: 26 * scale)
                .blur(radius: 2 * scale)
                .blendMode(.plusLighter)

            // Lit dome: pale at the top, mood tint at the shaded base. Reading
            // the paw as a small sphere gives the hands real volume.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            highlightTint.opacity(0.78),
                            tint.opacity(0.58),
                            tint.opacity(0.30)
                        ],
                        center: .init(x: isRight ? 0.36 : 0.32, y: 0.24),
                        startRadius: 0,
                        endRadius: 10 * scale
                    )
                )
                .frame(width: 14 * scale, height: 14 * scale)

            // Soft ambient occlusion in the lower-right keeps it rounded.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.34), Color.clear],
                        center: .init(x: 0.78, y: 0.82),
                        startRadius: 0,
                        endRadius: 8 * scale
                    )
                )
                .frame(width: 14 * scale, height: 14 * scale)

            // Tight specular pinprick, brighter than the old flat glint.
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 3.2 * scale, height: 3.2 * scale)
                .offset(x: -1.6 * scale, y: -2.6 * scale)
                .blur(radius: max(0.2, 0.3 * scale))

            // Faint reflected bounce along the lower rim.
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.clear, highlightTint.opacity(0.45), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: max(0.6, scale)
                )
                .frame(width: 13 * scale, height: 13 * scale)
        }
        .shadow(color: tint.opacity(0.34), radius: 4 * scale, x: 0, y: 2 * scale)
    }
}
