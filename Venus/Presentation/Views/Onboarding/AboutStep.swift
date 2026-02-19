//
//  VenusAboutStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusAboutStep: View {
    @Binding var userProfile: UserProfile
    
    // Animation states for each item
    @State private var showItem1 = false
    @State private var showItem2 = false
    @State private var showItem3 = false
    @State private var showItem4 = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("O que é Venus?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                
                Text("Seu assistente pessoal de bem-estar")
                    .font(.title3)
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // Feature List with Animated Arrows
            VStack(spacing: 24) {
                FeatureRow(
                    text: "Sugestões personalizadas",
                    icon: "sparkles",
                    delay: 0,
                    show: $showItem1
                )
                
                FeatureRow(
                    text: "Cronograma adaptável",
                    icon: "calendar.badge.clock",
                    delay: 0.2,
                    show: $showItem2
                )
                
                FeatureRow(
                    text: "Suporte emocional",
                    icon: "heart.fill",
                    delay: 0.4,
                    show: $showItem3
                )
                
                FeatureRow(
                    text: "Alívio de estresse",
                    icon: "leaf.fill",
                    delay: 0.6,
                    show: $showItem4
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.bottom, 30)
        .onAppear {
            // Trigger sequential animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) { showItem1 = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) { showItem2 = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) { showItem3 = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7)) { showItem4 = true }
        }
    }
}

struct FeatureRow: View {
    let text: String
    let icon: String
    let delay: Double
    @Binding var show: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(VenusTheme.primary.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(VenusTheme.primary)
            }
            
            Text(text)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.text)
            
            Spacer()
            
            // Animated Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(VenusTheme.secondary)
                .offset(x: show ? 0 : -20) // Slide from left
                .opacity(show ? 1 : 0)     // Fade in
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.6))
                .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.8), lineWidth: 1)
        )
        .offset(y: show ? 0 : 20) // Slide up entire row
        .opacity(show ? 1 : 0)
    }
}

#Preview {
    ZStack {
        VenusTheme.backgroundGradient.ignoresSafeArea()
        VenusAboutStep(userProfile: .constant(UserProfile()))
    }
}
