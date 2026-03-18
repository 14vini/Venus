//
//  HomeView.swift
//  Venus
//
//
//

import SwiftUI

struct HomeView: View {
    let userName: String

    @State private var showVenusChat = false
    @State private var showChatHistory = false
    @State private var showVenusProPlans = false
    @State private var actionReasonSheetAction: NextBestAction?

    @AppStorage(LocalSubscriptionStatusProvider.planKey) private var isPremiumTestEnabled = false
    @AppStorage("home.lastPracticeStartedDate") private var lastPracticeStartedDate = ""
    @AppStorage("home.preferHighImpactAction") private var preferHighImpactAction = false

    private let feedbackStore = DependencyContainer.shared.makeBehaviorFeedbackStore()

    @StateObject private var viewModel = HomeViewModel(
        patternEngineUseCase: DependencyContainer.shared.makePatternEngineUseCase(),
        checkInAllowanceUseCase: DependencyContainer.shared.makeCheckInAllowanceUseCase(),
        moodRepository: DependencyContainer.shared.makeMoodRepository()
    )

    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()

            // Animated Background Orbs
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(VenusTheme.primary.opacity(0.1))
                        .blur(radius: 60)
                        .frame(width: 300, height: 300)
                        .offset(x: -100, y: 100)

                    Circle()
                        .fill(VenusTheme.accentOrange.opacity(0.08))
                        .blur(radius: 80)
                        .frame(width: 400, height: 400)
                        .offset(x: geo.size.width - 200, y: geo.size.height - 300)
                }
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    header
                    checkInCard
                    actionCard
                    insightsStack
                    premiumCTA
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Olá, \(userName)")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                CircleButton(systemName: "sparkles") {
                    showVenusChat = true
                }
            }
            ToolbarItemGroup(placement: .topBarLeading) {
                CircleButton(systemName: "clock") {
                    showChatHistory = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showMoodCheckIn) {
            MoodCheckInView(
                viewModel: DependencyContainer.shared.makeMoodCheckInViewModel(),
                ritualProgressLabel: ritualProgressLabel,
                onCompleted: viewModel.handleMoodCheckInCompleted
            )
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
        .sheet(item: $actionReasonSheetAction) { actionModel in
            HomeActionReasonSheet(
                actionModel: actionModel,
                weeklyInsights: viewModel.weeklyInsights,
                patternAlert: viewModel.patternAlert,
                actionWhy: viewModel.actionWhy,
                proForecast: viewModel.proMoodForecast,
                isPro: viewModel.checkInAllowance.plan == .pro,
                confidenceInsight: viewModel.confidenceInsight,
                triggerRecoveryInsight: viewModel.triggerRecoveryInsight
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.isCriticalRiskNow) { _, isCritical in
            if isCritical {
                preferHighImpactAction = true
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seu dia em 3 passos")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.textSecondary)

                    Text(nextStepSummary)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(VenusTheme.accentOrange)
                    Text("\(viewModel.checkInStreakDays)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(VenusTheme.accentOrange.opacity(0.1))
                .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                ForEach(homeJourneySteps) { step in
                    HomeJourneyStepCard(step: step)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Check-in Card (redesenhado)

    private var checkInCard: some View {
        Button(action: handleCheckInAction) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.65),
                                Color.white.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)

                // Content
                HStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Como você está se sentindo?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        if viewModel.hasCheckedInToday, let mood = viewModel.todayMoodType {
                            MoodBadge(mood: mood, intensity: viewModel.todayMoodIntensity)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text(checkInActionTitle)
                                    .font(.system(.footnote, design: .rounded).weight(.bold))
                            }
                            .foregroundColor(VenusTheme.textSecondary)
                        }

                        if isCheckInUpgradeCTA {
                            Button {
                                showVenusProPlans = true
                            } label: {
                                Text("Desbloquear Pro →")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.accentOrange)
                            }
                        }
                    }

                    Spacer()

                    // Premium Button
                    ZStack {
                        Circle()
                            .fill(VenusTheme.orangeTopGradient)
                            .frame(width: 58, height: 58)

                        Image(systemName: viewModel.hasCheckedInToday ? "arrow.clockwise" : "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(24)
            }
        }
        
        .overlay(alignment: .bottomLeading) {
            Label("\(viewModel.checkInsUsedToday) rituais hoje", systemImage: "clock.badge.checkmark")
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .padding(.leading, 24)
                .padding(.top, 24)
                .padding(.bottom, -24)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Action Card (redesenhado)

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("O que pode te ajudar agora")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                Spacer()

                if displayedActionModel != nil {
                    HStack(spacing: 8) {
                        Image(systemName: preferHighImpactAction ? "bolt.fill" : "leaf.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(preferHighImpactAction ? VenusTheme.accentOrange : VenusTheme.accentGreen)

                        Text(preferHighImpactAction ? "Profunda" : "Leve")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)

                        Toggle("", isOn: $preferHighImpactAction)
                            .toggleStyle(SwitchToggleStyle(tint: VenusTheme.accentOrange))
                            .scaleEffect(0.7)
                            .frame(width: 40)
                    }
                    .padding(.leading, 12)
                    .padding(.trailing)
                    .padding(.vertical, 2)
                    .background(VenusTheme.surface)
                    .clipShape(Capsule())
                }
            }

            VStack(spacing: 0) {
                actionCardContent
                    .padding(24)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .liquidGlass(cornerRadius: 28)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: displayedActionModel?.id)
    }

    @ViewBuilder
    private var actionCardContent: some View {
        if viewModel.isLoadingInsights {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(VenusTheme.accentOrange)
                    .scaleEffect(1.2)
                Text("Analisando seus padrões...")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(VenusTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)

        } else if let action = displayedActionModel {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: action.kind.iconName)
                                .font(.system(size: 14, weight: .bold))
                            Text(preferHighImpactAction ? "Para virar o dia" : "Para começar leve")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                        }
                        .foregroundColor(preferHighImpactAction ? VenusTheme.accentOrange : VenusTheme.accentGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background((preferHighImpactAction ? VenusTheme.accentOrange : VenusTheme.accentGreen).opacity(0.1))
                        .clipShape(Capsule())

                        Text(action.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .lineLimit(2)

                        Text(action.detail)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                            .lineLimit(3)
                    }

                    Spacer()
                }

                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(action.estimatedMinutes) min")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                    }
                    .foregroundColor(VenusTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(VenusTheme.surface)
                    .clipShape(Capsule())

                    Spacer()

                    Button(action: handlePrimaryAction) {
                        HStack(spacing: 8) {
                            Text(primaryActionTitle)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(VenusTheme.primaryGradient)
                        .clipShape(Capsule())
                        .shadow(color: VenusTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }

                if viewModel.actionWhy?.summary != nil {
                    Button {
                        actionReasonSheetAction = action
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text("Entender por quê")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                        }
                        .foregroundColor(VenusTheme.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        } else if let error = viewModel.insightsErrorMessage {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundColor(VenusTheme.accentOrange)
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: handlePrimaryAction) {
                    Text("Tentar novamente")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(VenusTheme.primaryGradient)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(VenusTheme.primary.opacity(0.3))
                
                Text("Faça um check-in para gerar sua análise.")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Insights Stack

    private var insightsStack: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seu momento agora")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                    Text("Resumo simples para bater o olho e entender como você está.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }

                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(VenusTheme.primary)
            }

            if visualInsights.isEmpty {
                VenusCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Seu resumo aparece aqui")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)
                        Text("Faça um check-in e eu transformo seus sinais em um painel mais fácil de entender.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(visualInsights) { insight in
                        HomeVisualInsightCard(insight: insight)
                            .onTapGesture {
                                if insight.kind == .forecastLocked {
                                    showVenusProPlans = true
                                }
                            }
                    }
                }
            }

            if !viewModel.exploreActionSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Se quiser variar")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.exploreActionSuggestions.prefix(5)) { suggestion in
                                ChipView(
                                    title: suggestion.activityTitle,
                                    subtitle: "\(suggestion.durationMinutes) min · \(suggestion.activityCategory)",
                                    icon: suggestion.iconName
                                )
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.weeklyTrend?.direction)
    }

    private var premiumCTA: some View {
        Button {
            isPremiumTestEnabled.toggle()
            viewModel.refreshAfterPlanToggle()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("VENUS PRO")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundColor(VenusTheme.accentOrange)

                    Text(isPremiumTestEnabled ? "Premium Ativo" : "Desbloqueie o Pro")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)

                    Text(isPremiumTestEnabled ? "Teste ilimitado ativado." : "Previsões de humor e gatilhos.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: isPremiumTestEnabled ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(
                ZStack {
                    VenusTheme.primaryGradient
                    
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: VenusTheme.primary.opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.move(edge: .bottom).combined(with: .opacity))
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

    private var dailyLoopCompletedSteps: Int {
        var steps = 0
        if viewModel.hasCheckedInToday { steps += 1 }
        if hasInsightReady { steps += 1 }
        if hasStartedPracticeToday { steps += 1 }
        return steps
    }

    private var homeJourneySteps: [HomeJourneyStep] {
        [
            HomeJourneyStep(
                title: "Sentir",
                subtitle: viewModel.hasCheckedInToday ? "feito" : "agora",
                systemImage: viewModel.hasCheckedInToday ? "heart.fill" : "heart",
                tint: VenusTheme.accentPink,
                isDone: viewModel.hasCheckedInToday
            ),
            HomeJourneyStep(
                title: "Entender",
                subtitle: hasInsightReady ? "pronto" : (viewModel.hasCheckedInToday ? "montando" : "depois"),
                systemImage: hasInsightReady ? "sparkles" : "wand.and.stars",
                tint: VenusTheme.primary,
                isDone: hasInsightReady
            ),
            HomeJourneyStep(
                title: "Agir",
                subtitle: hasStartedPracticeToday ? "feito" : (displayedActionModel != nil ? "próximo" : "em breve"),
                systemImage: hasStartedPracticeToday ? "checkmark.circle.fill" : "play.fill",
                tint: VenusTheme.accentOrange,
                isDone: hasStartedPracticeToday
            )
        ]
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
                    tint: VenusTheme.primary,
                    badgeText: "PRO"
                )
            )
        }

        return Array(items.prefix(4))
    }

    private var primaryActionTitle: String {
        if viewModel.isLoadingInsights {
            return "Montando..."
        }

        if displayedActionModel != nil {
            return hasStartedPracticeToday ? "Fazer de novo" : "Começar agora"
        }

        if viewModel.insightsErrorMessage != nil {
            return "Tentar de novo"
        }

        return "Atualizar"
    }

    private var checkInActionTitle: String {
        if !viewModel.hasCheckedInToday {
            return "Abrir check-in"
        }
        if viewModel.checkInAllowance.canCheckIn {
            return "Atualizar check-in"
        }
        return "Ver Venus Pro"
    }

    private var isCheckInUpgradeCTA: Bool {
        viewModel.hasCheckedInToday && !viewModel.checkInAllowance.canCheckIn
    }

    private var displayedActionModel: NextBestAction? {
        guard let baseAction = viewModel.nextBestAction else { return nil }
        return preferHighImpactAction ? baseAction.asHighImpactVariant() : baseAction
    }

    private var nextStepSummary: String {
        if !viewModel.hasCheckedInToday {
            return "Comece contando como você está. Depois eu organizo o resto."
        }

        if viewModel.isLoadingInsights {
            return "Estou montando um plano simples para o seu momento."
        }

        if !hasInsightReady {
            return "Seu resumo pode ser atualizado com um toque."
        }

        if !hasStartedPracticeToday {
            return preferHighImpactAction
                ? "Sua sugestão mais forte está pronta."
                : "Sua sugestão leve está pronta."
        }

        return "Seu essencial de hoje já está encaminhado."
    }

    private var ritualProgressLabel: String {
        let nextIndex = viewModel.checkInAllowance.usedToday + 1
        if viewModel.checkInAllowance.isUnlimited {
            return "Ritual \(nextIndex)/∞"
        }

        let limit = viewModel.checkInAllowance.dailyLimit ?? viewModel.freePlanDailyLimit
        return "Ritual \(min(nextIndex, limit))/\(limit)"
    }

    private func markPracticeStartedToday(actionKind: NextBestActionKind? = nil) {
        lastPracticeStartedDate = todayKey
        guard let actionKind else { return }
        Task {
            await feedbackStore.trackStarted(kind: actionKind, at: Date())
        }
    }

    private func handlePrimaryAction() {
        if displayedActionModel != nil {
            markPracticeStartedToday(actionKind: displayedActionModel?.kind)
            return
        }
        viewModel.retryInsights()
    }

    private func handleCheckInAction() {
        viewModel.checkInButtonTapped()
    }

    private func makeTrendInsight(from trend: WeeklyEmotionalTrend) -> HomeVisualInsight {
        switch trend.direction {
        case .improving:
            return HomeVisualInsight(
                kind: .trend,
                label: "Seu ritmo",
                title: "Você está reagindo melhor",
                detail: "Os últimos dias mostram uma fase mais leve e com mais fôlego.",
                systemImage: "sun.max.fill",
                tint: VenusTheme.accentGreen
            )
        case .stable:
            return HomeVisualInsight(
                kind: .trend,
                label: "Seu ritmo",
                title: "Seu ritmo está estável",
                detail: "Seu humor parece mais previsível agora, sem grandes oscilações.",
                systemImage: "equal.circle.fill",
                tint: VenusTheme.primary
            )
        case .declining:
            return HomeVisualInsight(
                kind: .trend,
                label: "Seu ritmo",
                title: "Seu momento pede mais cuidado",
                detail: "Os últimos dias parecem mais pesados. Vale seguir no modo gentil hoje.",
                systemImage: "cloud.rain.fill",
                tint: VenusTheme.accentOrange
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
            tint: VenusTheme.accentOrange
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
                tint: VenusTheme.primary
            )
        } else if delta < -0.08 {
            return HomeVisualInsight(
                kind: .forecast,
                label: "Próximos dias",
                title: "Vale manter cuidado extra",
                detail: "Seu momento ainda pode oscilar, então pequenos passos consistentes ajudam mais.",
                systemImage: "cloud.moon.rain.fill",
                tint: VenusTheme.accentOrange
            )
        }

        return HomeVisualInsight(
            kind: .forecast,
            label: "Próximos dias",
            title: "Seu caminho tende a estabilizar",
            detail: "Sem grandes viradas, mas com chance de manter um ritmo mais equilibrado.",
            systemImage: "calendar.circle.fill",
            tint: VenusTheme.primary
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

        if let periodIndex = cleaned.firstIndex(of: "."), cleaned.distance(from: cleaned.startIndex, to: periodIndex) < 110 {
            return String(cleaned[...periodIndex])
        }

        if cleaned.count <= 110 {
            return cleaned
        }

        return String(cleaned.prefix(107)) + "..."
    }
}

// MARK: - Small helper views

private struct CircleButton: View {
    var systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(VenusTheme.text)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
    }
}

