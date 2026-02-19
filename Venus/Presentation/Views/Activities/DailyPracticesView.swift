//
//  DailyPracticesView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct DailyPracticesView: View {
    @StateObject private var viewModel: ActivitiesListViewModel
    @State private var selectedPractice: Activity?
    @State private var showPracticeDetail = false
    @State private var animateCards = false
    @State private var floatingAnimation = false
    @State private var showBreathingView = false
    @State private var showPomodoroView = false
    @State private var showGratitudeView = false
    
    init(viewModel: ActivitiesListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            // Same gradient as HomeView
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Floating Orbs
            ZStack {
                Circle()
                    .fill(VenusTheme.primary.opacity(0.12))
                    .frame(width: 160, height: 160)
                    .blur(radius: 30)
                    .offset(x: -60, y: -100)
                    .scaleEffect(floatingAnimation ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: floatingAnimation)
                
                Circle()
                    .fill(VenusTheme.accentPink.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .offset(x: 80, y: 120)
                    .scaleEffect(floatingAnimation ? 0.7 : 1.1)
                    .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1), value: floatingAnimation)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Práticas Diárias")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(VenusTheme.text)
                                
                                Text("Encontre equilíbrio em pequenos momentos")
                                    .font(.subheadline)
                                    .foregroundColor(VenusTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Circle()
                                    .fill(VenusTheme.surface)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "calendar")
                                            .font(.system(size: 18))
                                            .foregroundColor(VenusTheme.text)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(VenusTheme.chipBorder, lineWidth: 1.5)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animateCards)
                    
                    // Quick Actions
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        QuickActionCard(
                            title: "Respiração",
                            subtitle: "5 min",
                            icon: "wind",
                            color: VenusTheme.primary,
                            action: { showBreathingView = true }
                        )
                        .opacity(animateCards ? 1 : 0)
                        .offset(x: animateCards ? 0 : -30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateCards)
                        
                        QuickActionCard(
                            title: "Pomodoro",
                            subtitle: "25 min",
                            icon: "timer",
                            color: VenusTheme.secondary,
                            action: { showPomodoroView = true }
                        )
                        .opacity(animateCards ? 1 : 0)
                        .offset(x: animateCards ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateCards)
                        
                        QuickActionCard(
                            title: "Gratidão",
                            subtitle: "3 min",
                            icon: "heart.fill",
                            color: VenusTheme.accentPink,
                            action: { showGratitudeView = true }
                        )
                        .opacity(animateCards ? 1 : 0)
                        .offset(x: animateCards ? 0 : -30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateCards)
                        
                        QuickActionCard(
                            title: "Meditação",
                            subtitle: "10 min",
                            icon: "leaf.fill",
                            color: VenusTheme.tertiary,
                            action: { showBreathingView = true }
                        )
                        .opacity(animateCards ? 1 : 0)
                        .offset(x: animateCards ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: animateCards)
                    }
                    .padding(.horizontal, 24)
                    
                    // Categories Section
                    if !viewModel.activities.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Todas as Práticas")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(VenusTheme.text)
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("Ver todas")
                                        .font(.subheadline)
                                        .foregroundColor(VenusTheme.primary)
                                }
                            }
                            .padding(.horizontal, 24)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateCards)
                            
                            ForEach(Array(ActivityCategory.allCases.enumerated()), id: \.element) { index, category in
                                if let categoryActivities = viewModel.activities[category], !categoryActivities.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(category.rawValue)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(VenusTheme.text)
                                            .padding(.horizontal, 24)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                Spacer().frame(width: 8)
                                                
                                                ForEach(categoryActivities.prefix(3)) { activity in
                                                    CompactActivityCard(activity: activity) {
                                                        selectedPractice = activity
                                                        showPracticeDetail = true
                                                    }
                                                }
                                                
                                                Spacer().frame(width: 16)
                                            }
                                        }
                                    }
                                    .opacity(animateCards ? 1 : 0)
                                    .offset(y: animateCards ? 0 : 30)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7 + Double(index) * 0.1), value: animateCards)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            floatingAnimation = true
            withAnimation {
                animateCards = true
            }
            Task {
                await viewModel.loadActivities()
            }
        }
        .sheet(isPresented: $showPracticeDetail) {
            if let practice = selectedPractice {
                PracticeDetailView(activity: practice)
            }
        }
        .fullScreenCover(isPresented: $showBreathingView) {
            BreathingView()
        }
        .fullScreenCover(isPresented: $showPomodoroView) {
            PomodoroView()
        }
        .fullScreenCover(isPresented: $showGratitudeView) {
            GratitudeView()
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(color)
                    )
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(VenusTheme.text)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(VenusTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(VenusTheme.surface)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(VenusTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(VenusTheme.chipBorder, lineWidth: 1.5)
                    )
                    .shadow(color: VenusTheme.text.opacity(0.1), radius: isPressed ? 4 : 10, x: 0, y: isPressed ? 2 : 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

struct CompactActivityCard: View {
    let activity: Activity
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(VenusTheme.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: activity.iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(VenusTheme.primary)
                        )
                    
                    Spacer()
                    
                    Text("\(activity.durationMinutes) min")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(VenusTheme.surface)
                        )
                        .foregroundColor(VenusTheme.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(VenusTheme.text)
                        .lineLimit(2)
                    
                    Text(activity.description)
                        .font(.caption)
                        .foregroundColor(VenusTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(width: 180, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(VenusTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(VenusTheme.chipBorder, lineWidth: 1)
                    )
                    .shadow(color: VenusTheme.text.opacity(0.1), radius: isPressed ? 3 : 8, x: 0, y: isPressed ? 1 : 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

struct PracticeDetailView: View {
    let activity: Activity
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(VenusTheme.surface)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(VenusTheme.text)
                            )
                    }
                    
                    Spacer()
                    
                    Text("Prática")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(VenusTheme.text)
                    
                    Spacer()
                    
                    Circle()
                        .fill(.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Content
                VStack(spacing: 20) {
                    Circle()
                        .fill(VenusTheme.primary.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: activity.iconName)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(VenusTheme.primary)
                        )
                    
                    VStack(spacing: 8) {
                        Text(activity.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(VenusTheme.text)
                        
                        Text("\(activity.durationMinutes) minutos")
                            .font(.subheadline)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    
                    Text(activity.description)
                        .font(.body)
                        .foregroundColor(VenusTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Action Button
                Button(action: { dismiss() }) {
                    HStack {
                        Text("Iniciar Prática")
                            .fontWeight(.semibold)
                        Image(systemName: "play.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(VenusTheme.primaryGradient)
                    .cornerRadius(25)
                    .shadow(color: VenusTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    DailyPracticesView(viewModel: ActivitiesListViewModel(getActivitiesUseCase: DependencyContainer.shared.makeGetActivitiesUseCase()))
}

#Preview("Practice Detail") {
    PracticeDetailView(activity: Activity(
        title: "Meditação Guiada",
        description: "Uma sessão relaxante para acalmar a mente e reduzir o estresse do dia a dia",
        category: .relaxation,
        durationMinutes: 15,
        iconName: "leaf.fill"
    ))
}