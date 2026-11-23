//
//  VenusStreakMockView.swift
//  Venus
//
//  F37 — mock-up isolado de streaks para validação visual (debug/preview).
//
//  COMO USAR:
//  1. No Xcode, abra este arquivo e rode os #Preview do rodapé: há cenários
//     claros e escuros para 3, 7, 14 e 30 dias.
//  2. Para validar ao vivo no simulador/dispositivo, apresente esta view de
//     qualquer tela, por exemplo: .sheet { VenusStreakMockView() }
//     (ou NavigationLink { VenusStreakMockView() } label: { ... }).
//  3. Toque nos pills 3 / 7 / 14 / 30 para alternar o cenário em tempo real;
//     toque no CTA escuro para disparar a micro-celebração novamente.
//
//  Arquivo somente de teste: dados 100% mockados, sem repositórios, SwiftData,
//  lógica de produção ou referência a ViewModels. Não é usado pelo app.
//

import SwiftUI
import UIKit

// MARK: - Mock-up de streaks

struct VenusStreakMockView: View {
    @State private var selectedDays: Int
    @State private var isCelebrating = false
    @State private var celebrationTick = 0

    init(initialDays: Int = 7) {
        _selectedDays = State(initialValue: Self.normalize(initialDays))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VenusJourneyBackground(palette: palette)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header

                        mascotStage

                        VenusJourneyProgress(
                            currentStep: selectedIndex + 1,
                            totalSteps: MockStreakScenario.all.count,
                            tint: scenario.tint,
                            caption: "MARCO \(selectedIndex + 1) DE \(MockStreakScenario.all.count)"
                        )
                        .frame(maxWidth: 320)

                        Text(scenario.phrase)
                            .font(.system(size: 17, weight: .light, design: .rounded))
                            .foregroundStyle(VenusTheme.text)
                            .multilineTextAlignment(.center)
                            .contentTransition(.opacity)

                        Spacer(minLength: 4)

                        celebrateButton

                        scenarioPicker
                    }
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                }
            }
        }
        .onChange(of: selectedDays) { _, _ in
            triggerCelebration()
        }
    }

    // MARK: - Cabeçalho

    private var header: some View {
        VStack(spacing: 8) {
            Text("PRÉVIA DE STREAK")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .kerning(1.6)
                .foregroundStyle(scenario.tint)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(scenario.days)")
                    .font(.system(size: 68, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.text)

                Text("dias")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
            .contentTransition(.opacity)
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selectedDays)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Streak simulado de \(scenario.days) dias")
    }

    // MARK: - Venus com cosmético do marco

    private var mascotStage: some View {
        ZStack {
            VenusMoodOrb(
                mood: .happy,
                state: .celebrating,
                expression: .celebrating,
                cosmetic: scenario.cosmetic,
                size: 210,
                isInteractive: false
            )
            .id(scenario.days)
            .scaleEffect(isCelebrating ? 1.04 : 1)
            .animation(.spring(response: 0.42, dampingFraction: 0.62), value: isCelebrating)

            if isCelebrating {
                MockStreakBurst(tint: scenario.tint)
                    .id(celebrationTick)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 232)
    }

    // MARK: - CTA escuro em pill

    private var celebrateButton: some View {
        Button {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            triggerCelebration()
        } label: {
            VenusJourneyPrimaryButtonLabel(title: "Celebrar marco", systemImage: "sparkles")
        }
        .buttonStyle(VenusJourneyPressableStyle())
        .accessibilityLabel("Celebrar marco de \(scenario.days) dias")
    }

    // MARK: - Seletor ao vivo

    private var scenarioPicker: some View {
        HStack(spacing: 10) {
            ForEach(MockStreakScenario.all) { option in
                let isSelected = option.days == selectedDays

                Button {
                    guard !isSelected else { return }
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        selectedDays = option.days
                    }
                } label: {
                    Text("\(option.days)")
                        .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white : VenusTheme.text)
                        .frame(width: 52, height: 42)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isSelected ? option.tint : Color.clear)
                        )
                        .glassEffect(
                            isSelected ? .clear : .regular.interactive(),
                            in: Capsule(style: .continuous)
                        )
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Streak de \(option.days) dias")
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Estado derivado (somente mock)

    private var selectedIndex: Int {
        MockStreakScenario.all.firstIndex { $0.days == selectedDays } ?? 0
    }

    private var scenario: MockStreakScenario {
        MockStreakScenario.all[selectedIndex]
    }

    private var palette: VenusJourneyPalette {
        VenusJourneyPalette(
            accent: scenario.tint,
            secondary: VenusJourneyPalette.rose,
            tertiary: VenusJourneyPalette.sky,
            moods: [.happy, .calm, .energetic]
        )
    }

    private static func normalize(_ days: Int) -> Int {
        MockStreakScenario.all.contains { $0.days == days } ? days : 7
    }

    @MainActor
    private func triggerCelebration() {
        celebrationTick += 1
        let token = celebrationTick

        withAnimation(.spring(response: 0.38, dampingFraction: 0.6)) {
            isCelebrating = true
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            guard celebrationTick == token else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                isCelebrating = false
            }
        }
    }
}

