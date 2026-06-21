//
//  AboutStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct AboutStep: View {
    @Binding var userProfile: UserProfile
    
    @Environment(\.colorScheme) private var colorScheme

    @State private var reveal = false
    @State private var currentSlide = 0
    @State private var slideDirection: Int = 1

    private let features: [AboutFeature] = [
	        AboutFeature(
	            title: "Leitura do seu momento",
	            detail: "Um check-in rápido vira uma visão clara do seu dia.",
	            systemImage: "sparkles",
	            tint: VenusTheme.accentBlue,
	            highlights: ["Check-in rápido", "Visão clara", "Sem pressão"]
	        ),
	        AboutFeature(
	            title: "Próximo passo possível",
	            detail: "Eu sugiro uma ação curta que cabe no seu tempo e energia.",
	            systemImage: "bolt.fill",
	            tint: VenusTheme.accentGreen,
	            highlights: ["Curto", "Realista", "Agora"]
	        ),
	        AboutFeature(
	            title: "Motivos e evidências",
	            detail: "Você vê por que essa ação faz sentido (Reason Why).",
	            systemImage: "point.3.connected.trianglepath.dotted",
	            tint: VenusTheme.accentPurple,
	            highlights: ["Reason why", "Contexto", "Evidências"]
	        ),
	        AboutFeature(
	            title: "Ritual leve, sempre seu",
	            detail: "Não é terapia — é um copiloto. Você segue no controle.",
	            systemImage: "heart.fill",
	            tint: VenusTheme.accentPink,
	            highlights: ["Gentil", "Consistente", "Seu ritmo"]
	        )
	    ]

    private var currentFeature: AboutFeature {
        let index = min(max(currentSlide, 0), features.count - 1)
        return features[index]
    }
    
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                VenusMoodOrb(mood: .calm, size: 130)
                    .opacity(reveal ? 1 : 0)
                    .scaleEffect(reveal ? 1 : 0.86)
                    .animation(.spring(response: 0.7, dampingFraction: 0.72), value: reveal)
                Spacer()
            }
            .padding(.top, 4)

            OnboardingStepHeader(
                eyebrow: "o que é venus",
                title: "Seu copiloto de bem-estar",
                subtitle: "Uma leitura do seu momento + um próximo passo realista para hoje.",
                systemImage: "sparkles",
                tint: VenusTheme.accentBlue,
                accessory: "toque"
            )
            .opacity(reveal ? 1 : 0)
            .offset(y: reveal ? 0 : 12)
            .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.08), value: reveal)

            Spacer(minLength: 0)

            ZStack {
                slideAmbientBackground

                VStack(spacing: 16) {
                    AboutSlidesProgressBar(total: features.count, current: currentSlide, tint: currentFeature.tint)

                    ViewThatFits(in: .vertical) {
                        slidesDeck
                            .frame(height: 420)
                        slidesDeck
                            .frame(height: 380)
                        slidesDeck
                            .frame(height: 340)
                        slidesDeck
                            .frame(height: 300)
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.14 : 0.22),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .blendMode(.overlay)
                )
            }
            .opacity(reveal ? 1 : 0)
            .offset(y: reveal ? 0 : 16)
            .animation(.spring(response: 0.55, dampingFraction: 0.86).delay(0.16), value: reveal)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 26)
        .onAppear { reveal = true }
    }

    private var slideAmbientBackground: some View {
        ZStack {
            Circle()
                .fill(currentFeature.tint.opacity(colorScheme == .dark ? 0.18 : 0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -110, y: -50)

            Circle()
                .fill(currentFeature.tint.opacity(colorScheme == .dark ? 0.12 : 0.10))
                .frame(width: 260, height: 260)
                .blur(radius: 74)
                .offset(x: 120, y: 140)
        }
        .animation(.easeInOut(duration: 0.6), value: currentSlide)
        .allowsHitTesting(false)
    }

    private var slideTapZones: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { goToSlide(currentSlide - 1) }
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { goToSlide(currentSlide + 1) }
        }
        .accessibilityHidden(true)
    }

    private var slidesDeck: some View {
        ZStack {
            AboutFeatureSlideContent(
                feature: currentFeature,
                isActive: true
            )
            .id(currentSlide)
            .transition(slideTransition)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(slideTapZones)
    }

    private func goToSlide(_ target: Int) {
        let clamped = min(max(target, 0), features.count - 1)
        guard clamped != currentSlide else { return }
        slideDirection = clamped > currentSlide ? 1 : -1
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            currentSlide = clamped
        }
    }

    private var slideTransition: AnyTransition {
        let insertion: AnyTransition = slideDirection >= 0 ?
            .move(edge: .trailing).combined(with: .opacity) :
            .move(edge: .leading).combined(with: .opacity)

        let removal: AnyTransition = slideDirection >= 0 ?
            .move(edge: .leading).combined(with: .opacity) :
            .move(edge: .trailing).combined(with: .opacity)

        return .asymmetric(insertion: insertion, removal: removal)
    }
}

private struct AboutFeature: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    let highlights: [String]
}

private struct AboutSlidesProgressBar: View {
    let total: Int
    let current: Int
    var tint: Color = VenusTheme.primary

    @Environment(\.colorScheme) private var colorScheme

    private var safeTotal: Int { max(total, 1) }
    private var safeCurrent: Int { min(max(current, 0), safeTotal - 1) }

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.20) : Color.black.opacity(0.16)
    }
    private var fillColor: Color {
        tint
    }
    private var seenColor: Color {
        tint.opacity(colorScheme == .dark ? 0.42 : 0.30)
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<safeTotal, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(color(for: index))
                    .frame(height: 3)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: safeCurrent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slides")
        .accessibilityValue("\(safeCurrent + 1) de \(safeTotal)")
    }

    private func color(for index: Int) -> Color {
        if index < safeCurrent { return seenColor }
        if index == safeCurrent { return fillColor }
        return trackColor
    }
}

private struct AboutFeatureSlideContent: View {
    let feature: AboutFeature
    let isActive: Bool

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(feature.tint.opacity(0.22))
                    .frame(width: 108, height: 108)
                    .blur(radius: 22)

                Circle()
                    .fill(LinearGradient(
                        colors: [feature.tint, feature.tint.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 76, height: 76)

                Image(systemName: feature.systemImage)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isActive)
            }
            .padding(.top, 6)

            VStack(spacing: 10) {
                Text(feature.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(feature.detail)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(feature.highlights, id: \.self) { highlight in
                    AboutHighlightRow(text: highlight, tint: feature.tint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }
}

private struct AboutHighlightRow: View {
    let text: String
    var tint: Color = VenusTheme.primary

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(tint)

            Text(text)
                .font(.system(.callout, design: .rounded).weight(.bold))
                .foregroundStyle(VenusTheme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        VenusTheme.backgroundGradient.ignoresSafeArea()
        AboutStep(userProfile: .constant(UserProfile()))
    }
}
