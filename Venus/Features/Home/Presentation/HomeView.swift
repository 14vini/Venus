//
//  HomeView.swift
//  Venus
//
//  Home na linguagem visual da jornada: fundo lilás → rosa → branco com respiração lenta,
//  arco de progresso dos 3 rituais, número em vez de parágrafos, vidro sutil e CTA escuro.
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
    // A9: sinal persistente de conversa de hoje, sem mexer no ViewModel.
    @AppStorage("venus.lastChatDay") private var lastChatDay: Double = 0

    var body: some View {
        ZStack {
            // Fundo da jornada, com respiração lenta e tons profundos no dark mode.
            VenusHomeJourneyBackground()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // A3/A9: progresso honesto dos 3 rituais do dia.
                        VenusDailyRitualsView(
                            checkInDone: viewModel.hasCheckedInToday,
                            planBlockDone: (viewModel.todayPlan?.completedBlocksCount ?? 0) > 0,
                            chatDone: hasChattedToday
                        )
                        .padding(.top, 12)

                        heroTypographySection
                            .padding(.top, 26)

                        // A4: saudação da IA em linha curta com ícone, sem parágrafo.
                        modeSubtitle
                            .padding(.top, 14)

                        mascotStage
                            .padding(.top, 6)

                        readinessPill
                            .padding(.top, 10)

                        patternInsightLine
                            .padding(.top, 8)

                        modeSelectorPills
                            .padding(.top, 22)

                        Spacer(minLength: 28)

                        actionButton
                            .padding(.bottom, 36)
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

            ToolbarItem(placement: .principal) {
                Text("Venus")
                    .font(.system(size: 16, weight: .light, design: .rounded))
                    .kerning(1.6)
                    .foregroundStyle(VenusTheme.text)
            }

            ToolbarItem(placement: .topBarTrailing) {
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

    // MARK: - Reflexo do padrão calculado pela IA (linha única, não parágrafo)

    private var patternInsightLine: some View {
        Group {
            if let snapshot = viewModel.patternSnapshot {
                HStack(spacing: 8) {
                    Image(systemName: snapshot.weeklyTrend.direction.iconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(VenusHomeJourneyPalette.lilac)

                    Text("\(snapshot.weeklyTrend.direction.title) · \(snapshot.nextBestAction.title)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .foregroundStyle(VenusTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: Capsule(style: .continuous))
                .contentTransition(.opacity)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(minHeight: 32)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.45), value: viewModel.patternSnapshot)
    }

    // MARK: - Mascote Hero (Venus em código, com cosmético do streak real)

    private var mascotStage: some View {
        VStack(spacing: 0) {
            ZStack {
                RadialGradient(
                    colors: [
                        selectedMode.activeAuraColor.opacity(colorScheme == .dark ? 0.26 : 0.52),
                        VenusHomeJourneyPalette.rose.opacity(colorScheme == .dark ? 0.10 : 0.20),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 15,
                    endRadius: 118
                )
                .frame(width: 236, height: 236)
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

            // Streak real sempre visível (milestones exibem confete/feedback).
            if viewModel.checkInStreakDays > 0 {
                StreakBadge(days: viewModel.checkInStreakDays, celebrated: true)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.48))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.80), lineWidth: 1)
                            )
                    )
                    .padding(.top, 2)
            }
        }
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

    // MARK: - Prontidão em número + anel (toque abre detalhes completos)

    private var readinessPill: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.showReadinessBreakdown = true
        } label: {
            HStack(spacing: 12) {
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
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(viewModel.readinessAssessment.percentage100)")
                            .font(.system(size: 24, weight: .light, design: .rounded))
                            .contentTransition(.numericText())

                        Text("%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }

                    Text(shortStateTitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(VenusTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(minHeight: 56)
            .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
        }
        .buttonStyle(VenusHomePressableButtonStyle())
        .accessibilityLabel("Prontidão \(viewModel.readinessAssessment.percentage100)%, \(shortStateTitle)")
    }

    private var readinessFraction: CGFloat {
        let value = Double(viewModel.readinessAssessment.percentage100) / 100
        return CGFloat(min(max(value, 0), 1))
    }

    private var shortStateTitle: String {
        let title = viewModel.readinessAssessment.stateTitle
        if title.hasPrefix("Prontidão ") {
            return String(title.dropFirst("Prontidão ".count))
        }
        return title
    }

    // MARK: - Tipografia Hero (fina, com negrito seletivo no rótulo do modo)

    private var heroTypographySection: some View {
        VStack(spacing: 6) {
            Text(selectedMode.titleFirst)
                .font(.system(size: 32, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .contentTransition(.opacity)

            Text(selectedMode.titleSecond.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(VenusHomeJourneyPalette.lilac)
                .contentTransition(.opacity)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: selectedMode)
    }

    // MARK: - Saudação da IA (A4) quando chega, senão rótulo curto do modo

    private var modeSubtitle: some View {
        Group {
            if let greeting = viewModel.aiGreeting,
               !greeting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(VenusHomeJourneyPalette.lilac)
                        .padding(.top, 2)

                    Text(greeting)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityLabel("Saudação da Venus: \(greeting)")
            } else {
                HStack(spacing: 6) {
                    Image(systemName: selectedMode.iconSystemName)
                        .font(.system(size: 11, weight: .semibold))

                    Text(selectedMode.label.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.4)
                }
                .foregroundStyle(VenusTheme.textSecondary.opacity(0.78))
                .contentTransition(.opacity)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedMode)
            }
        }
        .padding(.horizontal, 32)
        .frame(minHeight: 34, alignment: .top)
        .animation(.easeInOut(duration: 0.5), value: viewModel.aiGreeting)
    }

    // MARK: - Seletor de modos: ícones em vidro, rótulo fica no hero

    private var modeSelectorPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VenusWellnessMode.allCases) { mode in
                    let isSelected = selectedMode == mode
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                            selectedMode = mode
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    isSelected
                                        ? (colorScheme == .dark ? Color.white : Color(hex: "241E2B"))
                                        : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.48)
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: mode.iconSystemName)
                                .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                                .foregroundStyle(
                                    isSelected
                                        ? (colorScheme == .dark ? Color.black : Color.white)
                                        : VenusTheme.textSecondary
                                )
                        }
                        .glassEffect(
                            isSelected ? .clear : .regular.interactive(),
                            in: Circle()
                        )
                    }
                    .buttonStyle(VenusHomePressableButtonStyle())
                    .accessibilityLabel(mode.label)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Ação Principal (CTA escuro em pill)

    private var actionButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.checkInButtonTapped()
        } label: {
            VenusHomeCTALabel(
                title: viewModel.hasCheckedInToday ? "Registrar novo momento" : "Fazer check-in de hoje",
                systemImage: "arrow.right"
            )
        }
        .buttonStyle(VenusHomePressableButtonStyle())
        .padding(.horizontal, 24)
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
