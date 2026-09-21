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

    var body: some View {
        ZStack {
            // Ambient blobs
            ZStack {
                Circle()
                    .fill(VenusTheme.primary.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 72)
                    .offset(x: -80, y: -220)

                Circle()
                    .fill(VenusTheme.accentBlue.opacity(0.10))
                    .frame(width: 260, height: 260)
                    .blur(radius: 60)
                    .offset(x: 130, y: 180)
            }

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()

                        // Orb
                        VenusMoodOrb(mood: .happy, size: 140)
                            .opacity(orbAppear ? 1 : 0)
                            .scaleEffect(orbAppear ? 1 : 0.78)
                            .animation(.spring(response: 0.7, dampingFraction: 0.68), value: orbAppear)

                        // Title block
                        VStack(spacing: 8) {
                            Text("Venus")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(VenusTheme.text)

                            Text("Não é terapia, mas é terapêutico.")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(VenusTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 14)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18), value: appear)
                        .padding(.top, 20)

                        Spacer()

                        // CTA card
                        VenusCard(cornerRadius: 32, padding: 22) {
                            VStack(spacing: 16) {
                                Text("Posso te ajudar a encontrar equilíbrio hoje?")
                                    .font(.system(.callout, design: .rounded).weight(.medium))
                                    .foregroundColor(VenusTheme.textSecondary)
                                    .multilineTextAlignment(.center)

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
                                    .padding(.vertical, 16)
                                    .background(VenusTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .shadow(color: VenusTheme.primary.opacity(0.30), radius: 18, x: 0, y: 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 40)
                        .animation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.32), value: appear)
                    }
                    .frame(minHeight: geometry.size.height, alignment: .center)
                }
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
