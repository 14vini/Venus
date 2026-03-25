//
//  HomeActionComponents.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI

struct HomeActionBadge: Identifiable {
    let title: String
    let systemImage: String
    let tint: Color

    var id: String { title }
}

struct HomeActionSection: View {
    let supportsActionModeSwitch: Bool
    let preferHighImpactAction: Bool
    let isLoadingInsights: Bool
    let action: NextBestAction?
    let badges: [HomeActionBadge]
    let alternativeActions: [NextBestAction]
    let errorMessage: String?
    let actionModeSummary: String
    let actionModeTint: Color
    let primaryActionTitle: String
    let showsReasonCTA: Bool
    let onSelectHighImpact: (Bool) -> Void
    let onSelectAlternative: (NextBestAction) -> Void
    let onPrimaryAction: () -> Void
    let onReasonTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Seu próximo passo")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.text)

            if supportsActionModeSwitch {
                HomeActionModeSegment(
                    preferHighImpact: preferHighImpactAction,
                    onSelect: { value in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            onSelectHighImpact(value)
                        }
                    }
                )
            }

            // Card principal
            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(VenusTheme.cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(VenusTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            // Ações alternativas fora do card
            if let action, !alternativeActions.isEmpty {
                HomeAlternativeActionsSection(
                    currentAction: action,
                    alternatives: alternativeActions,
                    onSelect: onSelectAlternative
                )
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: preferHighImpactAction)
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: action?.id)
    }

    @ViewBuilder
    private var content: some View {
        if isLoadingInsights {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(VenusTheme.accentBlue)
                    .scaleEffect(1.2)

                Text("Analisando seus padrões")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(VenusTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        } else if let action {
            VStack(spacing: 0) {
                // Zona 1 — Contexto (só leitura)
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: action.kind.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(actionModeSummary)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(actionModeTint)

                        Text(action.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(action.detail)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VenusIllustrationCluster(
                        symbols: actionIllustrationSymbols(for: action),
                        width: 108,
                        height: 90
                    )
                }
                .padding(24)

                // Divisor
                Rectangle()
                    .fill(VenusTheme.cardBorder)
                    .frame(height: 1)

                // Zona 2 — Metadados (só leitura)
                VStack(alignment: .leading, spacing: 10) {
                    HomeTimeProgressBar(
                        estimatedMinutes: action.estimatedMinutes,
                        tint: actionModeTint
                    )

                    if !badges.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(badges) { badge in
                                    HomeActionBadgeView(badge: badge)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // Divisor
                Rectangle()
                    .fill(VenusTheme.cardBorder)
                    .frame(height: 1)

                // Zona 3 — Ações
                VStack(spacing: 10) {
                    Button(action: onPrimaryAction) {
                        HStack(spacing: 8) {
                            Text(primaryActionTitle)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(VenusTheme.primaryGradient)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                    }

                    if showsReasonCTA {
                        Button(action: onReasonTap) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(VenusTheme.accentBlue.opacity(0.14))
                                        .frame(width: 38, height: 38)

                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(VenusTheme.accentBlue)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Entender por que isso apareceu")
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        .foregroundColor(VenusTheme.text)

                                    Text("Abra a leitura visual dessa recomendação.")
                                        .font(.system(.caption, design: .rounded).weight(.medium))
                                        .foregroundColor(VenusTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(VenusTheme.accentBlue)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(VenusTheme.accentBlue.opacity(0.09))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(VenusTheme.accentBlue.opacity(0.16), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        } else if let errorMessage {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundColor(VenusTheme.accentPink)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: onPrimaryAction) {
                    Text("Tentar novamente")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(VenusTheme.primaryGradient)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        } else {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Faça um check-in")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text("A próxima ação nasce a partir dele.")
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                }

                Spacer(minLength: 8)

                VenusIllustrationCluster(
                    symbols: [
                        VenusIllustrationSymbol(systemName: "heart.text.square.fill", tint: VenusTheme.accentBlue, size: 16),
                        VenusIllustrationSymbol(systemName: "sparkles", tint: VenusTheme.accentOrange, size: 16),
                        VenusIllustrationSymbol(systemName: "arrow.right.circle.fill", tint: VenusTheme.accentGreen, size: 14)
                    ],
                    width: 98,
                    height: 80
                )
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    private func actionIllustrationSymbols(for action: NextBestAction) -> [VenusIllustrationSymbol] {
        let primaryTint: Color
        let secondaryTint: Color

        switch action.kind.category {
        case .execution:
            primaryTint = VenusTheme.accentOrange
            secondaryTint = VenusTheme.accentBlue
        case .planning:
            primaryTint = VenusTheme.accentBlue
            secondaryTint = VenusTheme.accentGreen
        case .communication:
            primaryTint = VenusTheme.accentPink
            secondaryTint = VenusTheme.accentOrange
        case .movement:
            primaryTint = VenusTheme.accentGreen
            secondaryTint = VenusTheme.accentBlue
        case .recovery:
            primaryTint = VenusTheme.accentPurple
            secondaryTint = VenusTheme.accentPink
        }

        return [
            VenusIllustrationSymbol(systemName: action.kind.iconName, tint: primaryTint, size: 18),
            VenusIllustrationSymbol(systemName: "timer", tint: secondaryTint, size: 14),
            VenusIllustrationSymbol(systemName: "sparkles", tint: VenusTheme.accentOrange, size: 14)
        ]
    }
}

// MARK: - Mode Segment

private struct HomeActionModeSegment: View {
    let preferHighImpact: Bool
    let onSelect: (Bool) -> Void

    var body: some View {
        HStack(spacing: 0) {
            modeOption(title: "Rápido", systemImage: "hare.fill", isSelected: !preferHighImpact) {
                onSelect(false)
            }
            modeOption(title: "Completo", systemImage: "sparkles", isSelected: preferHighImpact) {
                onSelect(true)
            }
        }
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: Capsule())
    }

    @ViewBuilder
    private func modeOption(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
            }
            .foregroundColor(isSelected ? VenusTheme.text : VenusTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isSelected ? VenusTheme.accentBlue.opacity(0.12) : Color.clear)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}

// MARK: - Badge

private struct HomeActionBadgeView: View {
    let badge: HomeActionBadge

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: badge.systemImage)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(badge.tint)

            Text(badge.title)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(badge.tint.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - Time Progress Bar

private struct HomeTimeProgressBar: View {
    let estimatedMinutes: Int
    let tint: Color
    @State private var appeared = false

    private let maxMinutes = 35
    private var progress: Double {
        min(Double(estimatedMinutes) / Double(maxMinutes), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Duração estimada")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundColor(VenusTheme.textSecondary)
                Spacer()
                Text("\(estimatedMinutes) min")
                    .font(.system(.caption2, design: .rounded).weight(.black))
                    .foregroundColor(tint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(VenusTheme.cardBorder.opacity(0.35))

                    Capsule()
                        .fill(LinearGradient(
                            colors: [tint.opacity(0.6), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: appeared ? max(16, geo.size.width * progress) : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: appeared)
                }
            }
            .frame(height: 6)
        }
        .onAppear { appeared = true }
        .onChange(of: estimatedMinutes) { _, _ in
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
    }
}

// MARK: - Alternative Actions Section

private struct HomeAlternativeActionsSection: View {
    let currentAction: NextBestAction
    let alternatives: [NextBestAction]
    let onSelect: (NextBestAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Outras opções para hoje")
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(alternatives) { alternative in
                        HomeAlternativeActionCard(action: alternative) {
                            onSelect(alternative)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }
}

private struct HomeAlternativeActionCard: View {
    let action: NextBestAction
    let onTap: () -> Void

    private var tint: Color {
        switch action.kind.category {
        case .execution: return VenusTheme.accentOrange
        case .planning: return VenusTheme.accentBlue
        case .communication: return VenusTheme.accentPink
        case .movement: return VenusTheme.accentGreen
        case .recovery: return VenusTheme.accentPurple
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(0.14))
                            .frame(width: 32, height: 32)

                        Image(systemName: action.kind.iconName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(tint)
                    }

                    Spacer(minLength: 0)

                    Text("\(action.estimatedMinutes) min")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundColor(VenusTheme.textSecondary)
                }

                Text(action.title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .frame(width: 154, height: 136, alignment: .leading)
            .padding(14)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
