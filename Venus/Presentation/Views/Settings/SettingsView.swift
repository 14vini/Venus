//
//  SettingsView.swift
//  Venus
//
//  Created by Kaua on 19/03/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(UserProfile.self) private var userProfile
    @AppStorage(LocalSubscriptionStatusProvider.planKey) private var isProEnabled = false
    @State private var showResetAlert = false
    @State private var isResetting = false
    @State private var resetErrorMessage: String?
    
    var body: some View {
        ZStack {
            VenusReadingBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aqui fica o que muda a experiência do app, sem poluir a Home.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 18) {
                        VenusProBadge()
                        
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(VenusTheme.accentPurple.opacity(0.14))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(VenusTheme.accentPurple)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Modo Pro")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.text)
                                
                                Text("Ative para liberar leituras mais completas e mais check-ins no dia.")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(VenusTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isProEnabled)
                                .labelsHidden()
                                .tint(VenusTheme.accentPurple)
                        }
                        
                        Text(isProEnabled ? "Modo Pro ativo neste aparelho." : "Modo gratuito ativo neste aparelho.")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(isProEnabled ? VenusTheme.accentPurpleDeep : VenusTheme.textSecondary)
                    }
                    .padding(20)
                    .venusProGlassCardStyle(cornerRadius: 28)
                    
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Resetar app")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.text)
                                
                                Text("Apaga dados locais, preferências, tarefas, check-ins e faz o app voltar ao onboarding.")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(VenusTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: 10) {
                                if isResetting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                
                                Text(isResetting ? "Resetando..." : "Apagar tudo e recomeçar")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(isResetting)
                    }
                    .padding(20)
                    .solidCardStyle(cornerRadius: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
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

#Preview {
    SettingsView()
}
