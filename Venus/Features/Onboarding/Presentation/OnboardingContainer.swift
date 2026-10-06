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
    
    // Dynamic Conversation State
    @State private var conversationHistory: [(question: String, answer: String)] = []
    @State private var currentAIQuestion: AIOnboardingQuestionResponse? = nil
    @State private var currentAnswerText: String = ""
    @State private var dynamicQuestionCount: Int = 0
    @State private var isLoadingAIQuestion: Bool = false
    
    // AI Profile & HealthKit
    @State private var aiProfileResult: AIOnboardingProfileResponse? = nil
    @State private var isLoadingAIProfile: Bool = false
    @State private var isRequestingHealth: Bool = false
    
    private let venusAI: VenusAIServiceProtocol = DependencyContainer.shared.makeVenusAIService()
    private let healthKitService: HealthKitServiceProtocol = DependencyContainer.shared.makeHealthKitService()
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var bottomControlsHeight: CGFloat = 0
    
    init(userProfile: UserProfile, initialStep: Int = 0) {
        let safeInitialStep = min(max(initialStep, 0), 5)
        _userProfile = State(initialValue: userProfile)
        _currentStep = State(initialValue: safeInitialStep)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            let hasName = !userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasGender = !userProfile.gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasName && hasGender
        case 2:
            return !userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3:
            return !currentAnswerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        case 2, 3:
            return "Avançar"
        case 4:
            return "Conectar Apple Saúde"
        case 5:
            return "Entrar no Meu Espaço"
        default:
            return "Continuar"
        }
    }
    
    private var nextButtonIcon: String {
        switch currentStep {
        case 4:
            return "heart.fill"
        case 5:
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
            } else if currentStep >= 1 && currentStep <= 4 {
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
                    .safeAreaPadding(.top, 70)
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
        HStack {
            topBackButton
            Spacer()
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
                            .id(currentStep == 3 ? "step_3_\(dynamicQuestionCount)" : "step_\(currentStep)")
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
                .onChange(of: dynamicQuestionCount) { _, _ in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scrollProxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
    }

    private var bottomControlsView: some View {
        VStack(spacing: 8) {
            nextButton
            
            if currentStep == 4 {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    advanceToRevealStep()
                } label: {
                    Text("Configurar depois")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundColor(VenusTheme.textSecondary)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
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
                if isRequestingHealth || isLoadingAIProfile {
                    ProgressView()
                        .tint(.white)
                    Text(isRequestingHealth ? "Conectando..." : "Preparando seu espaço...")
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
        .disabled(!canProceed || isRequestingHealth || isLoadingAIProfile)
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
                text: $currentAnswerText,
                aiQuestion: currentAIQuestion,
                isLoadingAI: isLoadingAIQuestion,
                defaultQuestion: "Como costuma ser seu foco e quais momentos do dia são mais produtivos para você?",
                placeholder: "Conte sobre como sua mente opera, momentos de clareza ou distrações...",
                tintColor: palette.accent
            )
        case 4:
            HealthPermissionsStep(onContinue: {
                advanceToRevealStep()
            })
        case 5:
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func goToPreviousStep() {
        hideKeyboard()
        if currentStep == 3 && conversationHistory.count > 1 {
            // Revert to previous dynamic question
            _ = conversationHistory.popLast()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                dynamicQuestionCount = max(1, dynamicQuestionCount - 1)
            }
            if let previous = conversationHistory.last {
                currentAnswerText = previous.answer
            }
            return
        }
        
        guard currentStep > 0 else { return }
        transitionDirection = -1
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            currentStep -= 1
        }
    }
    
    private func goToNextStep() {
        hideKeyboard()
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
            // Setup initial conversation history and fetch first dynamic AI question
            let initialRhythm = userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines)
            conversationHistory = [("Como costuma ser seu ritmo e energia no dia a dia?", initialRhythm)]
            dynamicQuestionCount = 1
            currentAnswerText = ""
            currentAIQuestion = nil
            isLoadingAIQuestion = true
            
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 3
            }
            
            fetchNextAIQuestion(index: 1)
            return
        }
        
        if currentStep == 3 {
            let answer = currentAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
            let question = currentAIQuestion?.nextQuestion ?? "Como costuma ser seu foco?"
            conversationHistory.append((question, answer))
            
            // Check if AI has enough context (minimum 2 questions, safety cap 5)
            let hasEnough = currentAIQuestion?.hasEnoughContext ?? false
            if (hasEnough && dynamicQuestionCount >= 2) || dynamicQuestionCount >= 5 {
                advanceToHealthStep()
                return
            }
            
            // Fetch next dynamic question with fluid animation
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                dynamicQuestionCount += 1
                currentAnswerText = ""
                currentAIQuestion = nil
                isLoadingAIQuestion = true
            }
            
            fetchNextAIQuestion(index: dynamicQuestionCount)
            return
        }
        
        if currentStep == 4 {
            // Request Apple HealthKit permissions
            isRequestingHealth = true
            Task {
                _ = try? await healthKitService.requestAuthorization()
                await MainActor.run {
                    self.isRequestingHealth = false
                    advanceToRevealStep()
                }
            }
            return
        }
        
        if currentStep == 5 {
            finishOnboarding()
        }
    }
    
    private func fetchNextAIQuestion(index: Int) {
        Task {
            do {
                let aiResponse = try await venusAI.generateNextOnboardingQuestion(
                    userName: userProfile.name,
                    conversationHistory: conversationHistory,
                    questionIndex: index
                )
                await MainActor.run {
                    if let tone = aiResponse.suggestedTone, !tone.isEmpty {
                        self.userProfile.coachingTone = tone
                    }
                    
                    // If AI deems it already has enough context and we have at least 2 questions answered
                    if (aiResponse.hasEnoughContext == true) && self.conversationHistory.count >= 2 {
                        self.advanceToHealthStep()
                    } else {
                        self.currentAIQuestion = aiResponse
                        self.isLoadingAIQuestion = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingAIQuestion = false
                }
            }
        }
    }
    
    private func advanceToHealthStep() {
        compileAnswersToProfile()
        preloadAIProfile()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            currentStep = 4
        }
    }
    
    private func advanceToRevealStep() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            currentStep = 5
        }
    }
    
    private func compileAnswersToProfile() {
        var summaryLines: [String] = []
        for (q, a) in conversationHistory {
            summaryLines.append("• Pergunta: \(q)\n  Resposta: \(a)")
        }
        userProfile.contextNote = summaryLines.joined(separator: "\n\n")
        
        if let lastAnswer = conversationHistory.last?.answer {
            userProfile.primaryGoal = lastAnswer
        }
        
        let answersOnly = conversationHistory.map { $0.answer }
        userProfile.improvementAreas = Array(answersOnly.prefix(3))
    }
    
    private func preloadAIProfile() {
        Task {
            do {
                let profileResp = try await venusAI.generateOnboardingProfile(userProfile: userProfile)
                await MainActor.run {
                    self.aiProfileResult = profileResp
                }
            } catch {
                print("⚠️ Falha ao pré-carregar perfil de onboarding: \(error)")
            }
        }
    }
    
    private func finishOnboarding() {
        compileAnswersToProfile()
        userProfile.isOnboardingComplete = true
        Task {
            let repo = DependencyContainer.shared.makeUserProfileRepository()
            try? await repo.save(profile: userProfile)
        }
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
