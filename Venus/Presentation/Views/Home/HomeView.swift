//
//  HomeView.swift
//  Venus
//
//  Refactored by Kaua on 18/03/26.
//

import SwiftUI

struct HomeView: View {
    let userName: String

    @Environment(\.colorScheme) var colorScheme
    @State private var showVenusChat = false
    @State private var showChatHistory = false
    @State private var showVenusProPlans = false
    @State private var actionReasonAction: NextBestAction?
    @State private var showCheckInHint = false
    @State private var checkInHintSequence = 0

    @AppStorage(LocalSubscriptionStatusProvider.planKey) private var isPremiumTestEnabled = false
    @AppStorage("home.lastPracticeStartedDate") private var lastPracticeStartedDate = ""
    @AppStorage("home.preferHighImpactAction") private var preferHighImpactAction = false
    @AppStorage("home.hasSeenCheckInFloatingHint") private var hasSeenCheckInFloatingHint = false
    @AppStorage("home.hasSeenFirstLaunchGuide") private var hasSeenFirstLaunchGuide = false

    private let feedbackStore = DependencyContainer.shared.makeBehaviorFeedbackStore()

    @StateObject private var viewModel = HomeViewModel(
        patternEngineUseCase: DependencyContainer.shared.makePatternEngineUseCase(),
        checkInAllowanceUseCase: DependencyContainer.shared.makeCheckInAllowanceUseCase(),
        moodRepository: DependencyContainer.shared.makeMoodRepository()
    )
    @StateObject private var inlineCheckInViewModel = DependencyContainer.shared.makeMoodCheckInViewModel()

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.moodMintStrong,
                secondaryAccent: VenusTheme.moodSage,
                tertiaryAccent: VenusTheme.accentGreen,
                isAnimated: false
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HomeImmersiveCheckInHeroSection(
                        selectedMood: heroSelectedMood,
                        hasCheckedInToday: viewModel.hasCheckedInToday,
                        progressLabel: ritualProgressLabel,
                        statusLabel: checkInStatusHighlight.title,
                        isSelectionLocked: viewModel.hasCheckedInToday && !viewModel.checkInAllowance.canCheckIn,
                        onSelectMood: handleInlineMoodSelection
                    )

