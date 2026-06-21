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
//                    if viewModel.userProfile != nil {
//                        HStack {
//                            HStack(spacing: 6) {
//                                Image(systemName: viewModel.routineStatusIcon)
//                                    .font(.system(size: 12, weight: .bold))
//                                Text(viewModel.routineStatusLabel)
//                                    .font(.system(.caption, design: .rounded).weight(.bold))
//                            }
//                            .foregroundColor(Color(hex: viewModel.routineStatusColorHex))
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 6)
//                            .background(Color(hex: viewModel.routineStatusColorHex).opacity(0.12))
//                            .clipShape(Capsule())
//                            .overlay(
//                                Capsule()
//                                    .stroke(Color(hex: viewModel.routineStatusColorHex).opacity(0.24), lineWidth: 1)
//                            )
//                            
//                            Spacer()
//                        }
//                        .padding(.top, 8)
//                        .padding(.horizontal, 4)
//                    }

                    HomeImmersiveCheckInHeroSection(
                        selectedMood: viewModel.heroSelectedMood,
                        hasCheckedInToday: viewModel.hasCheckedInToday,
                        progressLabel: viewModel.ritualProgressLabel,
                        statusLabel: viewModel.checkInStatusLabel,
                        isSelectionLocked: viewModel.hasCheckedInToday && !viewModel.checkInAllowance.canCheckIn,
                        greetingText: viewModel.homeHeadline,
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
                        isLoadingInsights: viewModel.isLoadingInsights,
                        onLookIntoMirror: { viewModel.showMirror = true }
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
        .fullScreenCover(isPresented: $viewModel.showMoodCheckIn, onDismiss: {
            inlineCheckInViewModel.startNewCheckIn()
        }) {
            MoodCheckInView(
                viewModel: inlineCheckInViewModel,
                ritualProgressLabel: viewModel.ritualProgressLabel,
                onCompleted: viewModel.handleMoodCheckInCompleted
            )
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
        .sheet(isPresented: $viewModel.showMirror) {
            MirrorInsightView(
                weeklyTrend: viewModel.weeklyTrend,
                weeklyInsights: viewModel.weeklyInsights,
                patternAlert: viewModel.patternAlert
            )
        }
    }
}

#Preview {
    HomeScreen(userName: "Kauã")
}
