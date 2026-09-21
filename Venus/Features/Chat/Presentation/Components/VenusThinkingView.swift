//
//  VenusThinkingView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusThinkingView: View {
    @State private var animateDots = false
    @State private var pulseBubble = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            HStack(alignment: .center, spacing: 10) {
                // Mini Thinking Mascot
                VenusMoodOrb(
                    mood: .calm,
                    state: .thinking,
                    size: 38,
                    showFace: true,
                    isInteractive: false
                )
                
                // Thought bubble
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(VenusTheme.primary.opacity(0.85))
                                .frame(width: 6.5, height: 6.5)
                                .scaleEffect(animateDots ? 1.25 : 0.75)
                                .opacity(animateDots ? 1.0 : 0.4)
                                .animation(
                                    .easeInOut(duration: 0.55)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.18),
                                    value: animateDots
                                )
                        }
                    }
                    
                    Text("Venus está refletindo...")
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(VenusTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(VenusTheme.primary.opacity(colorScheme == .dark ? 0.2 : 0.12), lineWidth: 1)
                        )
                )
            }
            
            Spacer()
        }
        .onAppear {
            animateDots = true
        }
    }
}

#Preview {
    ZStack {
        VenusTheme.backgroundGradient.ignoresSafeArea()
        VenusThinkingView()
            .padding(20)
    }
}
