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
    private let questionnaireSteps = 4

    @Environment(\.colorScheme) private var colorScheme
    @State private var bottomControlsHeight: CGFloat = 0
    
    init(userProfile: UserProfile, initialStep: Int = 0) {
        let safeInitialStep = min(max(initialStep, 0), 7)
        _userProfile = State(initialValue: userProfile)
        _currentStep = State(initialValue: safeInitialStep)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return !userProfile.primaryGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !userProfile.improvementAreas.isEmpty
        case 3:
            return !userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 4:
            return !userProfile.coachingTone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && userProfile.dailyTimeBudgetMinutes > 0
        default:
            return true
        }
    }
    
    private var validationMessage: String {
        switch currentStep {
        case 1: return "Escolha como você está se sentindo para continuar"
        case 2: return "Selecione pelo menos um desafio para continuar"
        case 3: return "Digite seu nome para continuar"
        case 4: return "Escolha seu tom de conversa para continuar"
        default: return ""
        }
    }
    
    private var nextButtonTitle: String {
        if currentStep == questionnaireSteps {
            return "Calibrar Minha Venus"
        }
        return "Continuar"
    }
    
    private var nextButtonIcon: String {
        currentStep == questionnaireSteps ? "wand.and.stars" : "chevron.right"
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

            if currentStep >= 1 && currentStep <= 4 {
                OnboardingMascotBackdrop(palette: palette)
                    .opacity(colorScheme == .dark ? 0.95 : 0.88)
                    .animation(.easeInOut(duration: 0.6), value: currentStep)
            }
            
            if currentStep == 0 {
                presentationStepView
            } else if currentStep >= 1 && currentStep <= 4 {
                questionnaireFlowView
            } else {
                experienceFlowView
            }
        }
    }

    private var presentationStepView: some View {
        WelcomeView(onNext: {
            transitionDirection = 1
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 1
            }
        })
        .transition(.opacity)
        .zIndex(1)
    }

    private var questionnaireFlowView: some View {
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

    private var experienceFlowView: some View {
        HStack {
            Spacer(minLength: 0)
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    currentStepView
                        .id(currentStep)
                        .transition(stepTransition)
                        .safeAreaPadding(.top, currentStep == 5 ? 20 : 60)
                        .safeAreaPadding(.bottom, 30)
                }

                if currentStep == 6 {
                    HStack {
                        topBackButton
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .safeAreaPadding(.top, 10)
                }
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
        VenusProgressBar(currentStep: currentStep, totalSteps: questionnaireSteps, tint: palette.accent)
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
        .accessibilityHint(currentStep == questionnaireSteps ? "Inicia a calibração" : "Avança para a próxima etapa")
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0:
            WelcomeView(onNext: { withAnimation { currentStep = 1 } })
        case 1:
            InitialMoodStep(userProfile: $userProfile)
        case 2:
            RootStruggleStep(userProfile: $userProfile)
        case 3:
            IdentityStep(userProfile: $userProfile, onSubmit: {
                if canProceed {
                    goToNextStep()
                }
            })
        case 4:
            ToneCalibrationStep(userProfile: $userProfile)
        case 5:
            AICalibrationLoadingStep(
                userName: userProfile.name,
                tone: userProfile.coachingTone,
                onComplete: {
                    transitionDirection = 1
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        currentStep = 6
                    }
                }
            )
        case 6:
            EmotionalProfileRevealStep(
                userProfile: userProfile,
                onContinue: {
                    transitionDirection = 1
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        currentStep = 7
                    }
                }
            )
        case 7:
            FirstAhaMomentStep(
                userProfile: userProfile,
                onFinish: {
                    finishOnboarding()
                }
            )
        default:
            InitialMoodStep(userProfile: $userProfile)
        }
    }
    
    private func goToPreviousStep() {
        guard currentStep > 0 else { return }
        transitionDirection = -1
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            if currentStep == 6 {
                currentStep = 4 // skip backwards over loading step
            } else {
                currentStep -= 1
            }
        }
    }
    
    private func goToNextStep() {
        guard canProceed else { return }
        transitionDirection = 1
        
        if currentStep == 3 {
            userProfile.name = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if currentStep < 7 {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep += 1
            }
            return
        }
        
        finishOnboarding()
    }
    
    private func finishOnboarding() {
        userProfile.isOnboardingComplete = true
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
