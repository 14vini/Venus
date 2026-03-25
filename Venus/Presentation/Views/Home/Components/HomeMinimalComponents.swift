//
//  HomeMinimalComponents.swift
//  Venus
//

import SwiftUI
import Charts

struct HomeActionReasonView: View {
    @Environment(\.colorScheme) private var colorScheme

    let actionModel: NextBestAction
    let weeklyInsights: WeeklyStrategicInsights?
    let patternAlert: PatternAlert?
    let actionWhy: ActionWhyInsight?
    let proForecast: ProMoodForecast?
    let isPro: Bool
    let confidenceInsight: ConfidenceImprovementInsight?
    let triggerRecoveryInsight: TriggerRecoveryInsight?
    let alternativeActions: [NextBestAction]
    let exploreSuggestions: [ExploreActionSuggestion]

    @State private var pulseHero = false
    @State private var revealContent = false

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: actionAccent,
                secondaryAccent: VenusTheme.moodSage,
                tertiaryAccent: VenusTheme.ambientCool
            )

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    introSection
                        .venusScrollMotion(.gentle)
                    heroCard
                        .venusScrollMotion(.strong)
                    causalChainSection
                    diagnosisSection
                    decisionSimulatorSection
                    impactSection
                    contextSection
                    forecastSection
                    protocolLibrarySection
                    confidenceScoreSection

                    if let expandedActionOption {
                        expandedActionSection(option: expandedActionOption)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
                .padding(.top, 22)
                .padding(.bottom, 34)
                .opacity(revealContent ? 1 : 0)
                .offset(y: revealContent ? 0 : 18)
            }
        }
        .background(VenusTheme.background)
        .navigationTitle("Por que esta ação?")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear(perform: startAnimations)
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                if isPro {
                    VenusProBadge(title: "Leitura aprofundada")
                } else {
                    Label("Leitura essencial", systemImage: "sparkles")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [actionAccent, actionAccent.opacity(0.72)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }

                Spacer()

                if let confidence = explanationConfidence {
                    Text("\(Int((confidence * 100).rounded()))% confiança")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(cardFill.opacity(0.92)))
                }
            }

            Text(actionWhy?.summary ?? actionModel.strategicReason)
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(introHighlights) { highlight in
                    HomeReasonQuickLookCard(highlight: highlight)
                }
            }
        }
        .padding(18)
        .actionReasonCardStyle()
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [actionAccent, actionAccent.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: actionAccent.opacity(0.28), radius: pulseHero ? 26 : 12, x: 0, y: 10)
                        .scaleEffect(pulseHero ? 1.05 : 0.94)

                    Image(systemName: actionModel.kind.iconName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(pulseHero ? 1.06 : 0.94)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(actionModel.isHighImpactVariant ? "Ação alta" : "Microação")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(actionAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(actionAccent.opacity(0.12)))

                        if let window = weeklyInsights?.criticalWindow {
                            Text(window)
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Text(actionModel.title)
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(actionModel.detail)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                HomeSpotlightMetric(
                    title: "Formato",
                    value: actionModel.isHighImpactVariant ? "Profundo" : "Leve",
                    icon: actionModel.isHighImpactVariant ? "bolt.fill" : "leaf.fill",
                    tint: actionAccent
                )

                HomeSpotlightMetric(
                    title: "Duração",
                    value: "\(actionModel.estimatedMinutes) min",
                    icon: "timer",
                    tint: VenusTheme.accentBlue
                )

                if let delta = keyImpactDeltaText {
                    HomeSpotlightMetric(
                        title: "Impacto",
                        value: delta,
                        icon: "chart.line.uptrend.xyaxis",
                        tint: VenusTheme.accentGreen
                    )
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: 18, x: 0, y: 12)
    }

    private var causalChainSection: some View {
        HomeReasonSection(
            title: "Leitura causal",
            subtitle: "A cadeia de decisão que explica por que essa ação venceu agora.",
            icon: "point.3.connected.trianglepath.dotted",
            tint: actionAccent
        ) {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(causalHighlights) { item in
                    HomeReasonQuickLookCard(highlight: item)
                }
            }
        }
    }

    private var diagnosisSection: some View {
        HomeReasonSection(
            title: "Diagnóstico em camadas",
            subtitle: "Os sinais que empurraram essa ação para o topo agora.",
            icon: "waveform.path.ecg",
            tint: VenusTheme.moodMintStrong
        ) {
            VStack(spacing: 14) {
                ForEach(Array(evidenceItems.prefix(4).enumerated()), id: \.offset) { index, item in
                    HomeEvidenceCard(
                        index: index + 1,
                        title: item.title,
                        detail: item.detail,
                        tint: actionAccent
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var decisionSimulatorSection: some View {
        HomeReasonSection(
            title: "Simulador de alternativas",
            subtitle: "Compare a ação escolhida com outras rotas viáveis para este mesmo momento.",
            icon: "rectangle.split.3x1.fill",
            tint: VenusTheme.accentBlue
        ) {
            if isPro {
                VStack(spacing: 12) {
                    HomeActionDecisionCard(
                        title: actionModel.title,
                        detail: actionModel.detail,
                        badge: "Escolhida agora",
                        duration: "\(actionModel.estimatedMinutes) min",
                        tint: actionAccent
                    )

                    ForEach(Array(alternativeActions.prefix(3).enumerated()), id: \.element.id) { index, action in
                        HomeActionDecisionCard(
                            title: action.title,
                            detail: action.strategicReason,
                            badge: "Alternativa \(index + 1)",
                            duration: "\(action.estimatedMinutes) min",
                            tint: VenusTheme.accentBlue
                        )
                    }

                    if !exploreSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Rotas extras do Pro")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(exploreSuggestions.prefix(4)) { suggestion in
                                        HomeExploreSuggestionPill(suggestion: suggestion)
                                    }
                                }
                                .padding(.horizontal, 2)
                                .padding(.vertical, 2)
                            }
                            .scrollClipDisabled()
                        }
                    }
                }
            } else {
                HomeLockedInsightCard(
                    title: "O simulador de alternativas fica no Pro",
                    detail: "No modo Pro você compara a ação escolhida com outras rotas, duração e motivo estratégico antes de começar."
                )
            }
        }
    }

    @ViewBuilder
    private var impactSection: some View {
        HomeReasonSection(
            title: "Como isso mexe no seu estado mental",
            subtitle: "A diferença esperada quando você age no timing certo.",
            icon: "sparkles.rectangle.stack.fill",
            tint: VenusTheme.accentBlue
        ) {
            VStack(spacing: 16) {
                if let triggerRecoveryInsight {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Gatilho destacado")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.textSecondary)
                                Text(triggerRecoveryInsight.highlightedTrigger)
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.text)
                            }

                            Spacer()

                            if let delta = day7TriggerDelta {
                                HomePillBadge(
                                    text: signedPoints(delta),
                                    icon: "arrow.up.forward",
                                    tint: VenusTheme.accentGreen
                                )
                            }
                        }

                        Text(triggerRecoveryInsight.highlightedSummary)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HomeScenarioChart(
                            points: triggerSeriesPoints(from: triggerRecoveryInsight),
                            accent: actionAccent,
                            comparison: Color.secondary.opacity(colorScheme == .dark ? 0.45 : 0.35),
                            valueLabel: "Índice"
                        )
                    }
                    .padding(18)
                    .actionReasonCardStyle()

                    if !triggerRecoveryInsight.additionalAreaProjections.isEmpty {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            ForEach(triggerRecoveryInsight.additionalAreaProjections.prefix(4)) { projection in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(projection.area)
                                        .font(.system(.headline, design: .rounded).weight(.bold))
                                        .foregroundColor(VenusTheme.text)

                                    HStack(spacing: 8) {
                                        HomeMiniMetric(title: "D+3", value: signedPoints(projection.day3Delta))
                                        HomeMiniMetric(title: "D+7", value: signedPoints(projection.day7Delta))
                                    }

                                    Text("\(Int((projection.confidence * 100).rounded()))% confiança")
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                        .foregroundColor(VenusTheme.textSecondary)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .actionReasonCardStyle(cornerRadius: 24)
                            }
                        }
                    } else if !isPro, triggerRecoveryInsight.lockedAdditionalAreasCount > 0 {
                        HomeLockedInsightCard(
                            title: "Mais áreas destravadas no Pro",
                            detail: "\(triggerRecoveryInsight.lockedAdditionalAreasCount) leituras extras de gatilho ficam disponíveis com a projeção completa."
                        )
                    }
                } else {
                    HomeLockedInsightCard(
                        title: "Ainda coletando impacto",
                        detail: "Continue registrando check-ins para liberar a comparação entre cenário com ação e sem ação."
                    )
                }

                if let confidenceInsight {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Autoeficácia esperada")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)

                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            HomeMiniMetricCard(
                                title: "Hoje",
                                value: percent(confidenceInsight.currentConfidence),
                                tint: actionAccent
                            )

                            HomeMiniMetricCard(
                                title: "7 dias",
                                value: percent(confidenceInsight.projectedConfidence7Days),
                                tint: VenusTheme.accentBlue
                            )

                            HomeMiniMetricCard(
                                title: "14 dias",
                                value: percent(confidenceInsight.projectedConfidence14Days),
                                tint: VenusTheme.accentGreen
                            )

                            HomeMiniMetricCard(
                                title: "Ganho",
                                value: signedPercent(confidenceInsight.confidenceGain14Days),
                                tint: VenusTheme.primary
                            )
                        }

                        Text(confidenceInsight.personalizedSummary)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !confidenceInsight.keyLevers.isEmpty {
                            HomeFlowLayout(items: confidenceInsight.keyLevers.prefix(5).map { $0 }) { lever in
                                HomePillBadge(text: lever, icon: "star.fill", tint: VenusTheme.accentBlue)
                            }
                        }
                    }
                    .padding(18)
                    .actionReasonCardStyle()
                }
            }
        }
    }

    private var contextSection: some View {
        HomeReasonSection(
            title: "Contexto da semana",
            subtitle: "O pano de fundo da semana por trás dessa sugestão.",
            icon: "calendar.badge.exclamationmark",
            tint: VenusTheme.accentBlue
        ) {
            VStack(spacing: 16) {
                if weeklyInsights != nil || patternAlert != nil {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        if let trigger = weeklyInsights?.dominantTrigger {
                            HomeContextCard(title: "Gatilho dominante", value: trigger, tint: VenusTheme.moodMintStrong)
                        }

                        if let window = weeklyInsights?.criticalWindow {
                            HomeContextCard(title: "Janela crítica", value: window, tint: VenusTheme.accentBlue)
                        }

                        if let weeklyInsights {
                            HomeContextCard(
                                title: "Alavanca",
                                value: percent(weeklyInsights.leverageScore),
                                tint: VenusTheme.accentGreen
                            )

                            HomeContextCard(
                                title: "Qualidade do streak",
                                value: percent(weeklyInsights.streakQualityScore),
                                tint: VenusTheme.primary
                            )
                        }
                    }

                    if let weeklyInsights {
                        VStack(alignment: .leading, spacing: 12) {
                            HomeNarrativeCard(
                                eyebrow: "Foco comportamental",
                                title: weeklyInsights.behavioralFocus,
                                detail: weeklyInsights.worstRecurringPattern,
                                tint: VenusTheme.primary
                            )

                            if let bestDay = weeklyInsights.bestDay {
                                HomeNarrativeCard(
                                    eyebrow: "Melhor dia da semana",
                                    title: bestDay,
                                    detail: weeklyInsights.sleepCounterfactual ?? "Seu padrão mostra espaço para reforçar o que já está funcionando.",
                                    tint: VenusTheme.accentGreen
                                )
                            }
                        }
                    }

                    if let patternAlert {
                        HomeNarrativeCard(
                            eyebrow: "Alerta ativo",
                            title: patternAlert.title,
                            detail: patternAlert.detail,
                            tint: VenusTheme.primary
                        )
                    }
                } else {
                    HomeLockedInsightCard(
                        title: "Semana ainda em leitura",
                        detail: "Conforme você registra mais dias, essa área passa a mostrar gatilhos, janelas críticas e protocolos de recuperação."
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var forecastSection: some View {
        HomeReasonSection(
            title: "Cenário com ação vs sem ação",
            subtitle: "A diferença projetada entre agir agora e deixar esse momento passar.",
            icon: "chart.line.text.clipboard",
            tint: VenusTheme.accentGreen
        ) {
            if isPro, let proForecast {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Leitura de 7 dias")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.text)

                                Text("Baseline \(scoreText(proForecast.baselineScore))")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundColor(VenusTheme.textSecondary)
                            }

                            Spacer()

                            HomePillBadge(
                                text: forecastDeltaText(from: proForecast),
                                icon: "sparkles",
                                tint: VenusTheme.accentGreen
                            )
                        }

                        HomeScenarioChart(
                            points: forecastSeries(from: proForecast),
                            accent: VenusTheme.accentGreen,
                            comparison: Color.secondary.opacity(colorScheme == .dark ? 0.45 : 0.35),
                            valueLabel: "Score"
                        )

                        Text(proForecast.rationale)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let riskAlert = proForecast.riskAlert {
                            HomePillBadge(text: riskAlert, icon: "exclamationmark.triangle.fill", tint: VenusTheme.validationError)
                        }
                    }
                    .padding(18)
                    .actionReasonCardStyle()
                }
            } else {
                HomeLockedInsightCard(
                    title: "A curva completa fica no Venus Pro",
                    detail: (triggerRecoveryInsight?.lockedAdditionalAreasCount ?? 0) > 0
                    ? "Além da linha principal, você também destrava projeções extras de gatilho e cenários comparativos."
                    : "No modo Pro você vê a diferença entre cenário com ação e sem ação em uma linha temporal completa."
                )
            }
        }
    }

    @ViewBuilder
    private var protocolLibrarySection: some View {
        HomeReasonSection(
            title: "Biblioteca de protocolos",
            subtitle: "Estratégias que esse momento costuma aceitar melhor quando você precisa variar.",
            icon: "books.vertical.fill",
            tint: VenusTheme.primary
        ) {
            if isPro {
                VStack(spacing: 12) {
                    if let recoveryProtocol = weeklyInsights?.recoveryProtocol {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(recoveryProtocol.title)
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.text)

                            ForEach(Array(recoveryProtocol.steps.enumerated()), id: \.offset) { index, step in
                                HomeStepRow(index: index + 1, text: step, tint: actionAccent)
                            }
                        }
                        .padding(18)
                        .actionReasonCardStyle(cornerRadius: 26)
                    }

                    if !exploreSuggestions.isEmpty {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            ForEach(exploreSuggestions.prefix(4)) { suggestion in
                                HomeProtocolLibraryCard(suggestion: suggestion)
                            }
                        }
                    } else if weeklyInsights?.recoveryProtocol == nil {
                        HomeLockedInsightCard(
                            title: "Ainda coletando protocolos",
                            detail: "Conforme seu histórico cresce, o app passa a montar uma pequena biblioteca do que costuma funcionar melhor para você."
                        )
                    }
                }
            } else {
                HomeLockedInsightCard(
                    title: "Biblioteca adaptativa no Pro",
                    detail: "No modo Pro você ganha protocolos prontos e sugestões adicionais organizadas por contexto, energia e duração."
                )
            }
        }
    }

    @ViewBuilder
    private var confidenceScoreSection: some View {
        HomeReasonSection(
            title: "Confiança da leitura",
            subtitle: "Quão forte está o sinal que sustenta essa recomendação hoje.",
            icon: "target",
            tint: VenusTheme.accentBlue
        ) {
            if let confidence = explanationConfidence {
                VStack(spacing: 12) {
                    HomeConfidenceScoreCard(
                        confidence: confidence,
                        summary: confidenceSummary
                    )

                    if let confidenceInsight {
                        Text(confidenceInsight.personalizedSummary)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(18)
                            .actionReasonCardStyle(cornerRadius: 24)
                    }
                }
            } else {
                HomeLockedInsightCard(
                    title: "Confiança ainda em formação",
                    detail: "Com mais check-ins e resposta às ações, esse bloco passa a mostrar o quanto podemos confiar nessa recomendação."
                )
            }
        }
    }

    private func expandedActionSection(option: HomeExpandedActionOption) -> some View {
        HomeReasonSection(
            title: "Plano ampliado",
            subtitle: "Se hoje couber mais energia, essa é a versão ampliada da estratégia.",
            icon: "arrow.up.right.circle.fill",
            tint: VenusTheme.primary
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(option.title)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)
                        Text(option.detail)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    Text("\(option.estimatedMinutes) min")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(VenusTheme.primaryGradient))
                }
            }
            .padding(18)
            .actionReasonCardStyle()
        }
    }

    private var evidenceItems: [ActionWhyEvidence] {
        var items: [ActionWhyEvidence] = [
            ActionWhyEvidence(
                title: "Evidência principal",
                detail: actionModel.strategicReason
            )
        ]
        if let actionWhy {
            items.append(contentsOf: actionWhy.evidence)
        }

        var seen = Set<String>()
        return items.filter { item in
            let key = "\(item.title.lowercased())|\(item.detail.lowercased())"
            guard !item.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private var actionAccent: Color {
        actionModel.isHighImpactVariant ? VenusTheme.primary : VenusTheme.accentGreen
    }

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                actionAccent.opacity(colorScheme == .dark ? 0.10 : 0.08),
                colorScheme == .dark ? VenusTheme.cardSurface : Color.white,
                colorScheme == .dark ? VenusTheme.cardSurfaceStrong : VenusTheme.cardSurfaceStrong
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardFill: Color {
        colorScheme == .dark ? VenusTheme.cardSurface : Color.white
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private var explanationConfidence: Double? {
        actionWhy?.confidence ?? weeklyInsights?.confidence ?? proForecast?.confidence
    }

    private var introHighlights: [HomeReasonQuickHighlight] {
        var items: [HomeReasonQuickHighlight] = [
            HomeReasonQuickHighlight(
                title: "Formato",
                value: actionModel.isHighImpactVariant ? "Profundo" : "Leve",
                icon: actionModel.isHighImpactVariant ? "bolt.fill" : "leaf.fill",
                tint: actionAccent
            ),
            HomeReasonQuickHighlight(
                title: "Duração",
                value: "\(actionModel.estimatedMinutes) min",
                icon: "timer",
                tint: VenusTheme.accentBlue
            )
        ]

        if let confidence = explanationConfidence {
            items.append(
                HomeReasonQuickHighlight(
                    title: "Confiança",
                    value: "\(Int((confidence * 100).rounded()))%",
                    icon: "target",
                    tint: VenusTheme.accentGreen
                )
            )
        }

        if let delta = keyImpactDeltaText {
            items.append(
                HomeReasonQuickHighlight(
                    title: "Impacto",
                    value: delta,
                    icon: "chart.line.uptrend.xyaxis",
                    tint: VenusTheme.primary
                )
            )
        } else if let window = weeklyInsights?.criticalWindow {
            items.append(
                HomeReasonQuickHighlight(
                    title: "Janela",
                    value: window,
                    icon: "calendar.badge.clock",
                    tint: VenusTheme.accentBlue
                )
            )
        }

        return Array(items.prefix(4))
    }

    private var causalHighlights: [HomeReasonQuickHighlight] {
        [
            HomeReasonQuickHighlight(
                title: "Sinal",
                value: signalSummary,
                icon: "dot.scope",
                tint: VenusTheme.accentBlue
            ),
            HomeReasonQuickHighlight(
                title: "Padrão",
                value: patternSummary,
                icon: "waveform.path.ecg",
                tint: VenusTheme.primary
            ),
            HomeReasonQuickHighlight(
                title: "Por que agora",
                value: whyNowSummary,
                icon: "clock.badge.checkmark",
                tint: actionAccent
            ),
            HomeReasonQuickHighlight(
                title: "Impacto esperado",
                value: expectedImpactSummary,
                icon: "chart.line.uptrend.xyaxis",
                tint: VenusTheme.accentGreen
            )
        ]
    }

    private var signalSummary: String {
        if let triggerRecoveryInsight {
            return triggerRecoveryInsight.highlightedTrigger
        }
        if let patternAlert {
            return patternAlert.title
        }
        if let trigger = weeklyInsights?.dominantTrigger {
            return trigger
        }
        return "Sinal em formação"
    }

    private var patternSummary: String {
        if let weeklyInsights {
            return weeklyInsights.worstRecurringPattern
        }
        if let patternAlert {
            return patternAlert.detail
        }
        return "Ainda estamos consolidando padrão suficiente."
    }

    private var whyNowSummary: String {
        if let window = weeklyInsights?.criticalWindow {
            return window
        }
        if let actionWhy {
            return actionWhy.summary
        }
        return actionModel.strategicReason
    }

    private var expectedImpactSummary: String {
        if let delta = keyImpactDeltaText {
            return delta
        }
        if let proForecast {
            return forecastDeltaText(from: proForecast)
        }
        return "Mais clareza e menos atrito no próximo passo."
    }

    private var confidenceSummary: String {
        guard let confidence = explanationConfidence else {
            return "Ainda não temos confiança suficiente para exibir esse bloco."
        }

        let percent = Int((confidence * 100).rounded())
        switch percent {
        case ..<55:
            return "Leitura ainda jovem. Boa para orientar, mas vale observar mais alguns dias."
        case ..<75:
            return "Leitura consistente. Já temos sinal suficiente para priorizar essa direção."
        default:
            return "Leitura forte. O padrão atual está bem sustentado pelos seus sinais recentes."
        }
    }

    private var day7TriggerDelta: Double? {
        guard let triggerRecoveryInsight else { return nil }
        return triggerRecoveryInsight.highlightedProjection.first(where: { $0.dayOffset == 7 })?.delta
            ?? triggerRecoveryInsight.highlightedProjection.last?.delta
    }

    private var keyImpactDeltaText: String? {
        if let delta = day7TriggerDelta {
            return signedPoints(delta)
        }
        if let proForecast {
            return forecastDeltaText(from: proForecast)
        }
        if let confidenceInsight {
            return signedPercent(confidenceInsight.confidenceGain14Days)
        }
        return nil
    }

    private func startAnimations() {
        guard !revealContent else { return }

        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            pulseHero = true
        }

        withAnimation(.spring(response: 0.72, dampingFraction: 0.84)) {
            revealContent = true
        }
    }

    private var expandedActionOption: HomeExpandedActionOption? {
        guard !actionModel.isHighImpactVariant else { return nil }
        let expanded = actionModel.asHighImpactVariant()
        return HomeExpandedActionOption(
            title: expanded.title,
            detail: expanded.detail,
            estimatedMinutes: expanded.estimatedMinutes
        )
    }

    private func triggerSeriesPoints(from insight: TriggerRecoveryInsight) -> [ReasonChartPoint] {
        insight.highlightedProjection.flatMap { point in
            [
                ReasonChartPoint(dayOffset: point.dayOffset, scenario: "Sem ação", score: point.scoreWithoutAction),
                ReasonChartPoint(dayOffset: point.dayOffset, scenario: "Com ação", score: point.scoreWithAction)
            ]
        }
    }

    private func forecastSeries(from forecast: ProMoodForecast) -> [ReasonChartPoint] {
        forecast.points.flatMap { point in
            [
                ReasonChartPoint(dayOffset: point.dayOffset, scenario: "Sem ação", score: point.projectedScore),
                ReasonChartPoint(dayOffset: point.dayOffset, scenario: "Com ação", score: point.projectedScoreWithAction)
            ]
        }
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func signedPercent(_ value: Double) -> String {
        String(format: "%+.0f%%", value * 100)
    }

    private func signedPoints(_ value: Double) -> String {
        String(format: "%+.1f pts", value)
    }

    private func scoreText(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func forecastDeltaText(from forecast: ProMoodForecast) -> String {
        let delta = forecast.points.first(where: { $0.dayOffset == 7 })?.actionDelta ?? forecast.points.last?.actionDelta ?? 0
        return signedPoints(delta)
    }
}

private struct HomeReasonSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let content: Content

    init(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.text)
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .venusScrollMotion(.strong)
    }
}

private struct HomeReasonQuickHighlight: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let tint: Color
}

