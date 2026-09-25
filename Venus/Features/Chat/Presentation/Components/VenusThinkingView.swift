//
//  VenusThinkingView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusThinkingView: View {
    @State private var animateDots = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                HStack(spacing: 4.5) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(VenusTheme.primary)
                            .frame(width: 7, height: 7)
                            .scaleEffect(animateDots ? 1.2 : 0.7)
                            .opacity(animateDots ? 1.0 : 0.35)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(VenusTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(VenusTheme.primary.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
                    )
            )
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 16)
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
