//
//  HomeView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct HomeView: View {
    let userName: String
    @State private var selectedRecommendationActivity: Activity?
    @State private var showVenusChat = false
    @State private var showChatHistory = false
    
    @StateObject private var viewModel = HomeViewModel(
        smartRecommendationUseCase: DependencyContainer.shared.makeSmartRecommendationUseCase(),
        profileRepository: DependencyContainer.shared.makeUserProfileRepository(),
        moodRepository: DependencyContainer.shared.makeMoodRepository()
    )
    
    var body: some View {
        ZStack {
            // Gradient Background (Venus colors - purple/lavender)
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Olá, \(userName)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(VenusTheme.text)
                        
                        Text("É o seu \(getCurrentDayCount())º dia")
                            .font(.subheadline)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // top buttons
                    HStack(spacing: 12) {
                        // HistoryChat
                        Button(action: { showChatHistory = true }) {
                            Circle()
                                .fill(VenusTheme.surface)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "clock")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(VenusTheme.text)
                                )
                        }
                        
                        // Chat
                        Button(action: { showVenusChat = true }) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color(hex: "FF3D00").opacity(0.3), radius: 8, x: 0, y: 4)
                            
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Center Question
                VStack(spacing: 24) {
                    Text("Como você está se sentindo\nagora?")
                        .font(.system(size: 32, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundColor(VenusTheme.text)
                        .multilineTextAlignment(.center)
                    
                    // Add Button
                    Button(action: { viewModel.checkInButtonTapped() }) {
                        Circle()
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )
                           
                    }
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "FF3D00").opacity(0.4), radius: 12, x: 0, y: 6)
                    )

                }
                
                Spacer()
                
                // Bottom Cards
                VStack(spacing: 16) {
                    if let recommendation = viewModel.dailyRecommendation {
                        Button(action: { selectedRecommendationActivity = recommendation.activity }) {
                            RecommendationCard(recommendation: recommendation)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        HStack(spacing: 16) {
                            // New Insights Card (Default)
                            Button(action: {}) {
                                VStack(spacing: 12) {
                                    Image(systemName: "lightbulb.circle")
                                        .font(.title)
                                        .foregroundColor(VenusTheme.text)
                                    
                                    Text("Novas\nsugestões")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(VenusTheme.text)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(VenusTheme.surface)
                                )
                            }
                            
                            // Compliment Card
                            Button(action: {}) {
                                VStack(spacing: 12) {
                                    Image(systemName: "heart.circle")
                                        .font(.title)
                                        .foregroundColor(VenusTheme.text)
                                    
                                    Text("Criar\nafirmação")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(VenusTheme.text)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(VenusTheme.surface)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $viewModel.showMoodCheckIn) {
            MoodCheckInView(
                viewModel: DependencyContainer.shared.makeMoodCheckInViewModel(),
                onCompleted: viewModel.handleMoodCheckInCompleted
            )
        }
        .fullScreenCover(isPresented: $showVenusChat) {
            VenusChatView()
        }
        .fullScreenCover(item: $selectedRecommendationActivity) { activity in
            ActivityDetailView(activity: activity)
        }
        .sheet(isPresented: $showChatHistory) {
            ChatHistoryView { session in
                showChatHistory = false
                showVenusChat = true
            }
        }
    }
    
    private func getCurrentDayCount() -> Int {
        // Placeholder - calculate days since app install or onboarding
        return 1
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(Color(hex: "FF3D00"))
                Spacer()
                Text(recommendation.suggestedTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(VenusTheme.surface)
                    .cornerRadius(8)
            }
            
            Text("Sugerido para agora")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(VenusTheme.textSecondary)
            
            Text(recommendation.activity.title)
                .font(.headline)
                .foregroundColor(VenusTheme.text)
            
            Text(recommendation.reason)
                .font(.subheadline)
                .foregroundColor(VenusTheme.textSecondary)
                .lineLimit(3)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(VenusTheme.surface)
        )
    }
}

#Preview {
    HomeView(userName: "Kauã")
}