private struct HomeReasonQuickLookCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let highlight: HomeReasonQuickHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(highlight.tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: highlight.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(highlight.tint)
            }

            Text(highlight.title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(highlight.value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? VenusTheme.cardSurfaceStrong : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(VenusTheme.cardBorder, lineWidth: 1)
        )
    }
}

private struct HomeSpotlightMetric: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tint)
            }

            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? VenusTheme.cardSurfaceStrong : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(VenusTheme.cardBorder, lineWidth: 1)
        )
    }
}

private struct HomeEvidenceCard: View {
    let index: Int
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 36, height: 36)

                Text("\(index)")
                    .font(.system(.subheadline, design: .rounded).weight(.black))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)

                Text(detail)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .actionReasonCardStyle(cornerRadius: 24)
    }
}

private struct HomeScenarioChart: View {
    let points: [ReasonChartPoint]
    let accent: Color
    let comparison: Color
    let valueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                HomeLegendPill(label: "Com ação", tint: accent)
                HomeLegendPill(label: "Sem ação", tint: comparison)
            }

            Chart(points) { point in
                AreaMark(
                    x: .value("Dia", point.dayOffset),
                    y: .value(valueLabel, point.score)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    point.scenario == "Com ação"
                    ? accent.opacity(0.18)
                    : comparison.opacity(0.12)
                )

                LineMark(
                    x: .value("Dia", point.dayOffset),
                    y: .value(valueLabel, point.score)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: point.scenario == "Com ação" ? 3 : 2, lineCap: .round))
                .foregroundStyle(point.scenario == "Com ação" ? accent : comparison)

                PointMark(
                    x: .value("Dia", point.dayOffset),
                    y: .value(valueLabel, point.score)
                )
                .foregroundStyle(point.scenario == "Com ação" ? accent : comparison)
                .symbolSize(point.scenario == "Com ação" ? 36 : 24)
            }
            .chartXAxis {
                AxisMarks(values: [1, 3, 7]) { value in
                    AxisGridLine().foregroundStyle(Color.clear)
                    AxisTick().foregroundStyle(VenusTheme.textSecondary.opacity(0.2))
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            Text("D+\(day)")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
        }
    }
}

