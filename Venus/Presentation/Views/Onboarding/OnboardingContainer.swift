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
    @State private var transitionDirection: Int = 1
    private let totalSteps = 8

    @Environment(\.colorScheme) private var colorScheme
    @State private var bottomControlsHeight: CGFloat = 0
    
    init(userProfile: UserProfile, initialStep: Int = 0) {
        let safeInitialStep = min(max(initialStep, 0), 8)
        _userProfile = State(initialValue: userProfile)
        _currentStep = State(initialValue: safeInitialStep)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1: return !userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !userProfile.primaryGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !userProfile.coachingTone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && userProfile.dailyTimeBudgetMinutes > 0
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
        case 2: return "Escolha seu foco, tom e tempo para continuar"
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

    private var palette: OnboardingVisualPalette {
        OnboardingVisualPalette.forStep(currentStep)
    }

    private var stepTransition: AnyTransition {
        let insertion: AnyTransition = transitionDirection >= 0 ?
            .move(edge: .trailing).combined(with: .opacity) :
            .move(edge: .leading).combined(with: .opacity)

        let removal: AnyTransition = transitionDirection >= 0 ?
            .move(edge: .leading).combined(with: .opacity) :
            .move(edge: .trailing).combined(with: .opacity)

        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    var body: some View {
        ZStack {
            OnboardingAnimatedBackground(palette: palette, isAnimated: true)
                .animation(.easeInOut(duration: 0.7), value: currentStep)

            if currentStep >= 2 {
                OnboardingMascotBackdrop(palette: palette)
                    .opacity(colorScheme == .dark ? 0.95 : 0.88)
                    .animation(.easeInOut(duration: 0.6), value: currentStep)
            }
            
            if currentStep == 0 {
                presentationStepView
            } else {
                onboardingStepsView
            }
        }
    }

    private var presentationStepView: some View {
        PresentationView(onNext: {
            transitionDirection = 1
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 1
            }
        })
        .transition(.opacity)
        .zIndex(1)
    }

	    private var onboardingStepsView: some View {
	        HStack {
	            Spacer(minLength: 0)
	            ZStack(alignment: .top) {
	                contentView
	                    .safeAreaPadding(.top, 86)
	                    .safeAreaPadding(.bottom, max(132, bottomControlsHeight + 24))

	                topHUDView
	                    .safeAreaPadding(.top, 10)
	            }
	            .overlay(alignment: .bottom) {
	                bottomControlsView
	                    .safeAreaPadding(.bottom, 12)
	                    .frame(maxWidth: .infinity)
	            }
	            .frame(maxWidth: .infinity, maxHeight: .infinity)
	            .frame(maxWidth: 500)
	            Spacer(minLength: 0)
	        }
	    }

	    private var topHUDView: some View {
	        HStack(spacing: 12) {
	            topBackButton
	            progressBarView
	                .allowsHitTesting(false)
	        }
	        .padding(.horizontal, 24)
	    }

	    private var topBackButton: some View {
	        Button {
	            UIImpactFeedbackGenerator(style: .light).impactOccurred()
	            goToPreviousStep()
	        } label: {
	            Image(systemName: "chevron.left")
	                .font(.system(size: 14, weight: .black))
	                .foregroundStyle(palette.accent)
	                .frame(width: 40, height: 40)
	                .contentShape(Circle())
	                .glassEffect(.clear, in: Circle())
	        }
	        .buttonStyle(.plain)
	        .buttonStyle(OnboardingPressableButtonStyle())
	        .accessibilityLabel("Voltar")
	    }

	    private var progressBarView: some View {
	        VenusProgressBar(currentStep: currentStep, totalSteps: totalSteps, tint: palette.accent)
	    }

    private var contentView: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 1)
                            .id("top")

                        currentStepView
                            .id(currentStep)
                            .transition(stepTransition)
                    }
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: currentStep) { _, _ in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scrollProxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
    }

    private var bottomControlsView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                bottomMessageView
                navigationButtonsView
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .background(bottomControlsBackground)
        .readHeight { height in
            bottomControlsHeight = height
        }
    }

    private var bottomControlsBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(colorScheme == .dark ? 0.78 : 0.92)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.16 : 0.24),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.overlay)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.34 : 0.10), radius: 22, x: 0, y: 10)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
    }

    @ViewBuilder
    private var bottomMessageView: some View {
        if !canProceed {
            Text(validationMessage)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if !helperMessage.isEmpty {
            Text(helperMessage)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var navigationButtonsView: some View {
        nextButton
    }

    private var nextButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            goToNextStep()
        } label: {
            HStack(spacing: 8) {
                Text(nextButtonTitle)
                    .font(.system(.headline, design: .rounded).weight(.black))
                Image(systemName: nextButtonIcon)
                    .font(.system(size: 14, weight: .black))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                (canProceed ? palette.buttonGradient : palette.disabledGradient),
                in: Capsule(style: .continuous)
            )
            .overlay(
                Capsule(style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.16 : 0.22),
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .blendMode(.overlay)
            )
            .shadow(
                color: canProceed ? palette.accent.opacity(colorScheme == .dark ? 0.22 : 0.26) : .clear,
                radius: 18,
                x: 0,
                y: 12
            )
        }
        .buttonStyle(.plain)
        .buttonStyle(OnboardingPressableButtonStyle())
        .disabled(!canProceed)
        .opacity(canProceed ? 1 : 0.72)
        .accessibilityLabel(nextButtonTitle)
        .accessibilityHint(currentStep == totalSteps ? "Finaliza o onboarding" : "Avança para a próxima etapa")
        .overlay(alignment: .top) {
            VenusGlassCrown(tint: palette.accent)
                .padding(.horizontal, 10)
                .padding(.top, 3)
                .allowsHitTesting(false)
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
        case 2: PersonalizationStep(userProfile: $userProfile)
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
        guard currentStep > 0 else { return }
        transitionDirection = -1
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            currentStep -= 1
        }
    }
    
    private func goToNextStep() {
        guard canProceed else { return }
        transitionDirection = 1
        
        if currentStep == 1 {
            userProfile.name = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if currentStep < totalSteps {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep += 1
            }
            return
        }
        
        userProfile.isOnboardingComplete = true
    }
    
}

private struct VenusGlassCrown: View {
    var tint: Color = VenusTheme.primary

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.22 : 0.34),
                        tint.opacity(colorScheme == .dark ? 0.12 : 0.18),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 16)
            .blur(radius: 0.2)
            .mask(
                Capsule(style: .continuous)
                    .padding(.horizontal, 6)
            )
            .opacity(0.9)
    }
}

private struct ViewHeightReader: ViewModifier {
    let onChange: (CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ViewHeightPreferenceKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(ViewHeightPreferenceKey.self, perform: onChange)
    }
}

private struct ViewHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func readHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        modifier(ViewHeightReader(onChange: onChange))
    }
}

#Preview {
    OnboardingContainer(userProfile: UserProfile())
}
