//
//  BreathingAnimationView.swift
//  Venus
//
//  Created for breathing exercises animation
//

import SwiftUI

struct BreathingAnimationView: View {
    @State private var isExpanded = false
    @State private var breathingPhase: BreathingPhase = .inhale
    
    enum BreathingPhase {
        case inhale, hold, exhale
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Outer circle
                Circle()
                    .fill(VenusTheme.primary.opacity(0.1))
                    .frame(width: isExpanded ? 180 : 120, height: isExpanded ? 180 : 120)
                    .animation(.easeInOut(duration: 4), value: isExpanded)
                
                // Inner circle
                Circle()
                    .fill(VenusTheme.primaryGradient)
                    .frame(width: isExpanded ? 120 : 80, height: isExpanded ? 120 : 80)
                    .animation(.easeInOut(duration: 4), value: isExpanded)
                
                // Center text
                Text(breathingText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Text(instructionText)
                .font(.subheadline)
                .foregroundColor(VenusTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            startBreathingCycle()
        }
    }
    
    private var breathingText: String {
        switch breathingPhase {
        case .inhale: return "Inspire"
        case .hold: return "Segure"
        case .exhale: return "Expire"
        }
    }
    
    private var instructionText: String {
        switch breathingPhase {
        case .inhale: return "Inspire lentamente pelo nariz"
        case .hold: return "Segure a respiração"
        case .exhale: return "Expire lentamente pela boca"
        }
    }
    
    private func startBreathingCycle() {
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 4)) {
                switch breathingPhase {
                case .inhale:
                    isExpanded = true
                    breathingPhase = .hold
                case .hold:
                    breathingPhase = .exhale
                case .exhale:
                    isExpanded = false
                    breathingPhase = .inhale
                }
            }
        }
    }
}

#Preview {
    BreathingAnimationView()
        .frame(height: 200)
        .background(VenusTheme.backgroundGradient)
}