private struct MoodBadge: View {
    let mood: MoodType
    let intensity: Int?

    var body: some View {
        HStack(spacing: 8) {
            Text(mood.emoji)
                .font(.system(size: 16))
            
            Text(mood.rawValue)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
            
            if let intensity {
                Text("\(intensity)/10")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(VenusTheme.surface)
        .clipShape(Capsule())
    }
}

private struct HomeJourneyStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isDone: Bool
}

private struct HomeJourneyStepCard: View {
    let step: HomeJourneyStep

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(step.tint.opacity(step.isDone ? 0.18 : 0.1))
                        .frame(width: 34, height: 34)

                    Image(systemName: step.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(step.tint)
                }

                Spacer(minLength: 0)

                if step.isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(step.tint)
                }
            }

            Text(step.title)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)

            Text(step.subtitle)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(step.isDone ? step.tint : VenusTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(step.isDone ? step.tint.opacity(0.1) : VenusTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(step.isDone ? step.tint.opacity(0.2) : VenusTheme.cardBorder, lineWidth: 1)
        )
    }
}

private enum HomeVisualInsightKind: String {
    case trend
    case alert
    case forecast
    case forecastLocked
    case triggerRecovery
    case confidence
}

private struct HomeVisualInsight: Identifiable {
    let kind: HomeVisualInsightKind
    let label: String
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    var badgeText: String? = nil
    var progress: Double? = nil

    var id: String { kind.rawValue }
}

private struct HomeVisualInsightCard: View {
    let insight: HomeVisualInsight

    var body: some View {
        VenusCard(cornerRadius: 24, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(insight.tint.opacity(0.14))
                            .frame(width: 42, height: 42)

                        Image(systemName: insight.systemImage)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(insight.tint)
                    }

                    Spacer()

                    if let badgeText = insight.badgeText {
                        Text(badgeText)
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundColor(insight.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(insight.tint.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Text(insight.label)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)

                Text(insight.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                if let progress = insight.progress {
                    HomeMiniProgressBar(value: progress, tint: insight.tint)
                }

                Text(insight.detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
    }
}

private struct HomeMiniProgressBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let clampedValue = max(0, min(value, 1))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(VenusTheme.cardBorder.opacity(0.4))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.55), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(18, geometry.size.width * clampedValue))
            }
        }
        .frame(height: 8)
    }
}

private struct InsightRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VenusCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(VenusTheme.text)
                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }
}

private struct ChipView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(VenusTheme.primary.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(VenusTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                Text(subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .background(VenusTheme.surface)
        .clipShape(Capsule())
    }
}

#Preview {
    HomeView(userName: "Kauã")
}
