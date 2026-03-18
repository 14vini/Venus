//
//  OnboardingContainer.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct OnboardingContainer: View {
    @State var userProfile: UserProfile
    @State private var currentStep: Int
    private let totalSteps = 8
    
    init(userProfile: UserProfile, initialStep: Int = 0) {
        let safeInitialStep = min(max(initialStep, 0), 8)
        _userProfile = State(initialValue: userProfile)
        _currentStep = State(initialValue: safeInitialStep)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1: return !userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return true // About Step is informational
        case 3: return !userProfile.interests.isEmpty
        case 4: return !userProfile.currentHobbies.isEmpty
        case 5: return !userProfile.desiredHobbies.isEmpty
        case 6: return isRoutineStepValid
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
        case 6: return "Ajuste os horários para continuar"
        case 7: return "Selecione pelo menos uma área para melhorar"
        case 8: return "Selecione pelo menos uma área emocional"
        default: return ""
        }
    }
    
    private var helperMessage: String {
        if currentStep == 6 && isRoutineStepSkipped {
            return "Opcional: você pode configurar sua rotina depois."
        }
        return ""
    }
    
    private var isRoutineStepSkipped: Bool {
        userProfile.workSchedule == nil && !userProfile.studySchedule.studies
    }
    
    private var isRoutineStepValid: Bool {
        let hasValidWorkSchedule: Bool
        if let workSchedule = userProfile.workSchedule, workSchedule.hasWork {
            hasValidWorkSchedule = OnboardingScheduleValidator.isValid(start: workSchedule.startTime, end: workSchedule.endTime)
        } else {
            hasValidWorkSchedule = true
        }
        
        let hasValidStudySchedule: Bool
        if userProfile.studySchedule.studies {
            hasValidStudySchedule = OnboardingScheduleValidator.isValid(
                start: userProfile.studySchedule.startTime,
                end: userProfile.studySchedule.endTime
            )
        } else {
            hasValidStudySchedule = true
        }
        
        return hasValidWorkSchedule && hasValidStudySchedule
    }
    
    private var nextButtonTitle: String {
        if currentStep == totalSteps {
            return "Concluir"
        }
        if currentStep == 6 && isRoutineStepSkipped {
            return "Pular"
        }
        return "Próximo"
    }
    
    private var nextButtonIcon: String {
        currentStep == totalSteps ? "checkmark.circle.fill" : "chevron.right"
    }
    
    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            if currentStep == 0 {
                PresentationView(onNext: {
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
                        VenusProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                            .frame(height: 80)
                            .padding(.horizontal, 24)
                        
                        ScrollViewReader { scrollProxy in
                            // Content Area - Scrollable
                            ScrollView(showsIndicators: false) {
                                Color.clear
                                    .frame(height: 1)
                                    .id("top")
                                
                                currentStepView
                                    .id(currentStep)
                                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                            }
                            .scrollDismissesKeyboard(.interactively)
                            .onChange(of: currentStep) { _, _ in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    scrollProxy.scrollTo("top", anchor: .top)
                                }
                            }
                        }
                        
                        // Bottom Controls - Fixed Height
                        VStack(spacing: 0) {
                            // Validation Message
                            VStack(spacing: 2) {
                                if !canProceed {
                                    Text(validationMessage)
                                        .font(.caption)
                                        .foregroundColor(VenusTheme.textSecondary)
                                } else if !helperMessage.isEmpty {
                                    Text(helperMessage)
                                        .font(.caption)
                                        .foregroundColor(VenusTheme.textSecondary)
                                }
                            }
                            .frame(minHeight: 20)
                            .padding(.horizontal, 24)
                            
                            // Navigation Buttons
                            HStack(spacing: 12) {
                                Button {
                                    goToPreviousStep()
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
                                .accessibilityLabel("Voltar")
                                .accessibilityHint("Retorna para a etapa anterior")
                                
                                Button {
                                    goToNextStep()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(nextButtonTitle)
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                        Image(systemName: nextButtonIcon)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(canProceed ? VenusTheme.darkGreen : Color.gray.opacity(0.5))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                                .disabled(!canProceed)
                                .accessibilityLabel(nextButtonTitle)
                                .accessibilityHint(currentStep == totalSteps ? "Finaliza o onboarding" : "Avança para a próxima etapa")
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
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
        case 0: PresentationView(onNext: { withAnimation { currentStep = 1 } })
        case 1: WelcomeStep(userProfile: $userProfile, onSubmit: {
            if canProceed {
                goToNextStep()
            }
        })
        case 2: AboutStep(userProfile: $userProfile)
        case 3: InterestsStep(userProfile: $userProfile)
        case 4: HobbiesStep(userProfile: $userProfile)
        case 5: DesiredHobbiesStep(userProfile: $userProfile)
        case 6: WorkScheduleStep(userProfile: $userProfile)
        case 7: ImprovementAreasStep(userProfile: $userProfile)
        case 8: EmotionalAreaStep(userProfile: $userProfile)
        default: WelcomeStep(userProfile: $userProfile)
        }
    }
    
    private func goToPreviousStep() {
        guard currentStep > 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
    }
    
    private func goToNextStep() {
        guard canProceed else { return }
        
        if currentStep == 1 {
            userProfile.name = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
            return
        }
        
        userProfile.isOnboardingComplete = true
    }
    
}

#Preview {
    OnboardingContainer(userProfile: UserProfile())
}
