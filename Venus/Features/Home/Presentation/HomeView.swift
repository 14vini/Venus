//
//  HomeView.swift
//  Venus
//
//  Refactored by Kaua on 18/03/26.
//

import SwiftUI

struct HomeView: View {
    let userName: String
    @Bindable var viewModel: HomeViewModel
    @Bindable var inlineCheckInViewModel: MoodCheckInViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VenusReadingBackground(dayMoment: viewModel.dayMoment, isAnimated: true)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    
                    // Readiness & Energy Gauge (0-100) - Mantido com seu estilo exclusivo original
                    ReadinessEnergyGaugeView(
                        assessment: viewModel.readinessAssessment,
                        onDetailTap: {
                            viewModel.showReadinessBreakdown = true
                        }
                    )
                    
                    // Hero Mascot Host (Card Neumórfico Monocromático)
                    HomeHeroMascotView(
                        userName: userName,
                        dayMoment: viewModel.dayMoment,
                        streakDays: viewModel.checkInStreakDays,
                        todayMood: viewModel.todayMoodType,
                        hasCheckedInToday: viewModel.hasCheckedInToday,
                        customAIGreeting: viewModel.aiGreeting,
                        onCheckInTap: {
                            viewModel.checkInButtonTapped()
                        },
                        onChatTap: {
                            viewModel.showVenusChat = true
                        }
                    )
                    .padding(.top, 2)

                    // Curva Intradiária de Energia Circadiana (Card Neumórfico)
                    IntradayEnergyCurveView(
                        curve: viewModel.readinessAssessment.breakdown?.intradayCurve ?? .sampleDefault,
                        baseScore: viewModel.readinessAssessment.score,
                        onDetailTap: {
                            viewModel.showReadinessBreakdown = true
                        }
                    )
                    
                    // Galaxy & Venus Wrap Banner Card (Card Neumórfico)
                    HomeGalaxyBannerCard(
                        checkInCount: viewModel.weekMoods.count,
                        onOpenGalaxy: {
                            viewModel.showEmotionalGalaxy = true
                        },
                        onOpenWrap: {
                            viewModel.showVenusWrap = true
                        }
                    )

                    // "Sobre você:" (Trend summary - Card Neumórfico)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sobre você:")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.textSecondary)
                            .textCase(.uppercase)

                        Text(viewModel.weeklyTrend?.summary ?? "Analisando seus dados iniciais para desenhar seu reflexo emocional. Continue registrando seus check-ins com Venus.")
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.text)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                    .neumorphicCard(cornerRadius: 26, style: .raised, depth: 7)
                    .padding(.bottom, 120)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Olá, \(userName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.showChatHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(VenusTheme.text)
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.showEmotionalGalaxy = true
                } label: {
                    Image(systemName: "sparkles.rectangle.stack")
                        .foregroundStyle(VenusTheme.text)
                }
                
                Button {
                    viewModel.showVenusChat = true
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(VenusTheme.text)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showMoodCheckIn, onDismiss: {
            inlineCheckInViewModel.startNewCheckIn()
            viewModel.onMoodCheckInDismissed()
        }) {
            MoodCheckInView(
                viewModel: inlineCheckInViewModel,
                ritualProgressLabel: viewModel.ritualProgressLabel
            )
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
        .sheet(isPresented: $viewModel.showVenusWrap) {
            VenusWrapStoryView(
                userName: userName,
                weekMoods: viewModel.weekMoods,
                weeklyTrend: viewModel.weeklyTrend,
                readinessAssessment: viewModel.readinessAssessment,
                onDismiss: {
                    viewModel.showVenusWrap = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showVenusChat) {
            NavigationStack {
                VenusChatView()
            }
        }
        .sheet(isPresented: $viewModel.showChatHistory) {
            NavigationStack {
                ChatHistoryView(
                    onSelectSession: { session in
                        viewModel.showChatHistory = false
                        viewModel.showVenusChat = true
                    }
                )
            }
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
