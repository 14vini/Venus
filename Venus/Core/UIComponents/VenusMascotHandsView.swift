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
}

struct VenusMascotHandsView: View {
    let pose: VenusHandPose
    let tint: Color
    let highlightTint: Color
    let size: CGFloat
    
    @State private var waveAngle: Double = -14
    @State private var idleFloat = false
    
    private var scale: CGFloat { size / 100.0 }
    
    // Body radius is 0.38 * size. Flank paws sit at ±0.37 * size to peek out from the edges
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
            }
        }
        .onChange(of: pose) { _, newPose in
            if newPose == .waving {
                withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
                    waveAngle = 24
                }
            }
        }
    }
    
    // MARK: - Paw Component
    
    private func singlePaw(isRight: Bool) -> some View {
        ZStack {
            // Paw body
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            highlightTint.opacity(0.95),
                            tint.opacity(0.95),
                            tint.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 14 * scale, height: 14 * scale)
                .overlay(
                    // Soft top highlight
                    Circle()
                        .stroke(Color.white.opacity(0.55), lineWidth: 1.2 * scale)
                )
                .overlay(
                    // Glossy specular dot
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 4 * scale, height: 4 * scale)
                        .offset(x: isRight ? 1.5 * scale : -1.5 * scale, y: -2.5 * scale)
                )
                .shadow(color: tint.opacity(0.4), radius: 3 * scale, x: 0, y: 2 * scale)
        }
    }
}
