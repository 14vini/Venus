//
//  HomeHeaderComponents.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI

struct HomeHeaderHighlight: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let tint: Color
}

struct HomeHeaderSection: View {
    let title: String
    let supportText: String
    let streakDays: Int
    let highlights: [HomeHeaderHighlight]
    let mood: MoodType?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Orb + Hint Card
            HStack(alignment: .center, spacing: 12) {
                VenusMoodOrb(mood: mood, size: 64)

                VenusFloatingHintBubble(
                    title: title,
                    bodyText: supportText,
                    maxWidth: .infinity
                )
                .frame(maxWidth: .infinity)
            }

            // Streak + pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Streak destacado
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(VenusTheme.accentOrange)
                        Text("\(streakDays) dias seguidos")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(VenusTheme.accentOrange.opacity(0.12))
                    .clipShape(Capsule())

                    ForEach(highlights) { highlight in
                        HomeHeaderPill(highlight: highlight)
                    }
                }
            }
            .scrollClipDisabled()
        }
        .padding(.top, 8)
    }
}

struct HomeCheckInOverviewSection: View {
    let statusText: String
    let statusHighlight: HomeHeaderHighlight
    let availabilityHighlight: HomeHeaderHighlight
    let mood: MoodType?
    let intensity: Int?
    let trendHighlight: HomeHeaderHighlight?
    let showsUpgradeCTA: Bool
    let onUpgradeTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Seu estado hoje")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text(statusHeadline)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text(statusText)
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                VenusIllustrationCluster(
                    symbols: overviewSymbols,
                    width: 110,
                    height: 92
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    HomeHeaderPill(highlight: statusHighlight)
                    HomeHeaderPill(highlight: availabilityHighlight)

                    if let mood {
                        MoodBadge(mood: mood, intensity: intensity)
                            .transition(.scale.combined(with: .opacity))
                    }

                    if let trendHighlight {
                        HomeHeaderPill(highlight: trendHighlight)
                    }

                    if showsUpgradeCTA {
                        Button(action: onUpgradeTap) {
                            VenusProBadge(title: "Ver Pro", compact: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }

    private var statusHeadline: String {
        if mood != nil {
            return "Leitura pronta para hoje"
        }
        return "Check-in esperando você"
    }

    private var overviewSymbols: [VenusIllustrationSymbol] {
        let moodSymbol: String
        let moodTint: Color

        switch mood {
        case .calm:
            moodSymbol = "leaf.fill"
            moodTint = VenusTheme.accentGreen
        case .happy:
            moodSymbol = "sun.max.fill"
            moodTint = VenusTheme.accentOrange
        case .energetic:
            moodSymbol = "bolt.fill"
            moodTint = VenusTheme.accentBlue
        case .stressed:
            moodSymbol = "waveform.path.ecg"
            moodTint = VenusTheme.accentPink
        case .sad:
            moodSymbol = "cloud.drizzle.fill"
            moodTint = VenusTheme.accentBlue
        case .tired:
            moodSymbol = "moon.zzz.fill"
            moodTint = VenusTheme.accentPurple
        case nil:
            moodSymbol = "heart.text.square.fill"
            moodTint = VenusTheme.accentBlue
        }

        return [
            VenusIllustrationSymbol(systemName: moodSymbol, tint: moodTint, size: 18),
            VenusIllustrationSymbol(systemName: "sparkles", tint: VenusTheme.accentOrange, size: 16),
            VenusIllustrationSymbol(systemName: "chart.line.uptrend.xyaxis", tint: VenusTheme.accentGreen, size: 14)
        ]
    }
}

struct HomeCheckInFloatingOverlay: View {
    let showHint: Bool
    let hintTitle: String
    let hintBody: String
    let buttonTitle: String
    let buttonSubtitle: String
    let buttonIcon: String
    let isProPrompt: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if showHint {
                VenusFloatingHintBubble(
                    title: hintTitle,
                    bodyText: hintBody
                )
                .allowsHitTesting(false)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            HomeCheckInFloatingButton(
                title: buttonTitle,
                subtitle: buttonSubtitle,
                systemImage: buttonIcon,
                isProPrompt: isProPrompt,
                highlightTapTarget: showHint,
                isDisabled: isDisabled,
                action: action
            )
        }
    }
}

private struct MoodBadge: View {
    let mood: MoodType
    let intensity: Int?

    var body: some View {
        HStack(spacing: 6) {
            Text(mood.emoji)
                .font(.system(size: 14))

            Text(mood.rawValue)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)

            if let intensity {
                Text("\(intensity)/10")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(VenusTheme.surface.opacity(0.6))
        .clipShape(Capsule())
    }
}

private struct HomeHeaderPill: View {
    let highlight: HomeHeaderHighlight

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: highlight.systemImage)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(highlight.tint)

            Text(highlight.title)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(highlight.tint.opacity(0.08))
        .clipShape(Capsule())
    }
}

private struct HomeCheckInFloatingButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isProPrompt: Bool
    let highlightTapTarget: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var animateGuidanceHalo = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isProPrompt ? VenusTheme.proGradient : VenusTheme.primaryGradient)
                        .frame(width: 46, height: 46)

                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text(subtitle)
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 10)
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .glassEffect(.regular.interactive())
//            .background {
//                if highlightTapTarget && !isDisabled {
//                    guidanceHalo
//                        .allowsHitTesting(false)
//                }
//            }
//            .opacity(isDisabled ? 0.72 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onAppear {
            startGuidanceHaloIfNeeded()
        }
        .onChange(of: highlightTapTarget) { _, _ in
            startGuidanceHaloIfNeeded()
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if isProPrompt {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(VenusTheme.proGradient.opacity(0.16))
                )
                .shadow(color: VenusTheme.accentPurple.opacity(0.14), radius: 12, x: 0, y: 8)
        } else {
            Capsule()
                .fill(VenusTheme.surface)
                .overlay(
                    Capsule()
                        .stroke(VenusTheme.cardBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
        }
    }

    private var guidanceHalo: some View {
        ZStack {
            Capsule()
                .fill(guidanceColor.opacity(animateGuidanceHalo ? 0.26 : 0.18))
                .frame(height: 70)
                .blur(radius: animateGuidanceHalo ? 24 : 14)
                .scaleEffect(x: animateGuidanceHalo ? 1.08 : 0.96, y: animateGuidanceHalo ? 1.12 : 0.98)

            Capsule()
                .stroke(guidanceColor.opacity(animateGuidanceHalo ? 0.32 : 0.16), lineWidth: 1.2)
                .frame(height: 60)
                .blur(radius: 0.4)
                .scaleEffect(animateGuidanceHalo ? 1.04 : 0.94)
        }
        .padding(.horizontal, -8)
    }

    private var guidanceColor: Color {
        isProPrompt ? VenusTheme.accentPurple : VenusTheme.moodMintStrong
    }

    private func startGuidanceHaloIfNeeded() {
        guard highlightTapTarget, !animateGuidanceHalo else { return }

        withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
            animateGuidanceHalo = true
        }
    }
}
