//
//  HomeView.swift
//  Venus
//
//  Home adaptada fielmente ao design etéreo e minimalista com seixos
//  translúcidos de regulação do sistema nervoso (Stress, Sleep, Burnout,
//  Meditation, Rest, Anxiety), tipografia hero e fundo atmosférico.
//

import SwiftUI

struct HomeView: View {
    let userName: String
    @Bindable var viewModel: HomeViewModel
    @Bindable var inlineCheckInViewModel: MoodCheckInViewModel

    @State private var selectedMode: VenusWellnessMode = .stress
    @State private var selectedTier: VenusAppTier = .premium
    @State private var isProfilePresented = false
    @State private var showQuickNavigationMenu = false

    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let isCompact = screenHeight < 720

            ZStack(alignment: .top) {
                // 1. Fundo etéreo com silhueta porcelana, iluminação de spa e névoa azul
                VenusHomeEtherealBackgroundView(activeAuraColor: selectedMode.activeAuraColor)

                // 2. Conteúdo Principal
                VStack(spacing: 0) {
                    // Barra Superior: Logo Ondulatório à esquerda + Cápsula [Basic | Premium] à direita
                    topBar
                        .padding(.horizontal, 24)
                        .padding(.top, max(geo.safeAreaInsets.top, 12))

                    ScrollView(showsIndicators: false) {
                        mainContent(isCompact: isCompact)
                            .frame(maxWidth: .infinity)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
                .frame(width: geo.size.width)
            }
            .ignoresSafeArea(edges: .all)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        // MARK: - Modais e Navegações da Venus
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
                onDismiss: {
                    viewModel.showUpgradePrompt = false
                },
                onSeePlans: {
                    viewModel.showUpgradePrompt = false
                    viewModel.showVenusProPlans = true
                }
            )
        }
        .sheet(isPresented: $viewModel.showVenusProPlans) {
            VenusProPlansSheet(
                freeDailyLimit: viewModel.freePlanDailyLimit,
                onContinueToSupport: {
                    viewModel.showVenusProPlans = false
                }
            )
        }
        .confirmationDialog("Menu Venus", isPresented: $showQuickNavigationMenu, titleVisibility: .visible) {
            Button("Prontidão & Bateria Corporal") {
                viewModel.showReadinessBreakdown = true
            }
            Button("Conversar com a Venus") {
                viewModel.selectedChatSession = nil
                viewModel.showVenusChat = true
            }
            Button("Meu Dia & Agenda") {
                viewModel.showMyDay = true
            }
            Button("Galaxy Emocional") {
                viewModel.showEmotionalGalaxy = true
            }
            Button("Histórico de Conversas") {
                viewModel.showChatHistory = true
            }
            Button("Meu Perfil & Preferências") {
                isProfilePresented = true
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Barra Superior Fiel ao Screenshot

    private var topBar: some View {
        HStack(alignment: .center) {
            // Logo fluido concêntrico à esquerda
            VenusWaveLogoView(size: 34) {
                showQuickNavigationMenu = true
            }

            Spacer()

            // Toggle cápsula de vidro [ Basic | Premium ] à direita
            VenusTierToggleView(selectedTier: $selectedTier) {
                viewModel.showVenusProPlans = true
            }
        }
    }

    // MARK: - Conteúdo Central e Inferior

    @ViewBuilder
    private func mainContent(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: isCompact ? 10 : 20)

            // Cluster Radial de Seixos de Vidro Fosco (Stress, Sleep, etc.)
            VenusRadialClusterView(selectedMode: $selectedMode) { mode in
                // Sincroniza o humor sugerido com o motor da Venus
                viewModel.checkInPrefilledMood = mode.associatedMood
            }
            .scaleEffect(isCompact ? 0.90 : 1.0)

            Spacer(minLength: isCompact ? 14 : 32)

            // Seção Inferior: Tipografia Hero + CTA de Ativação + Status de Prontidão
            VenusHomeBottomSectionView(
                mode: selectedMode,
                assessment: viewModel.readinessAssessment,
                onStartMode: {
                    startModeSession(for: selectedMode)
                },
                onReadinessTap: {
                    viewModel.showReadinessBreakdown = true
                },
                onCheckInTap: {
                    viewModel.checkInPrefilledMood = selectedMode.associatedMood
                    inlineCheckInViewModel.startNewCheckIn(prefilledMood: selectedMode.associatedMood)
                    viewModel.showMoodCheckIn = true
                },
                onGalaxyTap: {
                    viewModel.showEmotionalGalaxy = true
                }
            )
            .padding(.bottom, 84)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Iniciar Sessão do Modo

    private func startModeSession(for mode: VenusWellnessMode) {
        viewModel.selectedChatSession = nil
        viewModel.showVenusChat = true
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
