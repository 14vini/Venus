//
//  VenusApp.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

@main
struct VenusApp: App {
    @State private var userProfile = UserProfile()
    @State private var isLoading = true
    @State private var showSplash = true
    @State private var hasBootstrapped = false
    @State private var splashStartDate = Date()
    
    private let minimumSplashDuration: TimeInterval = 1.6
    
    private let profileRepository = DependencyContainer.shared.makeUserProfileRepository()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isLoading {
                    destinationView
                        .transition(.opacity)
                }
                
                if showSplash {
                    VenusSplashView(isReadyToReveal: !isLoading) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: showSplash)
            .preferredColorScheme(nil) // Permite que o sistema controle o modo escuro
            .task {
                guard !hasBootstrapped else { return }
                hasBootstrapped = true
                splashStartDate = Date()
                await loadUserProfile()
                await enforceMinimumSplashDurationIfNeeded()
                isLoading = false
            }
            .onChange(of: userProfile.isOnboardingComplete) { _, isComplete in
                if isComplete {
                    Task {
                        await saveUserProfile()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if userProfile.isOnboardingComplete {
            MainTabView(userName: userProfile.name.isEmpty ? "Visitante" : userProfile.name)
                .environment(userProfile)
        } else {
            OnboardingView(startAtWelcome: false)
                .environment(userProfile)
        }
    }
    
    @MainActor
    private func loadUserProfile() async {
        do {
            if let savedProfile = try await profileRepository.load() {
                userProfile = savedProfile
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    @MainActor
    private func saveUserProfile() async {
        do {
            try await profileRepository.save(profile: userProfile)
        } catch {
            print("Error saving profile: \(error)")
        }
    }
    
    @MainActor
    private func enforceMinimumSplashDurationIfNeeded() async {
        let elapsed = Date().timeIntervalSince(splashStartDate)
        let remaining = minimumSplashDuration - elapsed
        
        guard remaining > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
    }
}
