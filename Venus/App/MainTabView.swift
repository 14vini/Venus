//
//  MainTabView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//  F22: volta à TabView nativa — o glass da barra é fornecido pelo sistema.
//  Check-in: item de ação separado na própria tab bar (sem botão flutuante).
//

import SwiftUI
import UIKit

// MARK: - VenusAppTab

/// Itens da barra do shell: quatro abas de conteúdo e a ação de check-in.
/// Ordem de exibição definida por `allCases`.
enum VenusAppTab: String, CaseIterable, Sendable, Identifiable {
    case home
    case chat
    case settings
    case profile
    /// Item de ação da barra: abre o check-in e devolve a seleção à aba anterior.
    case checkIn

    var id: String { rawValue }

    /// Símbolos em traço (outline), iguais aos usados antes da F19.
    var systemImage: String {
        switch self {
        case .home:     return "house"
        case .chat:     return "bubble.left.and.bubble.right"
        case .settings: return "gearshape"
        case .profile:  return "person"
        case .checkIn:  return "plus.circle.fill"
        }
    }

    /// Rótulos em português, preservando a UI do app.
    var accessibilityLabel: String {
        switch self {
        case .home:     return "Hoje"
        case .chat:     return "Conversa"
        case .settings: return "Ajustes"
        case .profile:  return "Perfil"
        case .checkIn:  return "Check-in"
        }
    }
}

struct MainTabView: View {
    let userName: String
    @Environment(UserProfile.self) private var userProfile
    @State private var selectedTab: VenusAppTab = .home
    /// Última aba de conteúdo visitada — para onde o check-in retorna.
    @State private var lastContentTab: VenusAppTab = .home
    @State private var showCheckIn = false
    @State private var checkInViewModel = DependencyContainer.shared.makeMoodCheckInViewModel()

    /// A TabView nativa desenha a barra com o glass do sistema e já reserva o
    /// safe area do conteúdo. Não há pill, material customizado nem botão flutuante.
    var body: some View {
        ZStack {
            VenusAppBackground()

            TabView(selection: $selectedTab) {
                tabContent
            }
            .tint(VenusTheme.primary)
            .onChange(of: selectedTab) { _, newTab in
                guard newTab == .checkIn else {
                    lastContentTab = newTab
                    return
                }
                // Item de ação: nunca vira aba — abre o check-in e retorna
                // imediatamente para onde o usuário estava.
                selectedTab = lastContentTab
                presentCheckIn()
            }
        }
        .preferredColorScheme(nil)
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

    // MARK: - Conteúdo por aba

    @ViewBuilder
    private var tabContent: some View {
        NavigationStack {
            HomeScreen(userName: userName)
        }
        .tabItem {
            Label(VenusAppTab.home.accessibilityLabel, systemImage: VenusAppTab.home.systemImage)
        }
        .tag(VenusAppTab.home)

        // VenusChatView já traz seu próprio NavigationStack interno.
        VenusChatView(session: nil)
            .tabItem {
                Label(VenusAppTab.chat.accessibilityLabel, systemImage: VenusAppTab.chat.systemImage)
            }
            .tag(VenusAppTab.chat)

        NavigationStack {
            SettingsView()
        }
        .tabItem {
            Label(VenusAppTab.settings.accessibilityLabel, systemImage: VenusAppTab.settings.systemImage)
        }
        .tag(VenusAppTab.settings)

        NavigationStack {
            ProfileView()
        }
        .tabItem {
            Label(VenusAppTab.profile.accessibilityLabel, systemImage: VenusAppTab.profile.systemImage)
        }
        .tag(VenusAppTab.profile)

        // Item de ação separado na barra nativa: abre o check-in sem virar aba.
        Color.clear
            .ignoresSafeArea()
            .tabItem {
                Label(
                    VenusAppTab.checkIn.accessibilityLabel,
                    systemImage: VenusAppTab.checkIn.systemImage
                )
            }
            .tag(VenusAppTab.checkIn)
    }

    // MARK: - Ações

    @MainActor
    private func presentCheckIn() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        checkInViewModel.startNewCheckIn()
        showCheckIn = true
    }
}

#Preview {
    MainTabView(userName: "Kauã")
        .environment(UserProfile())
}
