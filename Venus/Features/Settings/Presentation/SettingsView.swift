//
//  SettingsView.swift
//  Venus
//
//  Created by Kaua on 19/03/26.
//
//  F15 — hierarquia clara (cabeçalho, grupos, ações), vidro real e haptics.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(UserProfile.self) private var userProfile
    @AppStorage(LocalSubscriptionStatusProvider.planKey) private var isProEnabled = false
    @AppStorage("debug.streakOverride") private var streakOverride: Int = 0
    @AppStorage("debug.streakOverrideEnabled") private var streakOverrideEnabled: Bool = false
    @State private var showResetAlert = false
    @State private var isResetting = false
    @State private var resetErrorMessage: String?

    var body: some View {
        ZStack {
            VenusSoftGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    subscriptionSection

                    resetSection

                    streakSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.automatic)
        .alert("Apagar tudo do app?", isPresented: $showResetAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Apagar tudo", role: .destructive) {
                Task {
                    await resetApp()
                }
            }
        } message: {
            Text("Isso remove seus dados locais e faz o app abrir novamente como se fosse a primeira vez.")
        }
        .alert("Não foi possível resetar", isPresented: resetErrorIsPresented) {
            Button("OK", role: .cancel) {
                resetErrorMessage = nil
            }
        } message: {
            Text(resetErrorMessage ?? "Tente novamente.")
        }
    }

    // MARK: - Cabeçalho

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ajustes")
                .font(.system(size: 30, design: .rounded).weight(.bold))
                .foregroundStyle(VenusTheme.text)

            Text("Aqui fica o que muda a experiência do app, sem poluir a Home.")
                .font(.system(size: 14, design: .rounded).weight(.regular))
                .foregroundStyle(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Assinatura

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionKicker("ASSINATURA")

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(VenusTheme.accentPurple.opacity(0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(VenusTheme.accentPurple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Modo Pro")
                        .font(.system(size: 18, design: .rounded).weight(.semibold))
                        .foregroundStyle(VenusTheme.text)

                    Text("Ative para liberar leituras mais completas e mais check-ins no dia.")
                        .font(.system(size: 13, design: .rounded).weight(.regular))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Toggle("", isOn: venusHapticBinding($isProEnabled, style: .medium))
                    .labelsHidden()
                    .tint(VenusTheme.accentPurple)
            }

            HStack(spacing: 8) {
                proPill

                statusPill

                Spacer(minLength: 0)
            }
        }
        .settingsCardStyle()
    }

    private var proPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10, weight: .semibold))

            Text("VENUS PRO")
                .font(.system(size: 10, design: .rounded).weight(.semibold))
                .kerning(0.8)
        }
        .foregroundStyle(VenusTheme.accentPurpleDeep)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(VenusTheme.accentPurple.opacity(0.18)), in: Capsule(style: .continuous))
    }

    private var statusPill: some View {
        Text(isProEnabled ? "Pro ativo" : "Modo gratuito")
            .font(.system(size: 11, design: .rounded).weight(.medium))
            .foregroundStyle(isProEnabled ? VenusTheme.accentPurpleDeep : VenusTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: Capsule(style: .continuous))
            .contentTransition(.opacity)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isProEnabled)
    }

    // MARK: - Reset

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionKicker("PRIVACIDADE")

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Resetar app")
                        .font(.system(size: 18, design: .rounded).weight(.semibold))
                        .foregroundStyle(VenusTheme.text)

                    Text("Apaga dados locais, preferências, tarefas, check-ins e faz o app voltar ao onboarding.")
                        .font(.system(size: 13, design: .rounded).weight(.regular))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showResetAlert = true
            } label: {
                HStack(spacing: 10) {
                    if isResetting {
                        ProgressView()
                            .tint(.red)
                    } else {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 13, weight: .semibold))
                    }

                    Text(isResetting ? "Resetando..." : "Apagar tudo e recomeçar")
                        .font(.system(size: 14, design: .rounded).weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glass)
            .tint(.red)
            .disabled(isResetting)
            .scaleEffect(isResetting ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isResetting)
        }
        .settingsCardStyle()
    }

    // MARK: - Streak Debug

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionKicker("DESENVOLVIMENTO")

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(VenusTheme.accentOrange.opacity(0.14))
                        .frame(width: 44, height: 44)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(VenusTheme.accentOrange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Testar Streak")
                        .font(.system(size: 18, design: .rounded).weight(.semibold))
                        .foregroundStyle(VenusTheme.text)

                    Text("Simula dias de streak para ver milestones, confetti e falas do mascot.")
                        .font(.system(size: 13, design: .rounded).weight(.regular))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle("Ativar override de streak", isOn: venusHapticBinding($streakOverrideEnabled, style: .medium))
                .font(.system(size: 14, design: .rounded).weight(.medium))
                .tint(VenusTheme.accentOrange)

            if streakOverrideEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Dias simulados")
                            .font(.system(size: 14, design: .rounded).weight(.medium))
                            .foregroundStyle(VenusTheme.text)

                        Spacer()

                        StreakBadge(days: streakOverride, celebrated: true)
                    }

                    Stepper(value: venusHapticBinding($streakOverride), in: 0...365) {
                        Text("\(streakOverride) dias")
                            .font(.system(size: 14, design: .rounded).weight(.semibold))
                            .foregroundStyle(VenusTheme.accentOrange)
                    }

                    Text("MILESTONES")
                        .font(.system(size: 10, design: .rounded).weight(.semibold))
                        .kerning(1.2)
                        .foregroundStyle(VenusTheme.textSecondary)

                    HStack(spacing: 10) {
                        ForEach([3, 7, 14, 30], id: \.self) { milestone in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                streakOverride = milestone
                            } label: {
                                Text("\(milestone)d")
                                    .font(.system(size: 13, design: .rounded).weight(.semibold))
                                    .foregroundStyle(
                                        streakOverride == milestone
                                            ? VenusTheme.accentOrange
                                            : VenusTheme.textSecondary
                                    )
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(
                                streakOverride == milestone
                                    ? .regular.tint(VenusTheme.accentOrange.opacity(0.28))
                                    : .regular,
                                in: Capsule(style: .continuous)
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: streakOverrideEnabled)
            }

            Text(streakOverrideEnabled ? "Override ativo: \(streakOverride) dias" : "Override desativado — usando streak real.")
                .font(.system(size: 12, design: .rounded).weight(.medium))
                .foregroundStyle(streakOverrideEnabled ? VenusTheme.accentOrange : VenusTheme.textSecondary)
        }
        .settingsCardStyle()
    }

    // MARK: - Componentes

    private func sectionKicker(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, design: .rounded).weight(.semibold))
            .kerning(1.4)
            .foregroundStyle(VenusTheme.textSecondary)
    }

    private var resetErrorIsPresented: Binding<Bool> {
        Binding(
            get: { resetErrorMessage != nil },
            set: { shouldPresent in
                if !shouldPresent {
                    resetErrorMessage = nil
                }
            }
        )
    }

    @MainActor
    private func resetApp() async {
        guard !isResetting else { return }
        isResetting = true
        resetErrorMessage = nil

        do {
            try AppResetService().resetAllLocalData()
            resetUserDefaults()
            isProEnabled = false
            userProfile.reset()
        } catch {
            resetErrorMessage = "O reset falhou. Nada foi apagado por completo."
        }

        isResetting = false
    }

    private func resetUserDefaults() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
    }
}

// MARK: - Estilo de cartão em vidro

private struct SettingsCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private extension View {
    func settingsCardStyle() -> some View {
        modifier(SettingsCardStyle())
    }
}

#Preview {
    SettingsView()
        .environment(UserProfile())
}
