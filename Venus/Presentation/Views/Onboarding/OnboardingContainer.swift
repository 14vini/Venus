//
//  OnboardingContainer.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct OnboardingContainer: View {
    @State var userProfile: UserProfile
    @State private var currentStep = 0
    
    private var canProceed: Bool {
        switch currentStep {
        case 1: return !userProfile.name.isEmpty
        case 2: return true // About Step is informational
        case 3: return !userProfile.interests.isEmpty
        case 4: return !userProfile.currentHobbies.isEmpty
        case 5: return !userProfile.desiredHobbies.isEmpty
        case 6: return true // Optional step
        case 7: return !userProfile.improvementAreas.isEmpty
        case 8: return !userProfile.emotionalAreas.isEmpty
        default: return true
        }
    }
    
    private var validationMessage: String {
        switch currentStep {
        case 1: return "Digite seu nome para continuar"
        case 2: return ""
        case 3: return "Selecione pelo menos um interesse"
        case 4: return "Selecione pelo menos um hobby atual"
        case 5: return "Selecione pelo menos um hobby que deseja aprender"
        case 6: return "" // Optional
        case 7: return "Selecione pelo menos uma área para melhorar"
        case 8: return "Selecione pelo menos uma área emocional"
        default: return ""
        }
    }
    
    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            if currentStep == 0 {
                VenusPresentationView(onNext: {
                    withAnimation {
                        currentStep = 1
                    }
                })
                .transition(.opacity)
                .zIndex(1)
            } else {
                HStack {
                    Spacer(minLength: 0)
                    VStack(spacing: 0) {
                        // Progress Bar - Fixed Height
                        VenusProgressBar(currentStep: currentStep, totalSteps: 8)
                            .frame(height: 80)
                            .padding(.horizontal, 24)
                        
                        // Content Area - Scrollable
                        ScrollView(showsIndicators: false) {
                            currentStepView
                                .id(currentStep)
                                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                        }
                        
                        // Bottom Controls - Fixed Height
                        VStack(spacing: 0) {
                            // Validation Message
                            Text(canProceed ? "" : validationMessage)
                                .font(.caption)
                                .foregroundColor(VenusTheme.textSecondary)
                                .frame(height: 20)
                                .padding(.horizontal, 24)
                            // Navigation Buttons
                            HStack(spacing: 12) {
                                Button {
                                    if currentStep > 1 {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentStep -= 1
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("Voltar")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(currentStep == 1 ? VenusTheme.chipBackground.opacity(0.5) : VenusTheme.chipBackground)
                                    .foregroundColor(currentStep == 1 ? VenusTheme.textSecondary : VenusTheme.text)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(VenusTheme.chipBorder, lineWidth: 1)
                                    )
                                }
                                .disabled(currentStep == 1)
                                Button {
                                    if currentStep < 8 {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentStep += 1
                                        }
                                    } else {
                                        userProfile.isOnboardingComplete = true
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(currentStep == 8 ? "Concluir" : (currentStep == 6 && userProfile.workSchedule == nil ? "Pular" : "Próximo"))
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                        Image(systemName: currentStep == 8 ? "checkmark.circle.fill" : "chevron.right")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(canProceed ? VenusTheme.darkGreen : Color.gray.opacity(0.5))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                                .disabled(!canProceed)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxWidth: 500)
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0: VenusPresentationView(onNext: { withAnimation { currentStep = 1 } })
        case 1: WelcomeStep(userProfile: $userProfile)
        case 2: VenusAboutStep(userProfile: $userProfile)
        case 3: VenusInterestsStep(userProfile: $userProfile)
        case 4: VenusHobbiesStep(userProfile: $userProfile)
        case 5: VenusDesiredHobbiesStep(userProfile: $userProfile)
        case 6: VenusWorkScheduleStep(userProfile: $userProfile)
        case 7: VenusImprovementAreasStep(userProfile: $userProfile)
        case 8: VenusEmotionalAreaStep(userProfile: $userProfile)
        default: WelcomeStep(userProfile: $userProfile)
        }
    }
    
}

#Preview {
    OnboardingContainer(userProfile: UserProfile())
}
