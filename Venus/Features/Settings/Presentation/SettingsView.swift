//
//  SettingsView.swift
//  Venus
//
//  Created by Kaua on 19/03/26.
//
//  F15 — hierarquia clara (cabeçalho, grupos, ações), vidro real e haptics.
//  F36 — cabeçalho com arco, grupos em vidro e marcos de streak visíveis.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(UserProfile.self) private var userProfile
    @AppStorage(LocalSubscriptionStatusProvider.planKey) private var isProEnabled = false
    @State private var showResetAlert = false
    @State private var isResetting = false
    @State private var resetErrorMessage: String?
    @State private var didAppear: Bool = false

    var body: some View {
        ZStack {
            VenusSoftGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    subscriptionSection

                    resetSection

                    progressSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 100)
                .opacity(didAppear ? 1 : 0)
                .offset(y: didAppear ? 0 : 14)
                .animation(.spring(response: 0.55, dampingFraction: 0.85), value: didAppear)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                didAppear = true
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
        VenusF36JourneyHeader(
            eyebrow: "Seu espaço",
            title: "Ajustes",
            subtitle: "O que muda a sua experiência, em um só lugar.",
            dotCount: 4,
            currentDot: 1,
            dotCaption: "Marcos: 3 · 7 · 14 · 30 dias",
            tint: VenusF36Palette.rose
        )
    }

    // MARK: - Assinatura

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionKicker("ASSINATURA")

            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(VenusF36Palette.lilac.opacity(0.20))
                        .frame(width: 44, height: 44)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(VenusF36Palette.lilac)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Modo Pro")
                        .font(.system(size: 20, design: .rounded).weight(.light))
                        .foregroundStyle(VenusTheme.text)

                    Text("Mais leituras e mais check-ins por dia.")
                        .font(.system(size: 13, design: .rounded).weight(.regular))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Toggle("", isOn: venusHapticBinding($isProEnabled, style: .medium))
                    .labelsHidden()
                    .tint(VenusF36Palette.lilac)
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
        .foregroundStyle(VenusF36Palette.lilac)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(VenusF36Palette.lilac.opacity(0.20)), in: Capsule(style: .continuous))
    }

    private var statusPill: some View {
        Text(isProEnabled ? "Pro ativo" : "Modo gratuito")
            .font(.system(size: 11, design: .rounded).weight(.medium))
            .foregroundStyle(isProEnabled ? VenusF36Palette.rose : VenusTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(
                isProEnabled
                    ? .regular.tint(VenusF36Palette.rose.opacity(0.18))
                    : .regular,
                in: Capsule(style: .continuous)
            )
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
                        .font(.system(size: 20, design: .rounded).weight(.light))
                        .foregroundStyle(VenusTheme.text)

                    Text("Apaga seus dados e volta ao começo.")
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
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(Color.red.opacity(0.10)), in: Capsule(style: .continuous))
            .disabled(isResetting)
            .scaleEffect(isResetting ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isResetting)
        }
        .settingsCardStyle()
    }

    // MARK: - Progresso (informação real)

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionKicker("SEU PROGRESSO")

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
                    Text("Streak de check-ins")
                        .font(.system(size: 20, design: .rounded).weight(.light))
                        .foregroundStyle(VenusTheme.text)

                    Text("Cada check-in fortalece sua sequência e desbloqueia um cosmético.")
                        .font(.system(size: 13, design: .rounded).weight(.regular))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text("MARCOS DESBLOQUEÁVEIS")
                .font(.system(size: 10, design: .rounded).weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(VenusTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(Array([3, 7, 14, 30].enumerated()), id: \.offset) { index, milestone in
                    let tint = index.isMultiple(of: 2) ? VenusF36Palette.lilac : VenusF36Palette.rose

                    HStack(spacing: 6) {
                        Text("\(milestone) dias")
                            .font(.system(size: 12, design: .rounded).weight(.semibold))
                            .foregroundStyle(tint)

                        if let reward = VenusCosmeticItem.milestoneLabel(forStreakDays: milestone) {
                            Text(reward)
                                .font(.system(size: 10, design: .rounded).weight(.medium))
                                .foregroundStyle(VenusTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .glassEffect(
                        .regular.tint(tint.opacity(0.12)),
                        in: Capsule(style: .continuous)
                    )
                }
            }

            Text("Contam apenas os seus check-ins reais.")
                .font(.system(size: 12, design: .rounded).weight(.medium))
                .foregroundStyle(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