                    HomeReflectionsPreviewSection(
                        mood: viewModel.todayMoodType,
                        intensity: viewModel.todayMoodIntensity,
                        tags: viewModel.todayMoodTags,
                        bodySignals: viewModel.todayMoodBodySignals,
                        energyLevel: viewModel.todayMoodEnergyLevel,
                        affectedArea: viewModel.todayMoodAffectedArea,
                        weeklyTrend: viewModel.weeklyTrend,
                        patternAlert: viewModel.patternAlert,
                        weeklyInsights: viewModel.weeklyInsights,
                        action: displayedActionModel,
                        isLoadingInsights: viewModel.isLoadingInsights,
                        onReasonTap: handleActionReasonTap
                    )
                }
                .padding(.horizontal,20)
                .padding(.top, 14)
                .padding(.bottom, 160)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            HomeCheckInFloatingOverlay(
                showHint: showCheckInHint,
                hintTitle: checkInHintTitle,
                hintBody: checkInHintBody,
                buttonTitle: checkInFloatingButtonTitle,
                buttonSubtitle: checkInFloatingButtonSubtitle,
                buttonIcon: checkInFloatingButtonIcon,
                isProPrompt: viewModel.hasCheckedInToday && !viewModel.checkInAllowance.canCheckIn,
                isDisabled: floatingButtonDisabled,
                action: handleCheckInAction
            )
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Olá, \(userName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showChatHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showVenusChat = true
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
            }
        }
        .sheet(isPresented: $viewModel.showMoodCheckIn, onDismiss: {
            inlineCheckInViewModel.startNewCheckIn()
        }) {
            NavigationStack {
                MoodCheckInView(
                    viewModel: inlineCheckInViewModel,
                    ritualProgressLabel: ritualProgressLabel,
                    onCompleted: viewModel.handleMoodCheckInCompleted
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showVenusChat) {
            VenusChatView()
        }
        .sheet(isPresented: $showChatHistory) {
            ChatHistoryView { _ in
                showChatHistory = false
                showVenusChat = true
            }
        }
        .sheet(isPresented: $viewModel.showUpgradePrompt) {
            PremiumUpgradeSheet(
                freeDailyLimit: viewModel.freePlanDailyLimit,
                onDismiss: { viewModel.showUpgradePrompt = false },
                onSeePlans: {
                    viewModel.showUpgradePrompt = false
                    showVenusProPlans = true
                }
            )
        }
        .sheet(isPresented: $showVenusProPlans) {
            VenusProPlansSheet(
                freeDailyLimit: viewModel.freePlanDailyLimit,
                onContinueToSupport: {
                    showVenusProPlans = false
                    showVenusChat = true
                }
            )
        }
        .navigationDestination(item: $actionReasonAction) { actionModel in
            HomeActionReasonView(
                actionModel: actionModel,
                weeklyInsights: viewModel.weeklyInsights,
                patternAlert: viewModel.patternAlert,
                actionWhy: viewModel.actionWhy,
                proForecast: viewModel.proMoodForecast,
                isPro: viewModel.checkInAllowance.plan == .pro,
                confidenceInsight: viewModel.confidenceInsight,
                triggerRecoveryInsight: viewModel.triggerRecoveryInsight,
                alternativeActions: displayedAlternativeActions,
                exploreSuggestions: viewModel.exploreActionSuggestions
            )
        }
        .onChange(of: viewModel.isCriticalRiskNow) { _, isCritical in
            if isCritical {
                preferHighImpactAction = true
            }
        }
        .onChange(of: viewModel.hasCheckedInToday) { _, _ in
            presentCheckInHint()
        }
        .onChange(of: viewModel.checkInAllowance.usedToday) { _, _ in
            presentCheckInHint()
        }
        .onChange(of: isPremiumTestEnabled) { _, _ in
            viewModel.refreshAfterPlanToggle()
        }
        .onAppear {
            presentCheckInHint()
        }
    }

    // MARK: - Computed helpers

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var hasStartedPracticeToday: Bool {
        lastPracticeStartedDate == todayKey
    }

    private var hasInsightReady: Bool {
        displayedActionModel != nil
            || viewModel.actionWhy != nil
            || viewModel.weeklyInsights != nil
            || viewModel.patternAlert != nil
    }

    private var headerHighlights: [HomeHeaderHighlight] {
        var items = [
            HomeHeaderHighlight(
                title: "\(viewModel.checkInStreakDays) dias",
                systemImage: "flame.fill",
                tint: VenusTheme.accentOrange
            )
        ]

        if viewModel.hasCheckedInToday {
            items.append(
                HomeHeaderHighlight(
                    title: "check-in feito",
                    systemImage: "heart.fill",
                    tint: VenusTheme.accentPink
                )
            )
        }

        if hasInsightReady {
            items.append(
                HomeHeaderHighlight(
                    title: "resumo pronto",
                    systemImage: "sparkles",
                    tint: VenusTheme.accentBlue
                )
            )
        }

        if hasStartedPracticeToday {
            items.append(
                HomeHeaderHighlight(
                    title: "ação iniciada",
                    systemImage: "play.fill",
                    tint: VenusTheme.accentGreen
                )
            )
        } else if displayedActionModel != nil {
            items.append(
                HomeHeaderHighlight(
                    title: "ação pronta",
                    systemImage: "play.circle.fill",
                    tint: VenusTheme.accentGreen
                )
            )
        }

        return items
    }

    private var checkInStatusHighlight: HomeHeaderHighlight {
        HomeHeaderHighlight(
            title: viewModel.hasCheckedInToday ? "feito hoje" : "pendente hoje",
            systemImage: viewModel.hasCheckedInToday ? "checkmark.circle.fill" : "circle.dashed",
            tint: viewModel.hasCheckedInToday ? VenusTheme.accentGreen : VenusTheme.accentBlue
        )
    }

    private var checkInAvailabilityHighlight: HomeHeaderHighlight {
        HomeHeaderHighlight(
            title: remainingCheckInsLabel,
            systemImage: viewModel.checkInAllowance.isUnlimited ? "infinity.circle.fill" : "plus.circle.fill",
            tint: VenusTheme.accentBlue
        )
    }

    private var dayOverDayHighlight: HomeHeaderHighlight? {
        guard let trend = viewModel.dayOverDayTrend else { return nil }
        return HomeHeaderHighlight(
            title: trend.label,
            systemImage: trend.direction.iconName,
            tint: Color(hex: trend.direction.colorHex)
        )
    }

    private var supportsActionModeSwitch: Bool {
        guard let baseAction = viewModel.nextBestAction else { return false }
        return baseAction.asHighImpactVariant() != baseAction
    }

    private var visualInsights: [HomeVisualInsight] {
        var items: [HomeVisualInsight] = []

        if let trend = viewModel.weeklyTrend {
            items.append(makeTrendInsight(from: trend))
        }

        if let alert = viewModel.patternAlert {
            items.append(makePatternAlertInsight(from: alert))
        }

        if let confidence = viewModel.confidenceInsight {
            items.append(makeConfidenceInsight(from: confidence))
        }

        if let triggerRecovery = viewModel.triggerRecoveryInsight {
            items.append(makeTriggerRecoveryInsight(from: triggerRecovery))
        }

        if let forecast = viewModel.proMoodForecast, viewModel.checkInAllowance.plan == .pro {
            items.append(makeForecastInsight(from: forecast))
        } else {
            items.append(
                HomeVisualInsight(
                    kind: .forecastLocked,
                    label: "Próximos dias",
                    title: "Veja o caminho à frente",
                    detail: "No Pro você acompanha a tendência dos próximos dias de um jeito simples.",
                    systemImage: "sparkles.rectangle.stack.fill",
                    tint: VenusTheme.accentPurple,
                    badgeText: "PRO"
                )
            )
        }

        return Array(items.prefix(4))
    }

    private var primaryActionTitle: String {
        if viewModel.isLoadingInsights {
            return "Preparando sua leitura"
        }

        if displayedActionModel != nil {
            return hasStartedPracticeToday ? "Fazer de novo" : "Começar agora"
        }

        if viewModel.insightsErrorMessage != nil {
            return "Tentar de novo"
        }

        return "Atualizar"
    }
    private var displayedAlternativeActions: [NextBestAction] {
        viewModel.alternativeActions.filter { $0.actionKey != viewModel.nextBestAction?.actionKey }
    }

    private var displayedActionModel: NextBestAction? {
        guard let baseAction = viewModel.nextBestAction else { return nil }
        return preferHighImpactAction ? baseAction.asHighImpactVariant() : baseAction
    }

    private var actionBadges: [HomeActionBadge] {
        guard let action = displayedActionModel else { return [] }

        var badges: [HomeActionBadge] = []

        if let availableTime = viewModel.todayMoodAvailableTime {
            let label = action.estimatedMinutes <= availableTime.maxMinutes
                ? "cabe no seu tempo"
                : "pede um pouco mais de tempo"
            badges.append(
                HomeActionBadge(
                    title: label,
                    systemImage: "clock.fill",
                    tint: action.estimatedMinutes <= availableTime.maxMinutes ? VenusTheme.accentGreen : VenusTheme.accentBlue
                )
            )
        }

        if let area = viewModel.todayMoodAffectedArea {
            badges.append(
                HomeActionBadge(
                    title: "olha para \(areaLabel(area))",
                    systemImage: "scope",
                    tint: VenusTheme.accentOrange
                )
            )
        }

        if let energy = viewModel.todayMoodEnergyLevel {
            let badge: HomeActionBadge
            switch energy {
            case .low:
                badge = HomeActionBadge(title: "funciona com pouca energia", systemImage: "battery.25", tint: VenusTheme.accentPurple)
            case .medium:
                badge = HomeActionBadge(title: "ritmo equilibrado", systemImage: "battery.75", tint: VenusTheme.accentBlue)
            case .high:
                badge = HomeActionBadge(title: "canaliza sua energia", systemImage: "bolt.fill", tint: VenusTheme.accentGreen)
            }
            badges.append(badge)
        }

        return Array(badges.prefix(3))
    }

    private var homeHeadline: String {
        if !viewModel.hasCheckedInToday {
            return "Vamos começar ouvindo você."
        }

        if viewModel.isLoadingInsights {
            return "Estou organizando seu dia."
        }

        if !hasInsightReady {
            return "Seu resumo já pode ganhar forma."
        }

        if !hasStartedPracticeToday {
            return preferHighImpactAction
                ? "Hoje dá para ir mais fundo."
                : "Hoje pede algo mais simples."
        }

        return "Seu dia já ganhou direção."
    }

    private var homeSupportText: String {
        if !viewModel.hasCheckedInToday {
            return "Um check-in rápido deixa a Home mais certeira."
        }

        if viewModel.isLoadingInsights {
            return "Estou montando uma leitura visual do seu momento."
        }

        if !hasInsightReady {
            return "Com um toque eu atualizo sua leitura."
        }

        if !hasStartedPracticeToday {
            return "Escolha uma versão rápida ou completa da sugestão."
        }

        return "Seu dia já ganhou direção, mas ainda dá para variar."
    }

    private var ritualProgressLabel: String {
        let nextIndex = viewModel.checkInAllowance.usedToday + 1
        if viewModel.checkInAllowance.isUnlimited {
            return "Ritual \(nextIndex)/∞"
        }

        let limit = viewModel.checkInAllowance.dailyLimit ?? viewModel.freePlanDailyLimit
        return "Ritual \(min(nextIndex, limit))/\(limit)"
    }

    private var heroSelectedMood: MoodType? {
        viewModel.todayMoodType
    }

    private var floatingButtonDisabled: Bool {
        false
    }

    private var checkInStatusCopy: String {
        if viewModel.hasCheckedInToday {
            if viewModel.checkInAllowance.canCheckIn {
                return "Seu check-in já está guiando a Home."
            }
            return "Seu check-in de hoje já está salvo."
        }

        return "Use o botão flutuante para liberar sua leitura."
    }

    private var remainingCheckInsLabel: String {
        if viewModel.checkInAllowance.isUnlimited {
            return "check-ins livres"
        }

        let limit = viewModel.checkInAllowance.dailyLimit ?? viewModel.freePlanDailyLimit
        let remaining = max(limit - viewModel.checkInAllowance.usedToday, 0)

        if remaining == 1 {
            return "1 disponível hoje"
        }

        return "\(remaining) disponíveis hoje"
    }

    private var checkInFloatingButtonTitle: String {
        if !viewModel.hasCheckedInToday {
            return "Fazer check-in"
        }
        if viewModel.checkInAllowance.canCheckIn {
            return "Novo check-in"
        }
        return "Mais check-ins"
    }

    private var checkInFloatingButtonSubtitle: String {
        if !viewModel.hasCheckedInToday {
            return "abre o check-in completo"
        }
        if viewModel.checkInAllowance.canCheckIn {
            return "abra uma nova atualização"
        }
        return "veja como liberar atualizações"
    }

    private var checkInFloatingButtonIcon: String {
        if !viewModel.hasCheckedInToday {
            return "heart.text.square.fill"
        }
        if viewModel.checkInAllowance.canCheckIn {
            return "plus.circle.fill"
        }
        return "crown.fill"
    }

    private var checkInHintTitle: String {
        if !viewModel.hasCheckedInToday {
            return "Comece o check-in aqui"
        }
        if viewModel.checkInAllowance.canCheckIn {
            return "Quer registrar um novo check-in?"
        }
        return "Seu check-in de hoje já está salvo"
    }

    private var checkInHintBody: String {
        if !hasSeenFirstLaunchGuide {
            return "Comece por aqui. Ao tocar no humor ou no pop-up, eu abro o check-in completo em uma sheet."
        }
        if !hasSeenCheckInFloatingHint {
            return "Esse botão de vidro abre o check-in completo sem pesar a Home."
        }
        if !viewModel.hasCheckedInToday {
            return "Leva poucos segundos e prepara a Home e a dashboard para o resto do dia."
        }
        if viewModel.checkInAllowance.canCheckIn {
            return "Se o seu dia mudou, toque aqui para abrir uma nova atualização do check-in."
        }
        return "No plano atual, novas atualizações ficam limitadas depois do primeiro check-in."
    }

    private func areaLabel(_ area: MoodAffectedArea) -> String {
        switch area {
        case .work: return "trabalho"
        case .relationship: return "relacionamentos"
        case .health: return "saúde"
        case .discipline: return "disciplina"
        case .finances: return "finanças"
        case .studies: return "estudos"
        case .social: return "vida social"
        case .family: return "família"
        case .personal: return "você"
        }
    }

    private func markPracticeStartedToday(action: NextBestAction? = nil) {
        lastPracticeStartedDate = todayKey
        guard let action else { return }
        Task {
            await feedbackStore.trackStarted(action: action, at: Date())
        }
    }

    private func handlePrimaryAction() {
        if displayedActionModel != nil {
            markPracticeStartedToday(action: displayedActionModel)
            return
        }
        viewModel.retryInsights()
    }

    private func handleActionReasonTap() {
        guard let action = displayedActionModel else { return }
        actionReasonAction = action
    }

    private func handleInlineMoodSelection(_ mood: MoodType) {
        guard viewModel.checkInAllowance.canCheckIn else {
            viewModel.showUpgradePrompt = true
            return
        }

        inlineCheckInViewModel.startNewCheckIn(prefilledMood: mood)
        viewModel.showMoodCheckIn = true
        if !hasSeenFirstLaunchGuide {
            hasSeenFirstLaunchGuide = true
        }
    }

    private func handleCheckInAction() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showCheckInHint = false
        }
        if !hasSeenFirstLaunchGuide {
            hasSeenFirstLaunchGuide = true
        }

        guard viewModel.checkInAllowance.canCheckIn else {
            viewModel.showUpgradePrompt = true
            return
        }

        inlineCheckInViewModel.startNewCheckIn()
        viewModel.showMoodCheckIn = true
    }

    private func handleInsightTap(_ insight: HomeVisualInsight) {
        if insight.kind == .forecastLocked {
            showVenusProPlans = true
        }
    }

    private func presentCheckInHint() {
        checkInHintSequence += 1
        let sequence = checkInHintSequence

        withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
            showCheckInHint = true
        }

        hasSeenCheckInFloatingHint = true

        // Na primeira abertura, o hint fica fixo até o usuário tocar
        guard hasSeenFirstLaunchGuide else { return }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard sequence == checkInHintSequence else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.92)) {
                showCheckInHint = false
            }
        }
    }

    private func makeTrendInsight(from trend: WeeklyEmotionalTrend) -> HomeVisualInsight {
        let sparkline: [Double] = {
            if let prev = trend.previousWeekScore {
                return [prev, (prev + trend.currentWeekScore) / 2, trend.currentWeekScore]
            }
            return [trend.currentWeekScore * 0.85, trend.currentWeekScore * 0.92, trend.currentWeekScore]
        }()

        switch trend.direction {
        case .improving:
            return HomeVisualInsight(
                kind: .trend,
                label: "Seu ritmo",
                title: "Você está reagindo melhor",
                detail: "Os últimos dias mostram uma fase mais leve e com mais fôlego.",
                systemImage: "sun.max.fill",
                tint: VenusTheme.accentGreen,
                sparklineValues: sparkline
            )
        case .stable:
            return HomeVisualInsight(
                kind: .trend,
                label: "Seu ritmo",
                title: "Seu ritmo está estável",
                detail: "Seu humor parece mais previsível agora, sem grandes oscilações.",
                systemImage: "equal.circle.fill",
                tint: VenusTheme.accentBlue,
                sparklineValues: sparkline
            )
        case .declining:
            return HomeVisualInsight(
                kind: .trend,
                label: "Seu ritmo",
                title: "Seu momento pede mais cuidado",
                detail: "Os últimos dias parecem mais pesados. Vale seguir no modo gentil hoje.",
                systemImage: "cloud.rain.fill",
                tint: VenusTheme.accentOrange,
                sparklineValues: sparkline
            )
        }
    }

    private func makePatternAlertInsight(from alert: PatternAlert) -> HomeVisualInsight {
        HomeVisualInsight(
            kind: .alert,
            label: "Ponto de atenção",
            title: friendlyAlertTitle(from: alert.title),
            detail: shortenedText(alert.detail, fallback: "Tem um padrão te puxando para baixo hoje."),
            systemImage: "bell.badge.fill",
            tint: VenusTheme.accentPink
        )
    }

    private func makeForecastInsight(from forecast: ProMoodForecast) -> HomeVisualInsight {
        let futureScore = forecast.points.last?.projectedScoreWithAction ?? forecast.baselineScore
        let delta = futureScore - forecast.baselineScore

        if delta > 0.12 {
            return HomeVisualInsight(
                kind: .forecast,
                label: "Próximos dias",
                title: "A tendência pode clarear",
                detail: "Mantendo esse ritmo, você tende a sentir mais leveza nos próximos dias.",
                systemImage: "sunrise.fill",
                tint: VenusTheme.accentBlue
            )
        } else if delta < -0.08 {
            return HomeVisualInsight(
                kind: .forecast,
                label: "Próximos dias",
                title: "Vale manter cuidado extra",
                detail: "Seu momento ainda pode oscilar, então pequenos passos consistentes ajudam mais.",
                systemImage: "cloud.moon.rain.fill",
                tint: VenusTheme.accentPink
            )
        }

        return HomeVisualInsight(
            kind: .forecast,
                label: "Próximos dias",
                title: "Seu caminho tende a estabilizar",
                detail: "Sem grandes viradas, mas com chance de manter um ritmo mais equilibrado.",
                systemImage: "calendar.circle.fill",
                tint: VenusTheme.accentBlue
            )
    }

    private func makeTriggerRecoveryInsight(from insight: TriggerRecoveryInsight) -> HomeVisualInsight {
        HomeVisualInsight(
            kind: .triggerRecovery,
            label: "O que mais mexe com você",
            title: insight.highlightedTrigger,
            detail: "Se você cuidar disso primeiro, o resto do dia tende a pesar menos.",
            systemImage: "heart.text.square.fill",
            tint: VenusTheme.accentPink
        )
    }

    private func makeConfidenceInsight(from confidence: ConfidenceImprovementInsight) -> HomeVisualInsight {
        let current = max(0, min(confidence.currentConfidence, 1))
        let percent = Int((current * 100).rounded())
        let title: String

        switch percent {
        case ..<40:
            title = "Hoje vale ir com calma"
        case ..<70:
            title = "Você já tem base para agir"
        default:
            title = "Você está mais firme hoje"
        }

        return HomeVisualInsight(
            kind: .confidence,
            label: "Seu fôlego para agir",
            title: title,
            detail: confidence.confidenceGain14Days >= 0.15
                ? "Se repetir pequenos passos, agir tende a ficar cada vez mais natural."
                : "Constância agora importa mais do que intensidade.",
            systemImage: "bolt.heart.fill",
            tint: VenusTheme.accentGreen,
            badgeText: "\(percent)%",
            progress: current
        )
    }

    private func friendlyAlertTitle(from rawTitle: String) -> String {
        let raw = rawTitle.lowercased()

        if raw.contains("sono") {
            return "Seu sono pesa muito no dia"
        }
        if raw.contains("taref") || raw.contains("adi") || raw.contains("evit") {
            return "Pendências estão roubando energia"
        }
        if raw.contains("mensagem") || raw.contains("conversa") || raw.contains("social") {
            return "Relações pendentes mexem com você"
        }
        if raw.contains("ambiente") || raw.contains("bagun") || raw.contains("casa") {
            return "Seu ambiente influencia seu humor"
        }

        return "Tem um padrão pedindo cuidado"
    }

    private func shortenedText(_ text: String, fallback: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return fallback }
        return cleaned
    }
}

#Preview {
    HomeView(userName: "Kauã")
}
