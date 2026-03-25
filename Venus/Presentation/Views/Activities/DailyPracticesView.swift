//
//  DailyPracticesView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct DailyPracticesView: View {
    @StateObject private var viewModel: ActivitiesListViewModel
    @State private var selectedPractice: Activity?
    @State private var showPracticeDetail = false
    @State private var showBreathingView = false
    @State private var showPomodoroView = false
    @State private var showGratitudeView = false
    @State private var appear = false

    init(viewModel: ActivitiesListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.accentBlue,
                secondaryAccent: VenusTheme.accentPink,
                tertiaryAccent: VenusTheme.accentGreen
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    practicesHeroSection
                    quickActionsSection
                    if !viewModel.activities.isEmpty {
                        allPracticesSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            appear = true
            Task { await viewModel.loadActivities() }
        }
        .sheet(isPresented: $showPracticeDetail) {
            if let practice = selectedPractice {
                PracticeDetailView(activity: practice)
            }
        }
        .fullScreenCover(isPresented: $showBreathingView) { BreathingView() }
        .fullScreenCover(isPresented: $showPomodoroView) { PomodoroView() }
        .fullScreenCover(isPresented: $showGratitudeView) { GratitudeView() }
    }

    // MARK: - Hero

    private var practicesHeroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                VenusGlassPill(title: "Hoje", systemImage: "sun.max.fill", tint: VenusTheme.accentOrange)
                VenusGlassPill(title: "Práticas", systemImage: "sparkles", tint: VenusTheme.moodMintStrong)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Práticas Diárias")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundColor(VenusTheme.text)

                Text("Encontre equilíbrio em pequenos momentos.")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            // Streak / progress row
            HStack(spacing: 12) {
                PracticeStatBadge(icon: "flame.fill", label: "Sequência", value: "3 dias", tint: VenusTheme.accentOrange)
                PracticeStatBadge(icon: "checkmark.circle.fill", label: "Hoje", value: "0 feitas", tint: VenusTheme.accentGreen)
                PracticeStatBadge(icon: "clock.fill", label: "Tempo", value: "~15 min", tint: VenusTheme.accentBlue)
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 16)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05), value: appear)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Acesso rápido", subtitle: "Toque para começar agora")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                PracticeQuickCard(
                    title: "Respiração",
                    subtitle: "5 min · Relaxamento",
                    icon: "wind",
                    tint: VenusTheme.accentBlue,
                    action: { showBreathingView = true }
                )
                .opacity(appear ? 1 : 0)
                .offset(x: appear ? 0 : -20)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.12), value: appear)

                PracticeQuickCard(
                    title: "Pomodoro",
                    subtitle: "25 min · Foco",
                    icon: "timer",
                    tint: VenusTheme.accentOrange,
                    action: { showPomodoroView = true }
                )
                .opacity(appear ? 1 : 0)
                .offset(x: appear ? 0 : 20)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.18), value: appear)

                PracticeQuickCard(
                    title: "Gratidão",
                    subtitle: "3 min · Bem-estar",
                    icon: "heart.fill",
                    tint: VenusTheme.accentPink,
                    action: { showGratitudeView = true }
                )
                .opacity(appear ? 1 : 0)
                .offset(x: appear ? 0 : -20)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.24), value: appear)

                PracticeQuickCard(
                    title: "Meditação",
                    subtitle: "10 min · Calma",
                    icon: "leaf.fill",
                    tint: VenusTheme.accentGreen,
                    action: { showBreathingView = true }
                )
                .opacity(appear ? 1 : 0)
                .offset(x: appear ? 0 : 20)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.30), value: appear)
            }
        }
    }

    // MARK: - All Practices

    private var allPracticesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Todas as práticas", subtitle: "Por categoria")

            ForEach(Array(ActivityCategory.allCases.enumerated()), id: \.element) { index, category in
                if let activities = viewModel.activities[category], !activities.isEmpty {
                    PracticeCategoryRow(
                        category: category,
                        activities: activities,
                        onTap: { activity in
                            selectedPractice = activity
                            showPracticeDetail = true
                        }
                    )
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 24)
                    .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.36 + Double(index) * 0.08), value: appear)
                }
            }
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
            Text(subtitle)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
        }
    }
}

// MARK: - Stat Badge (non-interactive → solid card, no glass)

private struct PracticeStatBadge: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tint)
            }

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)

            Text(label)
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.985))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.92),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Quick Action Card (interactive → glassEffect.interactive)

