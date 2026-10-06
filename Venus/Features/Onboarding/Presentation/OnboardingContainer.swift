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
    
    // Dynamic Conversation Answers
    @State private var initialRhythmAnswer: String = ""
    @State private var focusFrictionAnswer: String = ""
    @State private var recoverySleepAnswer: String = ""
    @State private var goalsOptimizationAnswer: String = ""
    
    // AI Responses
    @State private var aiQuestion1: AIOnboardingQuestionResponse? = nil
    @State private var aiQuestion2: AIOnboardingQuestionResponse? = nil
    @State private var aiQuestion3: AIOnboardingQuestionResponse? = nil
    @State private var isLoadingAIQuestion: Bool = false
    @State private var aiProfileResult: AIOnboardingProfileResponse? = nil
    @State private var isLoadingAIProfile: Bool = false
    
    // HealthKit
    @State private var isRequestingHealth: Bool = false
    
    private let totalQuestionSteps = 6 // Steps 1, 2, 3, 4, 5, 6
    private let venusAI: VenusAIServiceProtocol = DependencyContainer.shared.makeVenusAIService()
    private let healthKitService: HealthKitServiceProtocol = DependencyContainer.shared.makeHealthKitService()
    
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
            return !userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3:
            return !focusFrictionAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 4:
            return !recoverySleepAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 5:
            return !goalsOptimizationAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        case 2, 3, 4, 5:
            return "Avançar"
        case 6:
            return "Conectar Apple Saúde"
        case 7:
            return "Entrar no Meu Espaço"
        default:
            return "Continuar"
        }
    }
    
    private var nextButtonIcon: String {
        switch currentStep {
        case 6:
            return "heart.fill"
        case 7:
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
            } else if currentStep >= 1 && currentStep <= 6 {
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

                        if currentStep >= 1 && currentStep <= 5 {
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
        VStack(spacing: 8) {
            nextButton
            
            if currentStep == 6 {
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
                text: $focusFrictionAnswer,
                aiQuestion: aiQuestion1,
                isLoadingAI: isLoadingAIQuestion,
                defaultQuestion: "Em que momentos sua mente funciona melhor e o que costuma drenar seu foco?",
                placeholder: "Conte sobre seus picos de clareza, distrações ou onde surgem as maiores sobrecargas...",
                tintColor: VenusTheme.accentBlue
            )
        case 4:
            AIDeepeningStep(
                text: $recoverySleepAnswer,
                aiQuestion: aiQuestion2,
                isLoadingAI: isLoadingAIQuestion,
                defaultQuestion: "Quando chega a noite, o que mais impede sua mente de desligar e descansar?",
                placeholder: "Conte sobre a qualidade do seu sono, hábitos noturnos e como você recarrega a bateria...",
                tintColor: VenusTheme.accentPurple
            )
        case 5:
            AIDeepeningStep(
                text: $goalsOptimizationAnswer,
                aiQuestion: aiQuestion3,
                isLoadingAI: isLoadingAIQuestion,
                defaultQuestion: "Se você pudesse transformar um hábito ou momento da rotina, qual seria?",
                placeholder: "Ex: Foco profundo sem culpa, noites sem telas, mais constância ou calma sob pressão...",
                tintColor: VenusTheme.accentOrange
            )
        case 6:
            HealthPermissionsStep(onContinue: {
                advanceToRevealStep()
            })
        case 7:
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
            // Save initial rhythm answer and request AI Question 1 (Focus & Mental Frictions)
            initialRhythmAnswer = userProfile.contextNote
            isLoadingAIQuestion = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 3
            }
            
            Task {
                do {
                    let history = [("Como costuma ser seu ritmo e energia no dia a dia?", userProfile.contextNote)]
                    let aiResponse = try await venusAI.generateNextOnboardingQuestion(
                        userName: userProfile.name,
                        conversationHistory: history,
                        questionIndex: 2
                    )
                    await MainActor.run {
                        self.aiQuestion1 = aiResponse
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
            // Request AI Question 2 (Sleep & Biological Recovery)
            isLoadingAIQuestion = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 4
            }
            
            Task {
                do {
                    let history = [
                        ("Como costuma ser seu ritmo e energia?", userProfile.contextNote),
                        ("Como sua mente opera e onde estão as fricções de foco?", focusFrictionAnswer)
                    ]
                    let aiResponse = try await venusAI.generateNextOnboardingQuestion(
                        userName: userProfile.name,
                        conversationHistory: history,
                        questionIndex: 3
                    )
                    await MainActor.run {
                        self.aiQuestion2 = aiResponse
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
        
        if currentStep == 4 {
            // Request AI Question 3 (Optimization & Daily Levers)
            isLoadingAIQuestion = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 5
            }
            
            Task {
                do {
                    let history = [
                        ("Ritmo e energia", userProfile.contextNote),
                        ("Foco e fricções mentais", focusFrictionAnswer),
                        ("Sono e descanso", recoverySleepAnswer)
                    ]
                    let aiResponse = try await venusAI.generateNextOnboardingQuestion(
                        userName: userProfile.name,
                        conversationHistory: history,
                        questionIndex: 4
                    )
                    await MainActor.run {
                        self.aiQuestion3 = aiResponse
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
        
        if currentStep == 5 {
            // Compile all answers into userProfile
            compileAnswersToProfile()
            
            // Preload AI profile in background while user is on Health step
            preloadAIProfile()
            
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 6
            }
            return
        }
        
        if currentStep == 6 {
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
        
        if currentStep == 7 {
            finishOnboarding()
        }
    }
    
    private func compileAnswersToProfile() {
        var notes: [String] = []
        let initialRhythm = initialRhythmAnswer.isEmpty ? userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines) : initialRhythmAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !initialRhythm.isEmpty {
            notes.append("• Ritmo & Energia Basal: \(initialRhythm)")
        }
        let friction = focusFrictionAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !friction.isEmpty {
            notes.append("• Foco & Fricções: \(friction)")
        }
        let recovery = recoverySleepAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !recovery.isEmpty {
            notes.append("• Sono & Recuperação: \(recovery)")
        }
        let goal = goalsOptimizationAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !goal.isEmpty {
            notes.append("• Alavanca & Otimização: \(goal)")
            userProfile.primaryGoal = goal
        }
        
        userProfile.contextNote = notes.joined(separator: "\n")
        userProfile.improvementAreas = [friction, recovery].filter { !$0.isEmpty }
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
    
    private func advanceToRevealStep() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            currentStep = 7
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