private struct HomeMiniMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(VenusTheme.cardSurfaceStrong.opacity(0.85))
        )
    }
}

private struct HomeMiniMetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.5), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 14, height: 4)
            }

            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(value)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .actionReasonCardStyle(cornerRadius: 20)
    }
}

private struct HomeContextCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 30, height: 30)
                Capsule()
                    .fill(tint.opacity(0.75))
                    .frame(width: 14, height: 4)
            }

            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .actionReasonCardStyle(cornerRadius: 20)
    }
}

private struct HomeNarrativeCard: View {
    let eyebrow: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(tint)

            Text(title)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .actionReasonCardStyle(cornerRadius: 26)
    }
}

private struct HomeStepRow: View {
    let index: Int
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 28, height: 28)

                Text("\(index)")
                    .font(.system(.caption, design: .rounded).weight(.black))
                    .foregroundColor(tint)
            }

            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct HomeLegendPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? VenusTheme.cardSurfaceStrong : Color.white)
        )
    }
}

private struct HomePillBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? tint.opacity(0.18) : tint.opacity(0.12))
        )
    }
}

private struct HomeLockedInsightCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VenusProBadge(compact: true)

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(VenusTheme.accentPurple)

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
            }

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .venusProGlassCardStyle(cornerRadius: 26)
    }
}

