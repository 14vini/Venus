//
//  OnboardingMascotCompanionView.swift
//  Venus
//
//  Created by Kaua on 04/10/26.
//

import SwiftUI

struct OnboardingMascotCompanionView: View {
    let currentStep: Int
    @Binding var userProfile: UserProfile
    var isVoiceRecording: Bool = false
    var isTextFocused: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Computed Mascot State & Mood
    
    private var effectiveMood: MoodType {
        switch currentStep {
        case 1:
            return .happy
        case 2:
            return .calm
        case 3:
            return .calm
        case 4:
            return .happy
        default:
            return .happy
        }
    }
    
    private var effectiveState: VenusMascotState {
        switch currentStep {
        case 1:
            return userProfile.name.isEmpty ? .welcoming : .celebrating
        case 2:
            if isVoiceRecording { return .listening }
            return userProfile.contextNote.isEmpty ? .curious : .empathetic
        case 3:
            if isVoiceRecording { return .listening }
            return .thinking
        case 4:
            return .celebrating
        default:
            return .welcoming
        }
    }
    
    private var speechText: String {
        switch currentStep {
        case 1:
            let name = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                return "Que alegria te conhecer, \(name)! É um prazer ter você aqui ✨"
            }
            return "Oi! Como você prefere que eu te chame?"
            
        case 2:
            if isVoiceRecording {
                return "Estou te ouvindo com carinho... pode desabafar 🎙️"
            }
            if !userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Obrigada por se abrir comigo. É muito bom poder te ouvir 🤍"
            }
            let name = userProfile.name.isEmpty ? "" : ", \(userProfile.name)"
            return "Como você está se sentindo hoje\(name)? Pode falar ou digitar livremente ✨"
            
        case 3:
            if isVoiceRecording {
                return "Pode falar, estou prestando atenção em cada detalhe 🎙️"
            }
            return "Estou sintonizando com o seu momento para entender onde te dar mais apoio 🌿"
            
        case 4:
            return "Seu espaço está pronto! Seja muito bem-vindo(a) 🤍"
            
        default:
            return "Estou pronta para começar!"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Interactive 2.5D Mascot
            VenusMoodOrb(
                mood: effectiveMood,
                state: effectiveState,
                size: 80,
                showFace: true,
                showHands: true,
                showShadow: true,
                isInteractive: true
            )
            .frame(width: 80, height: 80)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.06), radius: 8, x: 0, y: 3)
            
            // Reactive Speech Bubble
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(VenusTheme.primary)
                    Text("Venus")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.primary)
                }
                
                Text(speechText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: speechText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(colorScheme == .dark ? 0.85 : 0.95)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.18 : 0.28),
                                        Color.clear,
                                        Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: effectiveState)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: effectiveMood)
    }
}
