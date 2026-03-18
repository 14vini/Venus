//
//  HomeMinimalComponents.swift
//  Venus
//

import SwiftUI
import Charts

struct HomeActionReasonSheet: View {
    @Environment(\.colorScheme) private var colorScheme

    let actionModel: NextBestAction
    let weeklyInsights: WeeklyStrategicInsights?
    let patternAlert: PatternAlert?
    let actionWhy: ActionWhyInsight?
    let proForecast: ProMoodForecast?
    let isPro: Bool
    let confidenceInsight: ConfidenceImprovementInsight?
    let triggerRecoveryInsight: TriggerRecoveryInsight?

    @State private var animateBackdrop = false
    @State private var pulseHero = false
    @State private var revealContent = false

    var body: some View {
        ZStack {
            animatedBackground

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    introSection
                    heroCard
                    diagnosisSection
                    impactSection
                    contextSection
                    forecastSection

                    if let expandedActionOption {
                        expandedActionSection(option: expandedActionOption)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 34)
                .opacity(revealContent ? 1 : 0)
                .offset(y: revealContent ? 0 : 18)
            }
        }
        .background(VenusTheme.background)
        .onAppear(perform: startAnimations)
    }

    private var animatedBackground: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        VenusTheme.backgroundWarm,
                        VenusTheme.backgroundBlush,
                        VenusTheme.backgroundCool,
                        VenusTheme.backgroundSoft
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(VenusTheme.ambientWarm.opacity(colorScheme == .dark ? 0.28 : 0.24))
                    .frame(width: 260, height: 260)
                    .blur(radius: 28)
                    .scaleEffect(animateBackdrop ? 1.15 : 0.85)
                    .offset(
                        x: animateBackdrop ? geometry.size.width * 0.28 : -geometry.size.width * 0.18,
                        y: animateBackdrop ? -70 : -10
                    )

                Circle()
                    .fill(VenusTheme.ambientRose.opacity(colorScheme == .dark ? 0.22 : 0.18))
                    .frame(width: 240, height: 240)
                    .blur(radius: 36)
                    .scaleEffect(animateBackdrop ? 0.9 : 1.2)
                    .offset(
                        x: animateBackdrop ? geometry.size.width * 0.45 : geometry.size.width * 0.12,
                        y: animateBackdrop ? geometry.size.height * 0.6 : geometry.size.height * 0.38
                    )

                Circle()
                    .fill(VenusTheme.ambientCool.opacity(colorScheme == .dark ? 0.2 : 0.16))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)
                    .scaleEffect(animateBackdrop ? 1.05 : 0.82)
                    .offset(
                        x: animateBackdrop ? geometry.size.width * 0.08 : geometry.size.width * 0.42,
                        y: animateBackdrop ? geometry.size.height * 0.2 : geometry.size.height * 0.08
                    )
            }
            .ignoresSafeArea()
        }
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label(isPro ? "Leitura aprofundada" : "Leitura essencial", systemImage: isPro ? "crown.fill" : "sparkles")
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

                Spacer()

                if let confidence = explanationConfidence {
                    Text("\(Int((confidence * 100).rounded()))% confiança")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(cardFill.opacity(0.92)))
                        .overlay(Capsule().stroke(cardBorder, lineWidth: 1))
                }
            }

            Text("Por que esta ação faz sentido agora")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(actionWhy?.summary ?? actionModel.strategicReason)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                                .lineLimit(1)
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

            HStack(spacing: 12) {
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
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.45), lineWidth: 1)
        )
        .shadow(color: actionAccent.opacity(colorScheme == .dark ? 0.18 : 0.14), radius: 18, x: 0, y: 12)
    }

    private var diagnosisSection: some View {
        HomeReasonSection(
            title: "Diagnóstico em camadas",
            subtitle: "Os sinais mais fortes que fizeram essa ação subir para o topo agora.",
            icon: "waveform.path.ecg",
            tint: VenusTheme.accentOrange
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
    private var impactSection: some View {
        HomeReasonSection(
            title: "Como isso mexe no seu estado mental",
            subtitle: "Aqui está a diferença esperada quando você executa essa ação no timing certo.",
            icon: "sparkles.rectangle.stack.fill",
            tint: VenusTheme.accentPink
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
                            accent: VenusTheme.accentOrange,
                            comparison: Color.secondary.opacity(colorScheme == .dark ? 0.45 : 0.35),
                            valueLabel: "Índice"
                        )
                    }
                    .padding(18)
                    .actionReasonCardStyle()

                    if !triggerRecoveryInsight.additionalAreaProjections.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(triggerRecoveryInsight.additionalAreaProjections.prefix(3)) { projection in
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
                                    .frame(width: 200, alignment: .leading)
                                    .actionReasonCardStyle(cornerRadius: 24)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        }
                        .scrollClipDisabled()
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
                                tint: VenusTheme.accentPink
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
            subtitle: "O pano de fundo comportamental que está influenciando essa sugestão.",
            icon: "calendar.badge.exclamationmark",
            tint: VenusTheme.accentBlue
        ) {
            VStack(spacing: 16) {
                if weeklyInsights != nil || patternAlert != nil {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        if let trigger = weeklyInsights?.dominantTrigger {
                            HomeContextCard(title: "Gatilho dominante", value: trigger, tint: VenusTheme.accentOrange)
                        }

                        if let window = weeklyInsights?.criticalWindow {
                            HomeContextCard(title: "Janela crítica", value: window, tint: VenusTheme.accentPink)
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

                            if let recoveryProtocol = weeklyInsights.recoveryProtocol {
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
                        }
                    }

                    if let patternAlert {
                        HomeNarrativeCard(
                            eyebrow: "Alerta ativo",
                            title: patternAlert.title,
                            detail: patternAlert.detail,
                            tint: VenusTheme.accentOrange
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
            title: "Projeção emocional",
            subtitle: "Uma visão do que tende a acontecer se você agir agora ou se deixar passar.",
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
                            HomePillBadge(text: riskAlert, icon: "exclamationmark.triangle.fill", tint: VenusTheme.accentOrange)
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

    private func expandedActionSection(option: HomeExpandedActionOption) -> some View {
        HomeReasonSection(
            title: "Plano ampliado",
            subtitle: "Se você tiver mais energia hoje, essa é a versão estendida da mesma estratégia.",
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
        actionModel.isHighImpactVariant ? VenusTheme.accentOrange : VenusTheme.accentGreen
    }

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                actionAccent.opacity(colorScheme == .dark ? 0.2 : 0.18),
                colorScheme == .dark ? Color(hex: "151B2A") : VenusTheme.cardSurface.opacity(0.92),
                colorScheme == .dark ? Color(hex: "0F1422") : VenusTheme.primary.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardFill: Color {
        colorScheme == .dark ? Color(hex: "161D2B").opacity(0.94) : Color.white.opacity(0.78)
    }

    private var cardBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.52)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private var explanationConfidence: Double? {
        actionWhy?.confidence ?? weeklyInsights?.confidence ?? proForecast?.confidence
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

        withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
            animateBackdrop = true
        }

        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            pulseHero = true
        }

        withAnimation(.spring(response: 0.72, dampingFraction: 0.84)) {
            revealContent = true
        }
    }

    private var expandedActionOption: HomeExpandedActionOption? {
        guard !actionModel.isHighImpactVariant else { return nil }

        switch actionModel.kind {
        case .resolveAvoidedTask:
            return HomeExpandedActionOption(
                title: "Sprint de execução profunda",
                detail: "Bloqueie 30 minutos para concluir uma tarefa importante: 25 min foco + 5 min revisão.",
                estimatedMinutes: 30
            )
        case .sleepReset:
            return HomeExpandedActionOption(
                title: "Protocolo de sono completo",
                detail: "Faça um fechamento de dia de 35 minutos: reduzir luz, organizar amanhã e desacelerar.",
                estimatedMinutes: 35
            )
        case .environmentReset:
            return HomeExpandedActionOption(
                title: "Reset completo de ambiente",
                detail: "Organize seu espaço por 25 minutos e elimine três pontos de fricção visual.",
                estimatedMinutes: 25
            )
        case .quickExercise:
            return HomeExpandedActionOption(
                title: "Sessão de movimento estendida",
                detail: "Faça 30 minutos de caminhada forte ou treino leve para estabilizar energia e foco.",
                estimatedMinutes: 30
            )
        case .difficultMessage:
            return HomeExpandedActionOption(
                title: "Conversa estruturada",
                detail: "Reserve 25 minutos para preparar e conduzir a conversa difícil com clareza.",
                estimatedMinutes: 25
            )
        case .deepDisconnect:
            return HomeExpandedActionOption(
                title: "Ritual de recuperação",
                detail: "Faça 30 minutos sem tela: respiração, silêncio e rotina curta de regulação.",
                estimatedMinutes: 30
            )
        case .weeklyPlanning:
            return HomeExpandedActionOption(
                title: "Planejamento tático",
                detail: "Reserve 35 minutos para revisar semana, escolher prioridades e reduzir sobrecarga.",
                estimatedMinutes: 35
            )
        }
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
    }
}

private struct HomeSpotlightMetric: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.52))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.48), lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(value)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.22), tint.opacity(0.65)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .actionReasonCardStyle(cornerRadius: 22)
    }
}

private struct HomeContextCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Capsule()
                .fill(tint.opacity(0.75))
                .frame(width: 48, height: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .actionReasonCardStyle(cornerRadius: 22)
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
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : VenusTheme.cardSurfaceStrong.opacity(0.85))
        )
        .overlay(
            Capsule()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : VenusTheme.cardBorder.opacity(0.6), lineWidth: 1)
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
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? tint.opacity(0.18) : tint.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(colorScheme == .dark ? tint.opacity(0.24) : tint.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct HomeLockedInsightCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(VenusTheme.accentOrange)

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
        .actionReasonCardStyle(cornerRadius: 26)
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
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color(hex: "161D2B").opacity(0.98) : VenusTheme.cardSurface.opacity(0.96),
                                colorScheme == .dark ? Color(hex: "0F1524").opacity(0.96) : Color.white.opacity(0.48)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.46), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.08), radius: 18, x: 0, y: 10)
    }
}

private extension View {
    func actionReasonCardStyle(cornerRadius: CGFloat = 28) -> some View {
        modifier(HomeActionReasonCardStyle(cornerRadius: cornerRadius))
    }
}
