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
    /// Agente separado e reutilizável para as perguntas (modelo gratuito do OpenRouter).
    private let questionAgent: any VenusQuestionGenerating = VenusQuestionAgent()
    private let healthKitService: HealthKitServiceProtocol = DependencyContainer.shared.makeHealthKitService()
    
    /// Total de perguntas dinâmicas antes de seguir para a permissão de saúde.
    private let totalDynamicQuestions = 2
    
    /// Perguntas locais usadas se o agente falhar — nunca mostram processo da IA.
    private let localFallbackQuestions = [
        "O que tem trazido mais tranquilidade para você ultimamente?",
        "Quando você sente que o dia finalmente desacelera?",
        "O que você gostaria que fosse mais leve na sua rotina?",
        "Há algo que te faz sentir mais presente agora?",
        "Como você costuma cuidar de si quando o dia fica pesado?"
    ]
    
    /// Reações curtas e calorosas — apenas texto de acolhimento, nunca de processo.
    private let empathyLines = [
        "Entender seu ritmo ajuda a calibrar seus dias.",
        "Cada resposta sua traz um pouco mais de clareza.",
        "É bom conhecer mais da sua mente, uma pergunta por vez."
    ]
    
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
        .transition(stepTransition)
        .zIndex(1)
    }

    private var conversationalFlowView: some View {
        HStack {
            Spacer(minLength: 0)
            ZStack(alignment: .top) {
                contentView
                    .safeAreaPadding(.top, 98)
                    .safeAreaPadding(.bottom, 16)

                topHUDView
                    .safeAreaPadding(.top, 10)
            }
            // O CTA vive dentro do safe area: com teclado aberto ele sobe junto
            // e nunca fica escondido atrás dele.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomControlsView
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
            ZStack {
                ScrollView(showsIndicators: false) {
                    currentStepView
                        .id(currentStep)
                        .transition(stepTransition)
                        .safeAreaPadding(.top, 132)
                        .safeAreaPadding(.bottom, 20)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomControlsView
                        .frame(maxWidth: .infinity)
                }
            }
            .overlay(alignment: .top) {
                OnboardingJourneyHeader(currentStep: currentStep)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(maxWidth: 500)
            Spacer(minLength: 0)
        }
    }

    private var topHUDView: some View {
        VStack(spacing: 6) {
            GlassEffectContainer(spacing: 8) {
                HStack {
                    topBackButton
                    Spacer()
                }
            }

            OnboardingJourneyHeader(currentStep: currentStep)
                .padding(.horizontal, 4)
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
                .frame(width: 44, height: 44)
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

                        if currentStep >= 1 && currentStep <= 4 {
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
                // Teclado aberto: rola até o campo ativo sem tirar o CTA da tela.
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        if currentStep == 3 {
                            scrollProxy.scrollTo("step_3_\(dynamicQuestionCount)", anchor: .bottom)
                        } else if currentStep == 1 || currentStep == 2 {
                            scrollProxy.scrollTo("step_\(currentStep)", anchor: .top)
                        }
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
                        .contentTransition(.opacity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(OnboardingPressableButtonStyle())
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: currentStep)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [Color.clear, palette.accent.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }

    private var nextButton: some View {
        let isBusy = isRequestingHealth || isLoadingAIProfile

        return Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            goToNextStep()
        } label: {
            OnboardingJourneyCTALabel(
                title: nextButtonTitle,
                systemImage: nextButtonIcon,
                isLoading: isBusy
            )
        }
        .buttonStyle(OnboardingPressableButtonStyle())
        .disabled(!canProceed || isBusy)
        .opacity(canProceed ? 1 : 0.62)
        .accessibilityLabel(nextButtonTitle)
        .accessibilityHint(isBusy ? "Aguarde um instante." : "Avança para a próxima etapa.")
        .accessibilityAddTraits(.isButton)
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
                defaultQuestion: "Como é seu foco ao longo do dia?",
                placeholder: "Escreva um pouco sobre você...",
                tintColor: palette.accent,
                onContinue: {
                    if canProceed {
                        goToNextStep()
                    }
                }
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
            let initialContext = userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines)
            conversationHistory = [("Como costuma ser sua rotina e o que mais tem ocupado sua mente ultimamente?", initialContext)]
            dynamicQuestionCount = 1
            currentAnswerText = ""
            currentAIQuestion = nil
            isLoadingAIQuestion = true
            
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep = 3
            }
            
            fetchNextQuestion(index: 1)
            return
        }
        
        if currentStep == 3 {
            let answer = currentAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
            let question = currentAIQuestion?.nextQuestion ?? fallbackQuestion(for: max(1, dynamicQuestionCount))
            conversationHistory.append((question, answer))
            
            // Quantidade fixa e local de perguntas — sem depender de sinal da IA.
            if dynamicQuestionCount >= totalDynamicQuestions {
                advanceToHealthStep()
                return
            }
            
            // Próxima pergunta dinâmica com transição fluida.
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                dynamicQuestionCount += 1
                currentAnswerText = ""
                currentAIQuestion = nil
                isLoadingAIQuestion = true
            }
            
            fetchNextQuestion(index: dynamicQuestionCount)
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
    
    // MARK: - Perguntas dinâmicas (agente separado do chat)

    private func fetchNextQuestion(index: Int) {
        // Contexto é calculado antes da Task para evitar capturar a view no chamado assíncrono.
        let context = profileContext()
        let answers = answeredSoFar()
        let fallback = fallbackQuestion(for: index)
        let empathy = VenusTextSanitizer.sanitize(empathyLine(for: index))

        Task {
            let rawQuestion: String
            do {
                rawQuestion = try await questionAgent.generateQuestion(
                    profileContext: context,
                    answeredSoFar: answers
                )
            } catch {
                rawQuestion = fallback
            }

            // Defesa extra: nada de JSON, tags de raciocínio ou prefixos na UI.
            let clean = VenusTextSanitizer.sanitize(rawQuestion)

            await MainActor.run {
                self.currentAIQuestion = AIOnboardingQuestionResponse(
                    empathyReaction: empathy,
                    nextQuestion: clean.isEmpty ? fallback : clean,
                    suggestedTone: nil,
                    hasEnoughContext: false
                )
                if self.userProfile.coachingTone.isEmpty {
                    self.userProfile.coachingTone = "Acolhedor"
                }
                self.isLoadingAIQuestion = false
            }
        }
    }

    /// Contexto rico e atualizado para o agente de perguntas.
    private func profileContext() -> String {
        var lines: [String] = []

        let name = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { lines.append("Nome: \(name)") }
        if !userProfile.gender.isEmpty { lines.append("Identificação: \(userProfile.gender)") }
        if !userProfile.primaryGoal.isEmpty { lines.append("Objetivo: \(userProfile.primaryGoal)") }
        if !userProfile.improvementAreas.isEmpty {
            lines.append("Áreas de melhoria: \(userProfile.improvementAreas.joined(separator: ", "))")
        }

        let initial = conversationHistory.first?.answer
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !initial.isEmpty { lines.append("Contexto inicial: \(initial)") }

        return lines.joined(separator: "\n")
    }

    private func answeredSoFar() -> [String] {
        conversationHistory
            .map { $0.answer }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func fallbackQuestion(for index: Int) -> String {
        localFallbackQuestions[(max(1, index) - 1) % localFallbackQuestions.count]
    }

    private func empathyLine(for index: Int) -> String {
        empathyLines[(max(1, index) - 1) % empathyLines.count]
    }
    
    private func advanceToHealthStep() {
        compileAnswersToProfile()
        preloadAIProfile()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            currentStep = 4
        }
    }

    private func advanceToRevealStep() {
        hideKeyboard()
        // Conclusão da coleta: confirmação tátil suave.
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        userProfile.isOnboardingComplete = true
        Task {
            let repo = DependencyContainer.shared.makeUserProfileRepository()
            try? await repo.save(profile: userProfile)
        }
    }
}

#Preview {
    OnboardingContainer(userProfile: UserProfile())
}
