//
//  AICalibrationLoadingStep.swift
//  Venus
//
//  Created by Kaua on 20/09/26.
//

import SwiftUI
import UIKit

struct AICalibrationLoadingStep: View {
    let userName: String
    let tone: String
    let onComplete: () -> Void
    
    @State private var progress: Double = 0.0
    @State private var currentPhaseIndex: Int = 0
    @State private var orbScale: CGFloat = 1.0
    
    private let impactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    private var phases: [String] {
        let name = userName.isEmpty ? "você" : userName
        let toneDesc = tone.isEmpty ? "acolhedor" : tone.lowercased()
        
        return [
            "Sintonizando seu padrão de energia...",
            "Ajustando o tom \(toneDesc) para \(name)...",
            "Criando seu refúgio seguro e protegido...",
            "Tudo pronto! Revelando seu perfil..."
        ]
    }
    
    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            // Central Venus Orb with Ultra-Fluid Ethereal Aurora & Waves Behind It
            ZStack {
                // 1. Ethereal Aurora Wave Halo (Behind Orb)
                EtherealAuroraWaves()
                
                // 2. Soft Ambient Light Core
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                VenusTheme.primary.opacity(0.40),
                                VenusTheme.accentBlue.opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(orbScale)
                    .blur(radius: 20)
                
                // 3. Crisp Venus Mood Orb (Foreground)
                VenusMoodOrb(mood: .calm, size: 140)
                    .scaleEffect(orbScale * 0.96)
                    .shadow(color: VenusTheme.primary.opacity(0.35), radius: 24, x: 0, y: 0)
                    .zIndex(10)
            }
            .frame(width: 340, height: 340)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: orbScale)
            
            // Dynamic Status Text
            VStack(spacing: 12) {
                Text("Calibrando a Venus")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                
                Text(phases[min(currentPhaseIndex, phases.count - 1)])
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(height: 44)
                    .padding(.horizontal, 32)
                    .id(currentPhaseIndex)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Single Color Progress Bar with Glow
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 7)
                        
                        Capsule()
                            .fill(VenusTheme.primary)
                            .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 7)
                            .shadow(color: VenusTheme.primary.opacity(0.55), radius: 6, x: 0, y: 0)
                            .animation(.easeInOut(duration: 0.12), value: progress)
                    }
                }
                .frame(height: 7)
                .padding(.horizontal, 48)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(.caption, design: .rounded).weight(.black))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 24)
        .onAppear {
            impactGenerator.prepare()
            heavyImpactGenerator.prepare()
            startCalibrationSequence()
        }
    }
    
    private func startCalibrationSequence() {
        orbScale = 1.12
        
        let totalDuration = 3.6
        let stepsCount = 40
        let interval = totalDuration / Double(stepsCount)
        
        for i in 1...stepsCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * interval)) {
                progress = Double(i) / Double(stepsCount)
                
                // Continuous tactile vibration growing with the progress bar
                if i % 2 == 0 {
                    let intensity = CGFloat(0.35 + (0.65 * progress))
                    impactGenerator.impactOccurred(intensity: intensity)
                }
                
                // Phase shifts with stronger feedback
                if progress >= 0.22 && currentPhaseIndex == 0 {
                    currentPhaseIndex = 1
                    heavyImpactGenerator.impactOccurred(intensity: 0.8)
                } else if progress >= 0.55 && currentPhaseIndex == 1 {
                    currentPhaseIndex = 2
                    heavyImpactGenerator.impactOccurred(intensity: 0.9)
                } else if progress >= 0.85 && currentPhaseIndex == 2 {
                    currentPhaseIndex = 3
                    heavyImpactGenerator.impactOccurred(intensity: 1.0)
                }
            }
        }
        
        // Completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                onComplete()
            }
        }
    }
}

// MARK: - Ethereal Fluid Aurora Waves
private struct EtherealAuroraWaves: View {
    @State private var rotation: Double = 0
    @State private var wave1 = false
    @State private var wave2 = false
    @State private var wave3 = false
    @State private var wave4 = false
    
    var body: some View {
        ZStack {
            // 1. Organic Rotating Aurora Gradient Disc
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            VenusTheme.primary.opacity(0.42),
                            VenusTheme.accentBlue.opacity(0.35),
                            VenusTheme.accentPurple.opacity(0.30),
                            VenusTheme.accentGreen.opacity(0.38),
                            VenusTheme.primary.opacity(0.42)
                        ],
                        center: .center
                    )
                )
                .frame(width: 250, height: 250)
                .blur(radius: 36)
                .rotationEffect(.degrees(rotation))
            
            // 2. Diffuse Expanding Wave Halos
            softWaveHalo(isAnimating: wave1, color: VenusTheme.primary)
            softWaveHalo(isAnimating: wave2, color: VenusTheme.accentBlue)
            softWaveHalo(isAnimating: wave3, color: VenusTheme.accentPurple)
            softWaveHalo(isAnimating: wave4, color: VenusTheme.primary)
        }
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            let duration: Double = 1.6
            let stepDelay = duration / 4.0
            
            withAnimation(.easeOut(duration: duration).repeatForever(autoreverses: false)) {
                wave1 = true
            }
            withAnimation(.easeOut(duration: duration).repeatForever(autoreverses: false).delay(stepDelay * 1)) {
                wave2 = true
            }
            withAnimation(.easeOut(duration: duration).repeatForever(autoreverses: false).delay(stepDelay * 2)) {
                wave3 = true
            }
            withAnimation(.easeOut(duration: duration).repeatForever(autoreverses: false).delay(stepDelay * 3)) {
                wave4 = true
            }
        }
    }
    
    private func softWaveHalo(isAnimating: Bool, color: Color) -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        color.opacity(isAnimating ? 0.0 : 0.55),
                        color.opacity(isAnimating ? 0.0 : 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isAnimating ? 18 : 6
            )
            .background(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(isAnimating ? 0.0 : 0.22),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
            )
            .frame(width: 150, height: 150)
            .scaleEffect(isAnimating ? 2.9 : 0.4)
            .blur(radius: isAnimating ? 14 : 4)
            .opacity(isAnimating ? 0.0 : 0.9)
    }
}

#Preview {
    AICalibrationLoadingStep(userName: "Kaua", tone: "Gentil", onComplete: {})
        .background(VenusTheme.backgroundGradient)
}
