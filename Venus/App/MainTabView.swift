//
//  MainTabView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct MainTabView: View {
    let userName: String
    @Environment(UserProfile.self) private var userProfile
    @State private var showCheckIn = false
    @State private var checkInViewModel = DependencyContainer.shared.makeMoodCheckInViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                NavigationStack {
                    HomeScreen(userName: userName)
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }

                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
            }
            .tint(VenusTheme.primary)
            .preferredColorScheme(nil)
            .tabBarMinimizeBehavior(.onScrollDown)
            
            // Floating Check-In Action Button
            Button {
                checkInViewModel.startNewCheckIn()
                showCheckIn = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                    Text("Check-in")
                        .font(.headline)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(
                    Capsule()
                        .fill(VenusTheme.primary)
                        .shadow(color: VenusTheme.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 70)
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            MoodCheckInView(
                viewModel: checkInViewModel,
                ritualProgressLabel: "Ritual Global",
                onCompleted: { _ in
                    showCheckIn = false
                }
            )
        }
    }
}

#Preview {
    MainTabView(userName: "Kauã")
        .environment(UserProfile())
}