// MARK: - Cenários mockados

private struct MockStreakScenario: Identifiable {
    let days: Int
    let cosmetic: VenusCosmeticItem
    let phrase: String
    let tint: Color

    var id: Int { days }

    static let all: [MockStreakScenario] = [
        MockStreakScenario(
            days: 3,
            cosmetic: .starHalo,
            phrase: "Três dias. Um começo que já brilha.",
            tint: VenusJourneyPalette.lilac
        ),
        MockStreakScenario(
            days: 7,
            cosmetic: .astralWings,
            phrase: "Uma semana inteira ao seu lado.",
            tint: VenusJourneyPalette.rose
        ),
        MockStreakScenario(
            days: 14,
            cosmetic: .cosmicHeadphones,
            phrase: "Duas semanas de cuidado, sem pressa.",
            tint: VenusJourneyPalette.sky
        ),
        MockStreakScenario(
            days: 30,
            cosmetic: .saturnRing,
            phrase: "Um mês em órbita. A Venus sente.",
            tint: VenusJourneyPalette.lilac
        )
    ]
}

// MARK: - Micro-celebração

private struct MockStreakBurst: View {
    let tint: Color

    @State private var exploded = false

    private let particleCount = 10

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                let angle = Double(index) * (360.0 / Double(particleCount))
                let distance: CGFloat = index.isMultiple(of: 2) ? 88 : 66
                let size: CGFloat = index.isMultiple(of: 3) ? 6 : 4

                Circle()
                    .fill(index.isMultiple(of: 3) ? tint : Color.white)
                    .frame(width: size, height: size)
                    .shadow(color: tint.opacity(0.5), radius: 4)
                    .offset(
                        x: exploded ? CGFloat(cos(angle * .pi / 180)) * distance : 0,
                        y: exploded ? CGFloat(sin(angle * .pi / 180)) * distance : 0
                    )
                    .opacity(exploded ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 0.85).delay(Double(index) * 0.012),
                        value: exploded
                    )
            }
        }
        .onAppear { exploded = true }
    }
}

// MARK: - Previews (todos os cenários, claro e escuro)

#Preview("Mock streak · 3 dias · claro") {
    VenusStreakMockView(initialDays: 3)
        .environment(\.colorScheme, .light)
}

#Preview("Mock streak · 7 dias · claro") {
    VenusStreakMockView(initialDays: 7)
        .environment(\.colorScheme, .light)
}

#Preview("Mock streak · 14 dias · escuro") {
    VenusStreakMockView(initialDays: 14)
        .environment(\.colorScheme, .dark)
}

#Preview("Mock streak · 30 dias · escuro") {
    VenusStreakMockView(initialDays: 30)
        .environment(\.colorScheme, .dark)
}
