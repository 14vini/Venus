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
                VStack(alignment: .leading, spacing: 26) {
                    
                    // Readiness & Energy Gauge (0-100)
                    ReadinessEnergyGaugeView(assessment: viewModel.readinessAssessment)
                    
                    // Hero Mascot Host
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
                    .padding(.top, 4)
                    
                    // Galaxy & Venus Wrap Banner Card
                    HomeGalaxyBannerCard(
                        checkInCount: viewModel.weekMoods.count,
                        onOpenGalaxy: {
                            viewModel.showEmotionalGalaxy = true
                        },
                        onOpenWrap: {
                            viewModel.showVenusWrap = true
                        }
                    )

                    // "Sobre você:" (Trend summary)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sobre você:")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(VenusTheme.primary)
                            .textCase(.uppercase)

                        Text(viewModel.weeklyTrend?.summary ?? "Analisando seus dados iniciais para desenhar seu reflexo emocional. Continue registrando seus check-ins com Venus.")
                            .font(.system(.title3, design: .serif).weight(.medium))
                            .foregroundColor(colorScheme == .dark ? .white : VenusTheme.text)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                        .foregroundStyle(VenusTheme.primary)
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
                ritualProgressLabel: viewModel.ritualProgressLabel,
                onCompleted: viewModel.handleMoodCheckInCompleted
            )
        }
        .fullScreenCover(isPresented: $viewModel.showVenusChat, onDismiss: {
            viewModel.onChatDismissed()
        }) {
            VenusChatView(session: viewModel.selectedChatSession)
        }
        .sheet(isPresented: $viewModel.showEmotionalGalaxy) {
            EmotionalGalaxyView(
                userName: userName,
                weekMoods: viewModel.weekMoods,
                weeklyTrend: viewModel.weeklyTrend,
                readinessAssessment: viewModel.readinessAssessment
            )
        }
        .fullScreenCover(isPresented: $viewModel.showVenusWrap) {
            VenusWrapStoryView(
                userName: userName,
                weekMoods: viewModel.weekMoods,
                weeklyTrend: viewModel.weeklyTrend,
                readinessAssessment: viewModel.readinessAssessment,
                onDismiss: { viewModel.showVenusWrap = false }
            )
        }
        .sheet(isPresented: $viewModel.showChatHistory) {
            ChatHistoryView { session in
                viewModel.selectedChatSession = session
                viewModel.showChatHistory = false
                viewModel.showVenusChat = true
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
                onContinueToSupport: {
                    viewModel.showVenusProPlans = false
                    viewModel.showVenusChat = true
                }
            )
        }
    }
}

#Preview {
    HomeView(
        userName: "kaua",
        viewModel: HomeViewModel(),
        inlineCheckInViewModel: DependencyContainer.shared.makeMoodCheckInViewModel()
    )
}
