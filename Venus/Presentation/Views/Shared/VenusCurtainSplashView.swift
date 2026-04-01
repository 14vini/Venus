//
//  VenusSplashView.swift
//  Venus
//

import SwiftUI

struct VenusSplashView: View {
    let isReadyToReveal: Bool
    let onCompleted: () -> Void

    @State private var isRevealing = false
    @State private var breathe = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            splashBackground
                .opacity(isRevealing ? 0 : 1)

            splashAura
                .opacity(isRevealing ? 0 : 1)

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                VenusMoodMascotOrb(mood: .happy, size: 180)
                    .scaleEffect(isRevealing ? 1.06 : (breathe ? 1.02 : 0.98))
                    .opacity(isRevealing ? 0 : 1)
                    .animation(.spring(response: 0.6, dampingFraction: 0.78), value: breathe)

                VStack(spacing: 10) {
                    Text("VENUS")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .tracking(4)

                    Text("transforme sentimento em direção")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
                .opacity(isRevealing ? 0 : 1)
                .offset(y: isRevealing ? -16 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.86), value: isRevealing)

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    SplashLoadingBar(tint: VenusTheme.primary)

                    Text("inicializando seu ritual...")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary.opacity(colorScheme == .dark ? 0.72 : 0.62))
                        .tracking(1)
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 34)
                .opacity(isRevealing ? 0 : 1)
            }
        }
        .onAppear {
            guard !breathe else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .onChange(of: isReadyToReveal) { _, ready in
            guard ready, !isRevealing else { return }
            
            withAnimation(.easeInOut(duration: 0.8)) {
                isRevealing = true
            }
            
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                await MainActor.run {
                    onCompleted()
                }
            }
        }
    }

    private var splashBackground: some View {
        ZStack {
            VenusReadingBackground(dayMoment: .current, isAnimated: true)

            OnboardingWavesOverlay(
                tint: VenusTheme.primary,
                secondary: VenusTheme.accentBlue,
                tertiary: VenusTheme.accentPurple
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var splashAura: some View {
        Circle()
            .fill(VenusTheme.primary.opacity(colorScheme == .dark ? 0.20 : 0.14))
            .frame(width: 280, height: 280)
            .blur(radius: 42)
            .scaleEffect(isRevealing ? 7.6 : (breathe ? 1.10 : 0.92))
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: breathe)
            .animation(.easeInOut(duration: 0.8), value: isRevealing)
            .allowsHitTesting(false)
    }
}

#Preview {
    VenusSplashView(isReadyToReveal: true, onCompleted: {})
}

private struct SplashLoadingBar: View {
    let tint: Color

    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.10)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let blockWidth = max(60, width * 0.26)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(trackColor)

                Capsule(style: .continuous)
                    .fill(LinearGradient(
                        colors: [tint.opacity(0.55), tint],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: blockWidth)
                    .offset(x: animate ? width - blockWidth : 0)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.clear.interactive(), in: Capsule(style: .continuous))
        .onAppear {
            guard !animate else { return }
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
        .accessibilityLabel("Carregando")
    }
}
