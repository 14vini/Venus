//
//  VenusHomeJourneyDetailsSheet.swift
//  Venus
//
//  Acesso secundário da Home (um toque no ícone de estrelas da toolbar):
//  sequência real de check-ins, prontidão, modo de bem-estar e padrão da semana.
//  O topo da Home fica só com o arco dos rituais e a saudação curta.
//

import SwiftUI

/// Sheet secundária da Home. O streak (A3) vive aqui — com cosméticos e confete de
/// marco preservados — e a prontidão abre o detalhamento completo sem competir com o hero.
struct VenusHomeJourneyDetailsSheet: View {
    @Binding var selectedMode: VenusWellnessMode
    let patternSnapshot: PatternInsightsSnapshot?
    let streakDays: Int
    let cosmetic: VenusCosmeticItem
    let readinessPercentage: Int
    let readinessStateTitle: String
    let onOpenReadiness: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    streakSection

                    readinessSection

                    modeSection

                    if let patternSnapshot {
                        patternSection(patternSnapshot)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .background(VenusHomeJourneyBackground())
            .navigationTitle("Seu momento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusTheme.text)
                }
            }
        }
    }

    // MARK: - Streak (A3): histórico completo no ViewModel, exibição e confete aqui

    /// Sem container recortado: o confete de marco do StreakBadge precisa de espaço livre.
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SUA SEQUÊNCIA")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(VenusHomeJourneyPalette.lilac)

            StreakBadge(days: streakDays, celebrated: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.opacity)
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: streakDays)

            if streakDays > 0 {
                Text("Cosmético desbloqueado: \(cosmetic.title)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            } else {
                Text("Check-ins em dias seguidos desbloqueiam cosméticos para a Venus.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sequência de \(streakDays) dias")
    }

    // MARK: - Prontidão: fora do hero, mas a um toque do detalhamento completo

    private var readinessSection: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpenReadiness()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.72),
                            lineWidth: 3
                        )

                    Circle()
                        .trim(from: 0, to: readinessFraction)
                        .stroke(
                            VenusHomeJourneyPalette.lilac,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: readinessFraction)

                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(VenusHomeJourneyPalette.lilac)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(readinessPercentage)")
                            .font(.system(size: 22, weight: .light, design: .rounded))
                            .contentTransition(.numericText())

                        Text("%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }

                    Text(readinessStateTitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(VenusTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(VenusHomePressableButtonStyle())
        .accessibilityLabel("Prontidão \(readinessPercentage)%, \(readinessStateTitle). Abrir detalhes")
    }

    private var readinessFraction: CGFloat {
        CGFloat(min(max(Double(readinessPercentage) / 100, 0), 1))
    }

    // MARK: - Modo de bem-estar

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMO VOCÊ QUER SE SENTIR?")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(VenusHomeJourneyPalette.lilac)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(VenusWellnessMode.allCases) { mode in
                    let isSelected = selectedMode == mode

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                            selectedMode = mode
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: mode.iconSystemName)
                                .font(.system(size: 18, weight: isSelected ? .bold : .semibold))

                            Text(mode.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(
                            isSelected
                                ? (colorScheme == .dark ? Color.black : Color.white)
                                : VenusTheme.text
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    isSelected
                                        ? (colorScheme == .dark ? Color.white : Color(hex: "241E2B"))
                                        : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.48)
                                )
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(VenusHomePressableButtonStyle())
                    .accessibilityLabel(mode.label)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    // MARK: - Padrão da semana (A4)

    private func patternSection(_ snapshot: PatternInsightsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PADRÃO DA SEMANA")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(VenusHomeJourneyPalette.lilac)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: snapshot.weeklyTrend.direction.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(VenusHomeJourneyPalette.lilac)

                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.weeklyTrend.direction.title)
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.text)

                    Text(snapshot.weeklyTrend.summary)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(snapshot.nextBestAction.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(VenusTheme.text)

                    Text(snapshot.nextBestAction.detail)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
