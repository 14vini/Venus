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
                VStack(alignment: .leading, spacing: 32) {
                    // "Sobre você:" (Trend summary)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sobre você:")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(VenusTheme.primary)
                            .textCase(.uppercase)

                        Text(viewModel.weeklyTrend?.summary ?? "Analisando seus dados iniciais para desenhar seu reflexo emocional. Continue registrando seus check-ins com Venus.")
                            .font(.system(.title3, design: .serif).weight(.medium))
                            .foregroundColor(.white)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // "Como você está agora:"
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Como você está agora:")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(VenusTheme.primary)
                            .textCase(.uppercase)

                        Text(viewModel.weeklyInsights?.dominantTrigger != nil ?
                             "O fator '\(viewModel.weeklyInsights!.dominantTrigger!)' tem ecoado forte em sua mente recentemente." :
                             "Observando seus hábitos iniciais para identificar gatilhos e janelas de estresse recorrentes.")
                            .font(.system(.body, design: .serif))
                            .foregroundColor(Color.white.opacity(0.8))
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Weekly Mood Waveform
                    WeeklyMoodWaveform(moods: viewModel.weekMoods)
                        .padding(.top, 8)
                    
                    // Mapped Patterns Grid
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("Padrões Mapeados")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundColor(VenusTheme.primary)
                                .textCase(.uppercase)
                            
                            if viewModel.weeklyInsights == nil {
                                Text("(Estimativas)")
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            let trigger = viewModel.weeklyInsights?.dominantTrigger ?? "Sua Rotina"
                            let window = viewModel.weeklyInsights?.criticalWindow ?? "Tarde (14h - 16h)"
                            let best = viewModel.weeklyInsights?.bestDay ?? "Quarta-feira"
                            let focus = viewModel.weeklyInsights?.behavioralFocus ?? "Evitar telas à noite"
                            
                            HomeInsightCard(
                                title: "Gatilho Dominante",
                                icon: "bolt.fill",
                                highlight: trigger,
                                color: VenusTheme.accentOrange
                            )
                            HomeInsightCard(
                                title: "Janela Crítica",
                                icon: "clock.fill",
                                highlight: window,
                                color: VenusTheme.accentPurple
                            )
                            HomeInsightCard(
                                title: "Melhor Dia",
                                icon: "sun.max.fill",
                                highlight: best,
                                color: VenusTheme.accentGreen
                            )
                            HomeInsightCard(
                                title: "Foco Comportamental",
                                icon: "leaf.fill",
                                highlight: focus,
                                color: VenusTheme.accentPink
                            )
                        }
                    }
                    
                    // Legal disclaimer footer
                    Text("Aviso: As análises baseiam-se em registros parciais que podem estar incompletos. A inteligência artificial Venus pode cometer erros. Use estas informações apenas como reflexão pessoal.")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.white.opacity(0.32))
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                        .padding(.bottom, 160)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Olá, \(userName)")
        .navigationBarTitleDisplayMode(.automatic)
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
        .fullScreenCover(isPresented: $viewModel.showVenusChat, onDismiss: {
            viewModel.selectedChatSession = nil
        }) {
            VenusChatView(session: viewModel.selectedChatSession)
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

struct HomeInsightCard: View {
    let title: String
    let icon: String
    let highlight: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            Text(highlight)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(VenusTheme.cardSurface.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
