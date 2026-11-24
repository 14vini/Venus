//
//  HomeView.swift
//  Venus
//
//  Home na linguagem visual da jornada: fundo lilás → rosa → branco com respiração lenta,
//  arco dos 3 rituais, Venus central, saudação curta, prontidão em pill e CTA escuro.
//  Quatro blocos visíveis; o resto segue acessível no toolbar e nas sheets.
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
            // Fundo da jornada, com respiração lenta e tons profundos no dark mode.
            VenusHomeJourneyBackground()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // (a) progresso dos 3 rituais com arco e micro-burst (A9).
                        VenusDailyRitualsView(
                            checkInDone: viewModel.hasCheckedInToday,
                            planBlockDone: (viewModel.todayPlan?.completedBlocksCount ?? 0) > 0,
                            chatDone: hasChattedToday
                        )
                        .padding(.top, 12)

                        // (b) Venus central + saudação curta (A4) + streak real (A3).
                        venusSection
                            .padding(.top, 24)

                        // (c) prontidão em pill; o toque abre o detalhamento.
                        readinessPill
                            .padding(.top, 20)

                        Spacer(minLength: 28)

                        // (d) única ação principal.
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
                HStack(spacing: 14) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isJourneyDetailsPresented = true
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }
                    .accessibilityLabel("Modo e padrões da semana")

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
        // Acesso secundário: modo de bem-estar e padrão da IA saem da hierarquia principal.
        .sheet(isPresented: $isJourneyDetailsPresented) {
            VenusHomeJourneyDetailsSheet(
                selectedMode: $selectedMode,
                patternSnapshot: viewModel.patternSnapshot
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

    // MARK: - Bloco (b): Venus em código + saudação curta + streak real

    private var venusSection: some View {
        VStack(spacing: 4) {
            mascotStage

            greetingText
                .padding(.horizontal, 32)

            // A3: streak calculado com o histórico completo; marcos mantêm confete.
            if viewModel.checkInStreakDays > 0 {
                StreakBadge(days: viewModel.checkInStreakDays, celebrated: true)
                    .frame(minHeight: 40)
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: viewModel.checkInStreakDays)
            }
        }
    }

    /// A4: saudação da IA em tipografia fina; sem cartão, sem parágrafo e sem rótulo duplicado.
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
                Text(selectedMode.label)
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .contentTransition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .top)
        .animation(.easeInOut(duration: 0.45), value: viewModel.aiGreeting)
    }

    private var mascotStage: some View {
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

// MARK: - Acesso secundário (um toque): modos de bem-estar + padrão calculado pela IA

/// Tira da Home o seletor de modos e o insight de padrão sem remover a função:
/// o botão de estrelas no toolbar abre esta sheet em um toque.
private struct VenusHomeJourneyDetailsSheet: View {
    @Binding var selectedMode: VenusWellnessMode
    let patternSnapshot: PatternInsightsSnapshot?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    modeSection

                    if let patternSnapshot {
                        patternSection(patternSnapshot)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
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