private struct PracticeQuickCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.text)

                    Text(subtitle)
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Row

private struct PracticeCategoryRow: View {
    let category: ActivityCategory
    let activities: [Activity]
    let onTap: (Activity) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color { category.accentColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Category header — non-interactive solid card
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: 34, height: 34)
                    Image(systemName: category.iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.system(.subheadline, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.text)
                    Text("\(activities.count) prática\(activities.count != 1 ? "s" : "")")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.985))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.92),
                        lineWidth: 1
                    )
            )

            // Activity cards — interactive → glassEffect.interactive
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activities.prefix(4)) { activity in
                        PracticeActivityCard(activity: activity, tint: tint, onTap: { onTap(activity) })
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }
}

// MARK: - Activity Card (interactive → glassEffect.interactive)

private struct PracticeActivityCard: View {
    let activity: Activity
    let tint: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(tint.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: activity.iconName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(tint)
                    }

                    Spacer(minLength: 0)

                    Text("\(activity.durationMinutes) min")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(VenusTheme.cardBorder.opacity(0.28))
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.system(.subheadline, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.text)
                        .lineLimit(2)

                    Text(activity.description)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Iniciar")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                }
                .foregroundColor(tint)
            }
            .padding(14)
            .frame(width: 168, height: 158, alignment: .topLeading)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ActivityCategory helpers

private extension ActivityCategory {
    var iconName: String {
        switch self {
        case .relaxation: return "leaf.fill"
        case .focus:      return "target"
        case .creativity: return "paintbrush.fill"
        case .physical:   return "figure.run"
        case .social:     return "person.2.fill"
        }
    }
}

// MARK: - PracticeDetailView (sheet)

struct PracticeDetailView: View {
    let activity: Activity
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color { activity.category.accentColor }

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: tint,
                secondaryAccent: VenusTheme.accentPink,
                tertiaryAccent: VenusTheme.accentGreen
            )

            VStack(spacing: 0) {
                // Drag indicator area
                Capsule()
                    .fill(VenusTheme.cardBorder.opacity(0.5))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Hero icon
                        ZStack {
                            Circle()
                                .fill(tint.opacity(0.14))
                                .frame(width: 100, height: 100)
                            Image(systemName: activity.iconName)
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(tint)
                        }
                        .padding(.top, 16)

                        // Title block — non-interactive solid card
                        VStack(spacing: 8) {
                            Text(activity.title)
                                .font(.system(size: 28, weight: .black, design: .serif))
                                .foregroundColor(VenusTheme.text)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 8) {
                                VenusGlassPill(
                                    title: activity.category.rawValue,
                                    systemImage: activity.category.iconName,
                                    tint: tint
                                )
                                VenusGlassPill(
                                    title: "\(activity.durationMinutes) min",
                                    systemImage: "clock.fill",
                                    tint: VenusTheme.textSecondary
                                )
                            }
                        }

                        // Description card — non-interactive
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Sobre esta prática")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Text(activity.description)
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundColor(VenusTheme.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.985))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.92),
                                    lineWidth: 1
                                )
                        )
                        .padding(.horizontal, 20)

                        // Steps preview — non-interactive
                        if let steps = activity.steps, !steps.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Passos")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                ForEach(Array(steps.prefix(3).enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(tint.opacity(0.14))
                                                .frame(width: 28, height: 28)
                                            Text("\(index + 1)")
                                                .font(.system(.caption, design: .rounded).weight(.black))
                                                .foregroundColor(tint)
                                        }
                                        Text(step)
                                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                                            .foregroundColor(VenusTheme.text)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.985))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.92),
                                        lineWidth: 1
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 120)
                }

                // CTA — interactive glass button
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Iniciar prática")
                            .font(.system(.body, design: .rounded).weight(.bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(VenusTheme.primaryGradient)
                    .cornerRadius(22)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .padding(.top, 12)
            }
        }
    }
}

#Preview {
    DailyPracticesView(viewModel: ActivitiesListViewModel(getActivitiesUseCase: DependencyContainer.shared.makeGetActivitiesUseCase()))
}

#Preview("Practice Detail") {
    PracticeDetailView(activity: Activity(
        title: "Meditação Guiada",
        description: "Uma sessão relaxante para acalmar a mente e reduzir o estresse do dia a dia.",
        category: .relaxation,
        durationMinutes: 15,
        iconName: "leaf.fill",
        steps: ["Sente-se confortavelmente", "Feche os olhos e respire fundo", "Foque na sua respiração"]
    ))
}
