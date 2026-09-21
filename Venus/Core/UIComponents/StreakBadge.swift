//
//  StreakBadge.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI

struct StreakBadge: View {
    let days: Int
    let celebrated: Bool

    @State private var animateFlame = false
    @State private var burstScale: CGFloat = 1
    @State private var showConfetti = false

    private var milestone: Int? {
        [3, 7, 14, 30].first { $0 == days }
    }

    private var milestoneLabel: String? {
        guard let m = milestone else { return nil }
        switch m {
        case 3:  return "⚡️ 3 dias!"
        case 7:  return "🔥 1 semana!"
        case 14: return "⭐️ 2 semanas!"
        case 30: return "🏆 1 mês!"
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            // Confetti burst on milestone
            if showConfetti {
                ConfettiBurst()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: celebrated ? "flame.fill" : "flame")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(VenusTheme.accentOrange)
                        .scaleEffect(animateFlame ? 1.2 : 1.0)
                        .rotationEffect(.degrees(animateFlame ? 10 : -10))

                    Text("\(days)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .scaleEffect(burstScale)
                }

                if let label = milestoneLabel, celebrated {
                    Text(label)
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.accentOrange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear { triggerIfNeeded() }
        .onChange(of: celebrated) { _, _ in triggerIfNeeded() }
        .onChange(of: days) { _, _ in triggerIfNeeded() }
    }

    private func triggerIfNeeded() {
        guard celebrated else {
            animateFlame = false
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { burstScale = 1.35 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { burstScale = 1.0 }
        }

        withAnimation(.easeInOut(duration: 0.25).repeatCount(4, autoreverses: true)) {
            animateFlame = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.default) { animateFlame = false }
        }

        if milestone != nil {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showConfetti = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showConfetti = false }
            }
        }
    }
}

private struct ConfettiBurst: View {
    private struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let rotation: Double
    }

    private let particles: [Particle] = (0..<18).map { i in
        let colors: [Color] = [
            VenusTheme.accentOrange, VenusTheme.accentPink,
            VenusTheme.accentBlue, VenusTheme.accentGreen,
            VenusTheme.accentPurple, Color(hex: "FFD580")
        ]
        return Particle(
            color: colors[i % colors.count],
            angle: Double(i) * (360.0 / 18),
            distance: CGFloat.random(in: 28...56),
            size: CGFloat.random(in: 5...9),
            rotation: Double.random(in: 0...360)
        )
    }

    @State private var exploded = false

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 1.6)
                    .rotationEffect(.degrees(p.rotation))
                    .offset(
                        x: exploded ? cos(p.angle * .pi / 180) * p.distance : 0,
                        y: exploded ? sin(p.angle * .pi / 180) * p.distance - 10 : 0
                    )
                    .opacity(exploded ? 0 : 1)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6).delay(Double.random(in: 0...0.1)),
                        value: exploded
                    )
            }
        }
        .onAppear {
            exploded = true
        }
    }
}
