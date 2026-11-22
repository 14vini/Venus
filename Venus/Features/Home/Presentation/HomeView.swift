//
//  HomeView.swift
//  Venus
//
//  Home minimalista, limpa e acolhedora no estilo da tela de passo a passo (Jornada):
//  Fundo pastel animado, arco de progresso, mascote oficial Venus com aura viva,
//  tipografia hero com a animação de letras por caracteres (.contentTransition(.numericText()))
//  da home anterior e apenas as informações e ações estritamente necessárias.
//

import SwiftUI

struct HomeView: View {
    let userName: String
    @Bindable var viewModel: HomeViewModel
    @Bindable var inlineCheckInViewModel: MoodCheckInViewModel

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedMode: VenusWellnessMode = .stress
    @State private var isProfilePresented = false

    var body: some View {
        ZStack {
            // 1. Fundo animado no estilo da jornada/passo a passo (lilás -> rosa -> azul)
            OnboardingAnimatedBackground(palette: .forStep(0), isAnimated: true)

            // 2. Conteúdo em ScrollView suave e limpo
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Cabeçalho de jornada com arco sutil e progresso de passos
                    journeyHeader
                        .padding(.top, 6)

                    // Mascote Oficial Venus flutuando com aura adaptativa
                    mascotStage
                        .padding(.top, 4)

                    // Pílula minimalista de Prontidão (toque para abrir detalhes completos)
                    readinessPill
                        .padding(.top, 8)

                    // Tipografia Hero com animação de letras (.contentTransition(.numericText()))
                    heroTypographySection
                        .padding(.top, 14)

                    // Subtítulo descritivo de regulação do sistema nervoso
                    modeSubtitle
                        .padding(.top, 6)

                    // Seletor minimalista de modos de regulação (ativa a animação de letras)
                    modeSelectorPills
                        .padding(.top, 16)

                    Spacer(minLength: 24)

                    // Ação Principal: Botão Dark Pill Único e Focado
                    actionButton
                        .padding(.bottom, 36)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
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
        min(max(viewModel.checkInsUsedToday, viewModel.hasCheckedInToday ? 1 : 0), 5)
    }

    // MARK: - Mascote Hero

    private var mascotStage: some View {
        ZStack {
            // Aura viva difusa que harmoniza com o modo de bem-estar ativo
            RadialGradient(
                colors: [
                    selectedMode.activeAuraColor.opacity(colorScheme == .dark ? 0.28 : 0.58),
                    Color(hex: "F3C9DC").opacity(colorScheme == .dark ? 0.10 : 0.24),
                    Color.clear
                ],
                center: .center,
                startRadius: 15,
                endRadius: 120
            )
            .frame(width: 240, height: 240)
            .blur(radius: 18)
            .animation(.easeInOut(duration: 0.5), value: selectedMode)

            // Mascote Oficial Venus em código, flutuando e expressivo
            VenusMoodOrb(
                mood: effectiveMood,
                state: mascotState,
                size: 136,
                showFace: true,
                showHands: true,
                showShadow: false,
                isInteractive: true
            )
            .frame(width: 136, height: 136)
        }
        .frame(height: 180)
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

    // MARK: - Pílula Minimalista de Prontidão

    private var readinessPill: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.showReadinessBreakdown = true
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "56D2C8"))
                    .frame(width: 7, height: 7)

                HStack(spacing: 2) {
                    Text("\(viewModel.readinessAssessment.percentage100)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(VenusTheme.text)

                Text("·")
                    .foregroundStyle(VenusTheme.textSecondary.opacity(0.6))

                Text(shortStateTitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(VenusTheme.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.65))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.85), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Prontidão \(viewModel.readinessAssessment.percentage100)%, \(shortStateTitle)")
    }

    private var shortStateTitle: String {
        let title = viewModel.readinessAssessment.stateTitle
        if title.hasPrefix("Prontidão ") {
            return String(title.dropFirst("Prontidão ".count))
        }
        return title
    }

    // MARK: - Tipografia Hero com Animação de Letras (.contentTransition(.numericText()))

    private var heroTypographySection: some View {
        VStack(spacing: 2) {
            Text("Start Your \(selectedMode.titleFirst)")
                .font(.system(size: 29, weight: .semibold, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .contentTransition(.numericText())

            Text(selectedMode.titleSecond)
                .font(.system(size: 29, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.textSecondary)
                .contentTransition(.numericText())
        }
        .multilineTextAlignment(.center)
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: selectedMode)
    }

    // MARK: - Subtítulo de Regulação do Sistema Nervoso

    private var modeSubtitle: some View {
        Text(selectedMode.subtitle)
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundStyle(VenusTheme.textSecondary.opacity(0.85))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, 32)
            .contentTransition(.opacity)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedMode)
    }

    // MARK: - Seletor de Modos de Regulação em Vidro Minimalista

    private var modeSelectorPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VenusWellnessMode.allCases) { mode in
                    let isSelected = selectedMode == mode
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                            selectedMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.iconSystemName)
                                .font(.system(size: 11, weight: .semibold))
                            Text(mode.label)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .medium, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(
                            isSelected
                            ? (colorScheme == .dark ? Color.black : Color.white)
                            : VenusTheme.textSecondary
                        )
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    isSelected
                                    ? (colorScheme == .dark ? Color.white : Color(hex: "1F2329"))
                                    : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.60)
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(
                                            isSelected
                                            ? Color.clear
                                            : Color.white.opacity(colorScheme == .dark ? 0.12 : 0.70),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Ação Principal (Dark Pill Único)

    private var actionButton: some View {
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
