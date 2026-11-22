//
//  HomeView.swift
//  Venus
//
//  Home adaptada ao estilo da tela de passo a passo (Onboarding / Jornada):
//  Fundo suave pastel lilás/rosa/céu com gradiente animado, arco de progresso
//  ("Cada passo que você dá importa"), mascote oficial Venus com rosto expressivo,
//  tipografia arredondada acolhedora e botões de ação em dark pill.
//

import SwiftUI

struct HomeView: View {
    let userName: String
    @Bindable var viewModel: HomeViewModel
    @Bindable var inlineCheckInViewModel: MoodCheckInViewModel

    @Environment(\.colorScheme) private var colorScheme
    @State private var isProfilePresented = false

    var body: some View {
        ZStack {
            // 1. Fundo animado no estilo da jornada/passo a passo (lilás -> rosa -> azul)
            OnboardingAnimatedBackground(palette: .forStep(0), isAnimated: true)

            // 2. Conteúdo em ScrollView suave
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Cabeçalho de jornada: "Esta é sua jornada" / "Cada passo que você dá importa." + arco com pontos
                    journeyHeader
                        .padding(.top, 8)

                    Spacer(minLength: 12)

                    // Mascote Oficial Venus em código, flutuando e expressivo
                    mascotStage
                        .padding(.top, 8)

                    // Tipografia Hero: Pontuação de Prontidão + Rótulo em caixa alta
                    typographySection
                        .padding(.top, 16)

                    // Frase de acolhimento e ritmo: "Venus foi feita para caminhar com você..."
                    rhythmQuote
                        .padding(.top, 12)

                    // Miniaturas de humores recentes
                    if !recentMoodEmojis.isEmpty {
                        recentMiniatures
                            .padding(.top, 14)
                    }

                    Spacer(minLength: 20)

                    // Ações principais: Botão CTA em Dark Pill + Botão Conversar
                    actionButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Venus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                VenusHomeToolbarLeading(
                    onHistoryTap: { viewModel.showChatHistory = true },
                    onMyDayTap: { viewModel.showMyDay = true }
                )
            }

            ToolbarItem(placement: .principal) {
                Text("Venus")
                    .font(.system(size: 16, weight: .light, design: .rounded))
                    .kerning(1.4)
                    .foregroundStyle(VenusTheme.text)
            }

            ToolbarItem(placement: .topBarTrailing) {
                VenusHomeToolbarTrailing(
                    userName: userName,
                    onGalaxyTap: { viewModel.showEmotionalGalaxy = true },
                    onChatTap: { viewModel.showVenusChat = true },
                    onProfileTap: { isProfilePresented = true }
                )
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

    // MARK: - Cabeçalho de Jornada

    private var journeyHeader: some View {
        OnboardingJourneyHeader(
            currentStep: journeyStepIndex,
            totalSteps: 6,
            tint: OnboardingVisualPalette.lilac
        )
        .padding(.horizontal, 28)
    }

    private var journeyStepIndex: Int {
        // Progresso diário baseado nos check-ins do dia
        min(max(viewModel.checkInsUsedToday, viewModel.hasCheckedInToday ? 1 : 0), 5)
    }

    // MARK: - Mascote Hero

    private var mascotStage: some View {
        ZStack {
            // Aura suave difusa em lilás/rosa
            RadialGradient(
                colors: [
                    Color(hex: "E7D8F5").opacity(colorScheme == .dark ? 0.22 : 0.54),
                    Color(hex: "F3C9DC").opacity(colorScheme == .dark ? 0.10 : 0.26),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 130
            )
            .frame(width: 260, height: 260)
            .blur(radius: 16)

            // Mascote Oficial Venus em código, com olhos, boca, mãos e animação de flutuação
            VenusMoodOrb(
                mood: viewModel.todayMoodType ?? .happy,
                state: mascotState,
                size: 148,
                showFace: true,
                showHands: true,
                showShadow: false,
                isInteractive: true
            )
            .frame(width: 148, height: 148)
        }
        .frame(height: 205)
        .accessibilityLabel("Mascote Venus")
    }

    private var mascotState: VenusMascotState {
        if viewModel.isHomeLoading { return .thinking }
        if viewModel.hasCheckedInToday { return .celebrating }
        return .welcoming
    }

    // MARK: - Tipografia Hero

    private var typographySection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(viewModel.readinessAssessment.percentage100)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .contentTransition(.numericText())

                Text("%")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
            .accessibilityLabel("Prontidão \(viewModel.readinessAssessment.percentage100) por cento")

            Text(viewModel.readinessAssessment.stateTitle.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(OnboardingVisualPalette.lilac)
                .tracking(1.8)
        }
    }

    // MARK: - Frase de Ritmo

    private var rhythmQuote: some View {
        Text("Venus foi feita para caminhar com você.\nUm passo de cada vez, no seu ritmo.")
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundStyle(VenusTheme.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 36)
    }

    // MARK: - Miniaturas de Humor Recente

    private var recentMiniatures: some View {
        HStack(spacing: 8) {
            ForEach(0..<min(recentMoodEmojis.count, 3), id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.70))
                        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)

                    Text(recentMoodEmojis[index])
                        .font(.system(size: 14))
                }
                .frame(width: 32, height: 32)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Ações Principais (Estilo Dark Pill da Jornada)

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Botão Principal em Dark Pill (idêntico ao botão Começar/Avançar da jornada)
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.checkInButtonTapped()
            } label: {
                OnboardingJourneyCTALabel(
                    title: viewModel.hasCheckedInToday ? "Registrar novo momento" : "Fazer check-in de hoje",
                    systemImage: "arrow.right"
                )
            }
            .buttonStyle(OnboardingPressableButtonStyle())

            // Botão Secundário: Conversar com a Venus
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.showVenusChat = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Conversar com a Venus")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(VenusTheme.text)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.65))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.80), lineWidth: 1)
                        )
                )
                .contentShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)

            // Link sutil: Ver detalhes da prontidão
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.showReadinessBreakdown = true
            } label: {
                HStack(spacing: 6) {
                    Text("Ver detalhes da prontidão")
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(VenusTheme.textSecondary)
                .padding(.top, 4)
            }
            .buttonStyle(.plain)
        }
    }

    /// Três humores mais recentes
    private var recentMoodEmojis: [String] {
        Array(viewModel.weekMoods.suffix(3).reversed().map { $0.type.emoji })
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
