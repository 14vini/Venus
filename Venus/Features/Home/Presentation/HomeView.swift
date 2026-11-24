//
//  HomeView.swift
//  Venus
//
//  Home com hierarquia única: fundo sóbrio, progresso dos 3 rituais (arco/pontos),
//  Venus central com saudação curta (A4) e um CTA circular em Liquid Glass.
//  Streak (A3), prontidão, modos e padrão ficam na sheet secundária (um toque).
//  Mascote, navegação e ações permanecem intactas.
//

import SwiftUI

struct HomeView: View {
    let userName: String
    @Bindable var viewModel: HomeViewModel
    @Bindable var inlineCheckInViewModel: MoodCheckInViewModel

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedMode: VenusWellnessMode = .stress
    @State private var isProfilePresented = false
    @State private var isJourneyDetailsPresented = false
    // A9: sinal persistente de conversa de hoje, sem mexer no ViewModel.
    @AppStorage("venus.lastChatDay") private var lastChatDay: Double = 0

    var body: some View {
        ZStack {
            VenusHomeJourneyBackground()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // (a) único progresso do topo: arco e pontos dos 3 rituais (A9).
                        VenusDailyRitualsView(
                            checkInDone: viewModel.hasCheckedInToday,
                            planBlockDone: (viewModel.todayPlan?.completedBlocksCount ?? 0) > 0,
                            chatDone: hasChattedToday
                        )
                        .padding(.top, 18)

                        // (b) Venus + saudação curta. Sem streak, sem prontidão, sem modos.
                        venusSection
                            .padding(.top, 20)

                        Spacer(minLength: 28)

                        // (c) única ação principal: círculo de vidro com "+".
                        VenusHomeCheckInButton(
                            hasCheckedInToday: viewModel.hasCheckedInToday
                        ) {
                            viewModel.checkInButtonTapped()
                        }
                        .padding(.bottom, 40)
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationTitle("Venus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.showChatHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(VenusTheme.textSecondary)
                }
                .accessibilityLabel("Histórico de conversas")
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isJourneyDetailsPresented = true
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }
                    .accessibilityLabel("Sequência, prontidão, modo e padrões")

                    Button {
                        isProfilePresented = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }
                    .accessibilityLabel("Perfil")
                }
            }
        }
        // MARK: - Modais e Sheets
        .fullScreenCover(isPresented: $viewModel.showMoodCheckIn, onDismiss: {
            inlineCheckInViewModel.startNewCheckIn()
            viewModel.onMoodCheckInDismissed()
        }) {
            MoodCheckInView(
                viewModel: inlineCheckInViewModel,
                ritualProgressLabel: viewModel.ritualProgressLabel
            )
        }
        .sheet(isPresented: $viewModel.showMyDay, onDismiss: {
            viewModel.onAppear()
        }) {
            MyDayView()
        }
        .sheet(isPresented: $viewModel.showReadinessBreakdown) {
            ReadinessBreakdownSheet(
                assessment: viewModel.readinessAssessment
            )
        }
        .sheet(isPresented: $viewModel.showEmotionalGalaxy) {
            EmotionalGalaxyView(
                userName: userName,
                weekMoods: viewModel.weekMoods,
                weeklyTrend: viewModel.weeklyTrend,
                readinessAssessment: viewModel.readinessAssessment
            )
        }
        .sheet(isPresented: $isProfilePresented) {
            NavigationStack {
                ProfileView()
            }
        }
        // Acesso secundário: streak, prontidão, modo e padrão saem da hierarquia principal.
        .sheet(isPresented: $isJourneyDetailsPresented) {
            VenusHomeJourneyDetailsSheet(
                selectedMode: $selectedMode,
                patternSnapshot: viewModel.patternSnapshot,
                streakDays: viewModel.checkInStreakDays,
                cosmetic: viewModel.unlockedCosmetic,
                readinessPercentage: viewModel.readinessAssessment.percentage100,
                readinessStateTitle: shortStateTitle,
                onOpenReadiness: { viewModel.showReadinessBreakdown = true }
            )
        }
        .fullScreenCover(isPresented: $viewModel.showVenusChat, onDismiss: {
            viewModel.selectedChatSession = nil
            markChatToday()
        }) {
            VenusChatView(session: viewModel.selectedChatSession)
        }
        .sheet(isPresented: $viewModel.showChatHistory) {
            NavigationStack {
                ChatHistoryView(
                    onSelectSession: { session in
                        viewModel.selectedChatSession = session
                        viewModel.showChatHistory = false
                        viewModel.showVenusChat = true
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showUpgradePrompt) {
            PremiumUpgradeSheet(
                freeDailyLimit: viewModel.freePlanDailyLimit,
                onDismiss: { viewModel.showUpgradePrompt = false },
                onSeePlans: {
                    viewModel.showUpgradePrompt = false
                    viewModel.showVenusProPlans = true
                }
            )
        }
        .sheet(isPresented: $viewModel.showVenusProPlans) {
            VenusProPlansSheet(
                freeDailyLimit: viewModel.freePlanDailyLimit,
                onContinueToSupport: { viewModel.showVenusProPlans = false }
            )
        }
    }

    // MARK: - Sinais derivados (sem estado novo no ViewModel)

    private var hasChattedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return abs(lastChatDay - today) < 60
    }

    private func markChatToday() {
        lastChatDay = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    }

    private var shortStateTitle: String {
        let title = viewModel.readinessAssessment.stateTitle
        if title.hasPrefix("Prontidão ") {
            return String(title.dropFirst("Prontidão ".count))
        }
        return title
    }

    // MARK: - Venus + saudação curta (A4)

    private var venusSection: some View {
        VStack(spacing: 6) {
            mascotStage

            greetingText
                .padding(.horizontal, 32)
        }
    }

    /// A4: saudação da IA em tipografia fina; sem cartão, sem rótulo de modo e sem parágrafo.
    private var greetingText: some View {
        Group {
            if let greeting = viewModel.aiGreeting,
               !greeting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(VenusHomeJourneyPalette.lilac)

                    Text(greeting)
                        .font(.system(size: 15, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .contentTransition(.opacity)
                }
                .accessibilityLabel("Saudação da Venus: \(greeting)")
            } else {
                // Saudação curta de reserva: nenhum rótulo de modo compete no topo.
                Text("Olá, \(userName)")
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .contentTransition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .top)
        .animation(.easeInOut(duration: 0.45), value: viewModel.aiGreeting)
    }

    private var mascotStage: some View {
        ZStack {
            RadialGradient(
                colors: [
                    selectedMode.activeAuraColor.opacity(colorScheme == .dark ? 0.20 : 0.36),
                    VenusHomeJourneyPalette.rose.opacity(colorScheme == .dark ? 0.06 : 0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 15,
                endRadius: 110
            )
            .frame(width: 220, height: 220)
            .blur(radius: 18)
            .animation(.easeInOut(duration: 0.5), value: selectedMode)

            VenusMoodOrb(
                mood: effectiveMood,
                state: mascotState,
                cosmetic: viewModel.unlockedCosmetic,
                size: 136,
                showFace: true,
                showHands: true,
                showShadow: false,
                isInteractive: true
            )
            .frame(width: 136, height: 136)
        }
        .frame(height: 158)
        .accessibilityLabel("Mascote Venus")
    }

    private var effectiveMood: MoodType {
        if let checkInMood = viewModel.todayMoodType {
            return checkInMood
        }
        return selectedMode.associatedMood
    }

    private var mascotState: VenusMascotState {
        if viewModel.isHomeLoading { return .thinking }
        if viewModel.hasCheckedInToday { return .celebrating }
        return .welcoming
    }
}

#Preview {
    HomeView(
        userName: "Kauã",
        viewModel: HomeViewModel(
            patternEngineUseCase: DependencyContainer.shared.makePatternEngineUseCase(),
            checkInAllowanceUseCase: DependencyContainer.shared.makeCheckInAllowanceUseCase(),
            moodRepository: DependencyContainer.shared.makeMoodRepository()
        ),
        inlineCheckInViewModel: DependencyContainer.shared.makeMoodCheckInViewModel()
    )
}