private struct HomeActionDecisionCard: View {
    let title: String
    let detail: String
    let badge: String
    let duration: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(badge)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(tint.opacity(0.12)))

                Spacer()

                Text(duration)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .actionReasonCardStyle(cornerRadius: 24)
    }
}

private struct HomeExploreSuggestionPill: View {
    let suggestion: ExploreActionSuggestion

    private var tint: Color {
        switch suggestion.activityCategory.lowercased() {
        case let value where value.contains("mov"):
            return VenusTheme.accentGreen
        case let value where value.contains("sono"), let value where value.contains("auto"):
            return VenusTheme.primary
        case let value where value.contains("conex"), let value where value.contains("rel"):
            return VenusTheme.accentBlue
        default:
            return VenusTheme.moodMintStrong
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: suggestion.iconName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tint)

                Text("\(suggestion.durationMinutes) min")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            Text(suggestion.activityTitle)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(suggestion.activityCategory)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(12)
        .frame(width: 160, alignment: .leading)
        .actionReasonCardStyle(cornerRadius: 20)
    }
}

private struct HomeProtocolLibraryCard: View {
    let suggestion: ExploreActionSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: suggestion.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(VenusTheme.accentBlue)

                Spacer()

                Text("\(Int((suggestion.matchScore * 100).rounded()))% fit")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.moodMintStrong)
            }

            Text(suggestion.activityTitle)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(suggestion.recommendationReason)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(suggestion.durationMinutes) min · \(suggestion.activityCategory)")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .actionReasonCardStyle(cornerRadius: 24)
    }
}

