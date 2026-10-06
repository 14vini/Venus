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
    
    // AI Dynamic Data
    @State private var aiQuestionResult: AIOnboardingQuestionResponse? = nil
    @State private var isLoadingAIQuestion: Bool = false
    @State private var aiProfileResult: AIOnboardingProfileResponse? = nil
    @State private var isLoadingAIProfile: Bool = false
    
    private let totalQuestionSteps = 3 // Steps 1, 2, 3
    private let venusAI: VenusAIServiceProtocol = DependencyContainer.shared.makeVenusAIService()
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var bottomControlsHeight: CGFloat = 0
    
    init(userProfile: UserProfile, initialStep: Int = 0) {
        let safeInitialStep = min(max(initialStep, 0), 4)
        _userProfile = State(initialValue: userProfile)
        _currentStep = State(initialValue: safeInitialStep)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return !userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3:
            return true // Opcional ou preenchido
        default:
            return true
        }
    }
    
    private var nextButtonTitle: String {
        switch currentStep {
        case 0:
            return "Começar"
        case 1:
            return "Continuar"
        case 2:
            return "Avançar"
        case 3:
            if userProfile.improvementAreas.isEmpty {
                return "Pular"
            }
            return "Continuar"
        case 4:
            return "Entrar no Meu Espaço"
        default:
            return "Continuar"
        }
    }
    
    private var nextButtonIcon: String {
        switch currentStep {
        case 4:
            return "arrow.right.circle.fill"
        default:
            return "chevron.right"
        }
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

            if currentStep == 0 {
                presentationStepView
            } else if currentStep >= 1 && currentStep <= 3 {
                conversationalFlowView
            } else {
                revealStepView
            }
        }
    }

    // MARK: - Views
    
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

    private var conversationalFlowView: some View {
        HStack {
            Spacer(minLength: 0)
            ZStack(alignment: .top) {
                contentView
                    .safeAreaPadding(.top, 74)
                    .safeAreaPadding(.bottom, max(110, bottomControlsHeight + 16))

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

    private var revealStepView: some View {
        HStack {
            Spacer(minLength: 0)
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    currentStepView
                        .id(currentStep)
                        .transition(stepTransition)
                        .safeAreaPadding(.top, 40)
                        .safeAreaPadding(.bottom, max(120, bottomControlsHeight + 20))
                }
                
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
            
            VenusProgressBar(
                currentStep: currentStep,
                totalSteps: totalQuestionSteps,
                tint: palette.accent
            )
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
                .frame(width: 38, height: 38)
                .contentShape(Circle())
                .glassEffect(.clear, in: Circle())
        }
        .buttonStyle(.plain)
        .buttonStyle(OnboardingPressableButtonStyle())
        .accessibilityLabel("Voltar")
    }

    private var contentView: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        Color.clear
                            .frame(height: 1)
                            .id("top")

                        if currentStep >= 1 && currentStep <= 3 {
                            OnboardingMascotCompanionView(
                                currentStep: currentStep,
                                userProfile: $userProfile
                            )
                            .padding(.top, 4)
                        }

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
            nextButton
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .readHeight { height in
            bottomControlsHeight = height
        }
    }

    private var nextButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            goToNextStep()
        } label: {
            HStack(spacing: 8) {
                if isLoadingAIProfile {
                    ProgressView()
                        .tint(.white)
                    Text("Preparando seu espaço...")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                } else {
                    Text(nextButtonTitle)
                        .font(.system(.headline, design: .rounded).weight(.black))
                    Image(systemName: nextButtonIcon)
                        .font(.system(size: 14, weight: .black))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
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
                color: canProceed ? palette.accent.opacity(colorScheme == .dark ? 0.24 : 0.28) : .clear,
                radius: 16,
                x: 0,
                y: 10
            )
        }
        .buttonStyle(.plain)
        .buttonStyle(OnboardingPressableButtonStyle())
        .disabled(!canProceed || isLoadingAIProfile)
        .opacity(canProceed ? 1 : 0.70)
        .accessibilityLabel(nextButtonTitle)
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0:
            PresentationView(onNext: { withAnimation { currentStep = 1 } })
        case 1:
            IdentityStep(userProfile: $userProfile, onSubmit: {
                if canProceed {
                    goToNextStep()
                }
            })
        case 2:
            InitialFeelingsStep(userProfile: $userProfile, onContinue: {
                if canProceed {
                    goToNextStep()
                }
            })
        case 3:
            AIDeepeningStep(
                userProfile: $userProfile,
                aiQuestion: aiQuestionResult,
                isLoadingAI: isLoadingAIQuestion
            )
        case 4:
            EmotionalProfileRevealStep(
                userProfile: userProfile,
                aiProfile: aiProfileResult,
                onFinish: {
                    finishOnboarding()
                }
            )
        default:
            IdentityStep(userProfile: $userProfile)
        }
    }
    
    // MARK: - Navigation Logic
    
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
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 2
            }
            return
        }
        
        if currentStep == 2 {
            // Trigger AI question generation for Step 3
            isLoadingAIQuestion = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 3
            }
            
            Task {
                do {
                    let aiResponse = try await venusAI.generateNextOnboardingQuestion(
                        userName: userProfile.name,
                        userResponse: userProfile.contextNote
                    )
                    await MainActor.run {
                        self.aiQuestionResult = aiResponse
                        if let tone = aiResponse.suggestedTone {
                            self.userProfile.coachingTone = tone
                        }
                        self.isLoadingAIQuestion = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoadingAIQuestion = false
                    }
                }
            }
            return
        }
        
        if currentStep == 3 {
            // Prepare final profile for Step 4
            isLoadingAIProfile = true
            
            Task {
                do {
                    let profileResp = try await venusAI.generateOnboardingProfile(userProfile: userProfile)
                    await MainActor.run {
                        self.aiProfileResult = profileResp
                        self.isLoadingAIProfile = false
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                            self.currentStep = 4
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isLoadingAIProfile = false
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                            self.currentStep = 4
                        }
                    }
                }
            }
            return
        }
        
        if currentStep == 4 {
            finishOnboarding()
        }
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
