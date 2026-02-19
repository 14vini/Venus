//
//  ActivitiesListView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import Combine

@MainActor
class ActivitiesListViewModel: ObservableObject {
    @Published var activities: [ActivityCategory: [Activity]] = [:]
    private let getActivitiesUseCase: GetActivitiesUseCaseProtocol
    
    init(getActivitiesUseCase: GetActivitiesUseCaseProtocol) {
        self.getActivitiesUseCase = getActivitiesUseCase
    }
    
    func loadActivities() async {
        let allActivities = await getActivitiesUseCase.execute()
        activities = Dictionary(grouping: allActivities, by: { $0.category })
    }
}

struct ActivitiesListView: View {
    @StateObject var viewModel: ActivitiesListViewModel
    @State private var appearAnimation = false
    @State private var headerPulse = false
    @State private var selectedActivity: Activity?
    
    var body: some View {
        ZStack {
            // Same gradient as HomeView
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Ambient Orbs
            ZStack {
                Circle()
                    .fill(VenusTheme.primary.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(x: -80, y: -150)
                    .scaleEffect(headerPulse ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: headerPulse)
                
                Circle()
                    .fill(VenusTheme.accentPink.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)
                    .offset(x: 100, y: 200)
                    .scaleEffect(headerPulse ? 0.8 : 1.2)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(1), value: headerPulse)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Hero Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Práticas Diárias")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(VenusTheme.text)
                        
                        Text("Explore técnicas para elevar sua energia.")
                            .font(.subheadline)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                    
                    // Categories
                    ForEach(Array(ActivityCategory.allCases.enumerated()), id: \.element) { index, category in
                        if let categoryActivities = viewModel.activities[category], !categoryActivities.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(category.rawValue)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(VenusTheme.text)
                                    
                                    Spacer()
                                    
                                    Text("\(categoryActivities.count) práticas")
                                        .font(.caption)
                                        .foregroundColor(VenusTheme.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(VenusTheme.surface)
                                        )
                                }
                                .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        Spacer().frame(width: 8)
                                        
                                        ForEach(Array(categoryActivities.enumerated()), id: \.element.id) { cardIndex, activity in
                                            ActivityCard(activity: activity) {
                                                selectedActivity = activity
                                            }
                                            .scrollTransition { content, phase in
                                                content
                                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                                                    .rotation3DEffect(
                                                        .degrees(phase.value * -8),
                                                        axis: (x: 0, y: 1, z: 0)
                                                    )
                                                    .opacity(phase.isIdentity ? 1.0 : 0.85)
                                            }
                                            .opacity(appearAnimation ? 1 : 0)
                                            .offset(x: appearAnimation ? 0 : 50)
                                            .animation(
                                                .spring(response: 0.6, dampingFraction: 0.8)
                                                .delay(0.4 + (0.1 * Double(index)) + (0.05 * Double(cardIndex))),
                                                value: appearAnimation
                                            )
                                        }
                                        
                                        Spacer().frame(width: 24)
                                    }
                                }
                                .contentMargins(.horizontal, 0, for: .scrollContent)
                            }
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.8).delay(0.3 + (0.1 * Double(index))),
                                value: appearAnimation
                            )
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            headerPulse = true
            withAnimation {
                appearAnimation = true
            }
            Task {
                await viewModel.loadActivities()
            }
        }
        .fullScreenCover(item: $selectedActivity) { activity in
            ActivityDetailView(activity: activity)
        }
    }
}

struct ActivityCard: View {
    let activity: Activity
    var action: () -> Void = {}
    @State private var isPressed = false
    @State private var shimmer = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon & Time Header
                HStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: activity.iconName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    Spacer()
                    
                    Text("\(activity.durationMinutes) min")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                }
                .padding(24)
                
                Spacer()
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    Text(activity.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(activity.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.2), .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 240, height: 300)
        .background(
            ZStack {
                // Main Gradient
                LinearGradient(
                    colors: [
                        VenusTheme.primary,
                        VenusTheme.secondary,
                        VenusTheme.tertiary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Shimmer effect
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(45))
                .offset(x: shimmer ? 300 : -300)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: shimmer)
                
                // Glass overlay
                LinearGradient(
                    colors: [.white.opacity(0.2), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: VenusTheme.primary.opacity(0.3), radius: isPressed ? 8 : 15, x: 0, y: isPressed ? 4 : 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }
        .onAppear {
            shimmer = true
        }
    }
}

#Preview {
    ActivitiesListView(viewModel: ActivitiesListViewModel(getActivitiesUseCase: DependencyContainer.shared.makeGetActivitiesUseCase()))
}

#Preview("Activity Card") {
    ActivityCard(activity: Activity(
        title: "Meditação Guiada",
        description: "Uma sessão relaxante para acalmar a mente e reduzir o estresse",
        category: .relaxation,
        durationMinutes: 15,
        iconName: "leaf.fill"
    ))
    .padding()
    .background(VenusTheme.backgroundGradient)
}
