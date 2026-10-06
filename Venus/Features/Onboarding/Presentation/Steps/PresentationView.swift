//
//  PresentationView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct PresentationView: View {
    var onNext: () -> Void

    @State private var appear = false
    @State private var orbAppear = false
    @State private var mascotState: VenusMascotState = .welcoming
    @State private var mascotMood: MoodType = .happy

    var body: some View {
        ZStack {
            // Ambient glowing blobs
            ZStack {
                Circle()
                    .fill(VenusTheme.primary.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 72)
                    .offset(x: -80, y: -220)

                Circle()
                    .fill(VenusTheme.accentBlue.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 60)
                    .offset(x: 130, y: 180)
            }

            VStack(spacing: 0) {
                Spacer()

                // Interactive Hero Mascot
                VenusMoodOrb(
                    mood: mascotMood,
                    state: mascotState,
                    size: 154,
                    showFace: true,
                    showHands: true,
                    showShadow: true,
                    isInteractive: true
                )
                .frame(width: 154, height: 154)
                .opacity(orbAppear ? 1 : 0)
                .scaleEffect(orbAppear ? 1 : 0.78)
                .animation(.spring(response: 0.7, dampingFraction: 0.68), value: orbAppear)

                // Title block (sem subtitulo)
                Text("Venus")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 14)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18), value: appear)
                    .padding(.top, 20)

                Spacer()

                // Bottom Action Button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onNext()
                } label: {
                    HStack(spacing: 8) {
                        Text("Começar")
                            .font(.system(.headline, design: .rounded).weight(.black))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(VenusTheme.primaryGradient, in: Capsule())
                    .shadow(color: VenusTheme.primary.opacity(0.30), radius: 16, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .buttonStyle(OnboardingPressableButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.28), value: appear)
            }
        }
        .onAppear {
            orbAppear = true
            appear = true
        }
    }
}

#Preview {
    PresentationView(onNext: {})
}
