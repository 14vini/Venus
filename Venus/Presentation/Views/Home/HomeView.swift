//
//  HomeView.swift
//  Venus
//
//  Refactored by Kaua on 18/03/26.
//

import SwiftUI

struct HomeView: View {
    let userName: String
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var inlineCheckInViewModel: MoodCheckInViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VenusReadingBackground(dayMoment: viewModel.dayMoment, isAnimated: true)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HomeImmersiveCheckInHeroSection(
                        selectedMood: viewModel.heroSelectedMood,
                        hasCheckedInToday: viewModel.hasCheckedInToday,
                        progressLabel: viewModel.ritualProgressLabel,
                        statusLabel: viewModel.checkInStatusLabel,
                        isSelectionLocked: viewModel.hasCheckedInToday && !viewModel.checkInAllowance.canCheckIn,
                        mascotSpeech: viewModel.homeHeadline,
                        moodIntensity: viewModel.todayMoodIntensity,
                        onSelectMood: viewModel.handleInlineMoodSelection
                    )

                    HomeReflectionsPreviewSection(
                        mood: viewModel.todayMoodType,
                        intensity: viewModel.todayMoodIntensity,
                        tags: viewModel.todayMoodTags,
                        bodySignals: viewModel.todayMoodBodySignals,
                        energyLevel: viewModel.todayMoodEnergyLevel,
                        affectedArea: viewModel.todayMoodAffectedArea,
                        weeklyTrend: viewModel.weeklyTrend,
                        patternAlert: viewModel.patternAlert,
                        weeklyInsights: viewModel.weeklyInsights,
                        action: viewModel.displayedActionModel,
                        isLoadingInsights: viewModel.isLoadingInsights,
                        onReasonTap: viewModel.handleActionReasonTap
                    )
                }
                .padding(.horizontal,20)
                .padding(.bottom, 160)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            HomeCheckInFloatingOverlay(
                showHint: viewModel.showCheckInHint,
                hintTitle: viewModel.checkInHintTitle,
                hintBody: viewModel.checkInHintBody,
                buttonTitle: viewModel.checkInFloatingButtonTitle,
                buttonSubtitle: viewModel.checkInFloatingButtonSubtitle,
                buttonIcon: viewModel.checkInFloatingButtonIcon,
                isProPrompt: viewModel.hasCheckedInToday && !viewModel.checkInAllowance.canCheckIn,
                isDisabled: false,
                action: viewModel.handleCheckInAction
            )
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Spacer()
                StreakBadge(
                    days: viewModel.displayedStreakDays,
                    celebrated: viewModel.hasCheckedInToday || viewModel.streakOverrideEnabled
                )
                .padding(.trailing, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            .background(.clear)
        }
        .navigationTitle("Olá, \(userName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.showChatHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showVenusChat = true
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
            }
        }
        .sheet(isPresented: $viewModel.showMoodCheckIn, onDismiss: {
            inlineCheckInViewModel.startNewCheckIn()
        }) {
            NavigationStack {
                MoodCheckInView(
                    viewModel: inlineCheckInViewModel,
                    ritualProgressLabel: viewModel.ritualProgressLabel,
                    onCompleted: viewModel.handleMoodCheckInCompleted
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showVenusChat) {
            VenusChatView()
        }
        .sheet(isPresented: $viewModel.showChatHistory) {
            ChatHistoryView { _ in
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
        .navigationDestination(item: $viewModel.actionReasonAction) { actionModel in
            HomeActionReasonView(
                actionModel: actionModel,
                weeklyInsights: viewModel.weeklyInsights,
                patternAlert: viewModel.patternAlert,
                actionWhy: viewModel.actionWhy,
                proForecast: viewModel.proMoodForecast,
                isPro: viewModel.checkInAllowance.plan == .pro,
                confidenceInsight: viewModel.confidenceInsight,
                triggerRecoveryInsight: viewModel.triggerRecoveryInsight,
                alternativeActions: viewModel.displayedAlternativeActions,
                exploreSuggestions: viewModel.exploreActionSuggestions
            )
        }
        .fullScreenCover(isPresented: $viewModel.showWrapped) {
            if let action = viewModel.actionReasonAction {
                HomeWrappedView(
                    actionModel: action,
                    weeklyInsights: viewModel.weeklyInsights,
                    patternAlert: viewModel.patternAlert,
                    actionWhy: viewModel.actionWhy,
                    proForecast: viewModel.proMoodForecast,
                    isPro: viewModel.checkInAllowance.plan == .pro,
                    confidenceInsight: viewModel.confidenceInsight,
                    triggerRecoveryInsight: viewModel.triggerRecoveryInsight,
                    weeklyTrend: viewModel.weeklyTrend
                )
            }
        }
    }
}

#Preview {
    HomeScreen(userName: "Kauã")
}
