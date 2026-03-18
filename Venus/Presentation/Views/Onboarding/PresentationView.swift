//
//  PresentationView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct PresentationView: View {
    var onNext: () -> Void
    
    @State private var pulse = false
    @State private var rotate = false
    @State private var appear = false
    
    var body: some View {
        ZStack {
            // MARK: - Background
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Ambient Orbs (Blurred Background Blobs)
            ZStack {
                Circle()
                    .fill(VenusTheme.primary.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -200)
                
                Circle()
                    .fill(VenusTheme.accentPink.opacity(0.15))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: 120, y: 150)
            }
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(VenusTheme.primary)
                        .padding()
                        .background(
                            Circle()
                                .fill(VenusTheme.surface)
                                .shadow(color: VenusTheme.primary.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                    Spacer()
                    
                    Text("Venus")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(VenusTheme.surface))
                        .shadow(color: VenusTheme.text.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // MARK: - Center Orb & Greeting
                ZStack {
                    // Pulsing Rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [VenusTheme.primary.opacity(0.5), VenusTheme.secondary.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 250 + CGFloat(i * 40), height: 250 + CGFloat(i * 40))
                            .scaleEffect(pulse ? 1.05 : 0.95)
                            .opacity(pulse ? 0.8 : 0.4)
                            .animation(
                                .easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                                value: pulse
                            )
                    }
                    
                    // Center Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [VenusTheme.primary.opacity(0.2), .clear]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                    
                    // Main Text
                    VStack(spacing: 8) {
                        Text("Ola, sou a Venus")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                        
                        Text("Seu guia de bem-estar")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                        Text("Não é terapia, mas é terapêutico.")
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                .offset(y: -40)
                
                Spacer()
                
                // MARK: - Action Card
                VStack(spacing: 20) {
                    Text("Posso ajudar você a encontrar equilíbrio hoje?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: onNext) {
                        HStack {
                            Text("Iniciar Jornada")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(VenusTheme.primaryGradient)
                        .cornerRadius(30)
                        .shadow(color: VenusTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 35)
                        .fill(VenusTheme.surface)
                        .shadow(color: VenusTheme.text.opacity(0.1), radius: 20, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(VenusTheme.chipBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .offset(y: appear ? 0 : 100)
                .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            pulse = true
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                appear = true
            }
        }
    }
}

#Preview {
    PresentationView(onNext: {})
}