private struct HomeConfidenceScoreCard: View {
    let confidence: Double
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(VenusTheme.cardBorder.opacity(0.55), lineWidth: 6)
                        .frame(width: 58, height: 58)

                    Circle()
                        .trim(from: 0, to: max(0.04, min(confidence, 1)))
                        .stroke(
                            LinearGradient(
                                colors: [VenusTheme.primary, VenusTheme.moodMintStrong],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 58, height: 58)

                    Text("\(Int((confidence * 100).rounded()))%")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.text)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Confiança da recomendação")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text(summary)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HomeConfidenceLinearBar(value: confidence, tint: VenusTheme.moodMintStrong)
        }
        .padding(18)
        .actionReasonCardStyle(cornerRadius: 24)
    }
}

private struct HomeConfidenceLinearBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let clampedValue = max(0, min(value, 1))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(VenusTheme.cardBorder.opacity(0.35))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.45), tint],
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

private struct HomeFlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(chunkedItems, id: \.self) { row in
                HStack(alignment: .top, spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunkedItems: [[Data.Element]] {
        var rows: [[Data.Element]] = []
        var currentRow: [Data.Element] = []

        for (index, item) in items.enumerated() {
            currentRow.append(item)
            if index.isMultiple(of: 2) == false {
                rows.append(currentRow)
                currentRow = []
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

private struct HomeExpandedActionOption {
    let title: String
    let detail: String
    let estimatedMinutes: Int
}

private struct ReasonChartPoint: Identifiable {
    let id = UUID()
    let dayOffset: Int
    let scenario: String
    let score: Double
}

private struct HomeActionReasonCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(colorScheme == .dark ? VenusTheme.cardSurface : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(VenusTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: 18, x: 0, y: 10)
    }
}

private extension View {
    func actionReasonCardStyle(cornerRadius: CGFloat = 28) -> some View {
        modifier(HomeActionReasonCardStyle(cornerRadius: cornerRadius))
    }
}
