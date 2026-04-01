//
//  HomeWrappedView.swift
//  Venus
//
// Created by kauã on 25/03/26

import SwiftUI
import Charts

struct HomeWrappedView: View {
    let actionModel: NextBestAction
    let weeklyInsights: WeeklyStrategicInsights?
    let patternAlert: PatternAlert?
    let actionWhy: ActionWhyInsight?
    let proForecast: ProMoodForecast?
    let isPro: Bool
    let confidenceInsight: ConfidenceImprovementInsight?
    let triggerRecoveryInsight: TriggerRecoveryInsight?
    let weeklyTrend: WeeklyEmotionalTrend?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentIndex = 0
    @State private var textVisible = false
    @State private var progressFill: CGFloat = 0
    @State private var autoAdvanceTask: Task<Void, Never>? = nil
    @State private var showFullDetail = false
    @State private var dragOffset: CGFloat = 0
    @State private var isPaused = false
    @State private var accumulatedProgress: CGFloat = 0
    @State private var seenSlides: Set<Int> = []

    private let slideDuration: Double = 6.0

    private var slides: [WrappedSlideData] {
        var result: [WrappedSlideData] = []

        // 1 — Abertura
        result.append(WrappedSlideData(
            kind: .opening,
            mascotMood: nil,
            bgColor: actionAccent,
            intensity: 5
        ))

        // 2 — O que eu notei
        result.append(WrappedSlideData(
            kind: .observation,
            mascotMood: .calm,
            bgColor: VenusTheme.accentBlue,
            intensity: 4
        ))

        // 3 — O que tá pesando
        if weeklyInsights?.dominantTrigger != nil || patternAlert != nil {
            result.append(WrappedSlideData(
                kind: .trigger,
                mascotMood: .stressed,
                bgColor: VenusTheme.accentOrange,
                intensity: 7
            ))
        }

        // 4 — Sua semana
        if weeklyTrend != nil {
            let mood: MoodType = weeklyTrend?.direction == .improving ? .happy : weeklyTrend?.direction == .declining ? .sad : .calm
            result.append(WrappedSlideData(
                kind: .week,
                mascotMood: mood,
                bgColor: weeklyTrend?.direction == .improving ? VenusTheme.accentGreen : weeklyTrend?.direction == .declining ? VenusTheme.accentPink : VenusTheme.accentBlue,
                intensity: 6
            ))
        }

        // 5 — Se você agir agora
        if triggerRecoveryInsight != nil || proForecast != nil {
            result.append(WrappedSlideData(
                kind: .impact,
                mascotMood: .energetic,
                bgColor: VenusTheme.accentGreen,
                intensity: 8
            ))
        }

        // 6 — Sua confiança
        if confidenceInsight != nil {
            result.append(WrappedSlideData(
                kind: .confidence,
                mascotMood: .calm,
                bgColor: VenusTheme.accentPurple,
                intensity: 5
            ))
        }

        // 7 — A ação
        result.append(WrappedSlideData(
            kind: .action,
            mascotMood: .happy,
            bgColor: actionAccent,
            intensity: 9
        ))

        return result
    }

    private var currentSlide: WrappedSlideData { slides[min(currentIndex, slides.count - 1)] }
    private var actionAccent: Color { actionModel.isHighImpactVariant ? VenusTheme.primary : VenusTheme.accentGreen }

    var body: some View {
        ZStack {
            // Fundo com crossfade de cor
            currentSlide.bgColor
                .opacity(colorScheme == .dark ? 0.18 : 0.12)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentIndex)

            (colorScheme == .dark ? VenusTheme.background : Color(hex: "F8FDF8"))
                .ignoresSafeArea()
                .zIndex(-1)

            // Blob de cor de fundo
            Circle()
                .fill(currentSlide.bgColor.opacity(colorScheme == .dark ? 0.28 : 0.22))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: -60, y: -120)
                .animation(.easeInOut(duration: 0.6), value: currentIndex)
                .allowsHitTesting(false)

            Circle()
                .fill(currentSlide.bgColor.opacity(colorScheme == .dark ? 0.18 : 0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 80, y: 200)
                .animation(.easeInOut(duration: 0.6), value: currentIndex)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Barra de progresso
                WrappedProgressBar(
                    total: slides.count,
                    current: currentIndex,
                    fill: progressFill,
                    seenSlides: seenSlides
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Botão fechar + hint de pausa
                HStack {
                    if isPaused {
                        HStack(spacing: 5) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("pausado")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                        }
                        .foregroundColor(VenusTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(VenusTheme.cardSurface.opacity(0.8))
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .scale))
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(VenusTheme.textSecondary)
                            .padding(10)
                            .background(Circle().fill(VenusTheme.cardSurface.opacity(0.8)))
                    }
                    .buttonStyle(.plain)
                }
                .animation(.easeInOut(duration: 0.2), value: isPaused)
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer()

                // Conteúdo do slide
                slideContent
                    .padding(.horizontal, 28)
                    .opacity(textVisible ? 1 : 0)
                    .offset(y: textVisible ? 0 : 24)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82), value: textVisible)

                Spacer()

                // Mascot + waveform
                VStack(spacing: 0) {
                    VenusMoodMascotOrb(
                        mood: currentSlide.mascotMood,
                        size: 190
                    )
                    .animation(.spring(response: 0.45, dampingFraction: 0.62), value: currentSlide.mascotMood)

                    WrappedWaveform(
                        tint: currentSlide.bgColor,
                        intensity: currentSlide.intensity
                    )
                    .padding(.top, 2)
                }
                .padding(.bottom, 32)
            }

            // Tap zones — esquerda volta, direita avança, segurar pausa
            HStack(spacing: 0) {
                TapHoldZone(onTap: goBack, onHold: pauseSlide, onRelease: resumeSlide)
                TapHoldZone(onTap: goForward, onHold: pauseSlide, onRelease: resumeSlide)
            }
            .ignoresSafeArea()
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { v in
                        if isPaused { resumeSlide() }
                        if v.translation.height > 0 { dragOffset = v.translation.height * 0.4 }
                    }
                    .onEnded { v in
                        if v.translation.height > 80 {
                            dismiss()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragOffset = 0 }
                        }
                    }
            )
        }
        .offset(y: dragOffset)
        .sheet(isPresented: $showFullDetail) {
            NavigationStack {
                HomeActionReasonView(
                    actionModel: actionModel,
                    weeklyInsights: weeklyInsights,
                    patternAlert: patternAlert,
                    actionWhy: actionWhy,
                    proForecast: proForecast,
                    isPro: isPro,
                    confidenceInsight: confidenceInsight,
                    triggerRecoveryInsight: triggerRecoveryInsight,
                    alternativeActions: [],
                    exploreSuggestions: []
                )
            }
        }
        .onAppear { startSlide() }
        .onChange(of: currentIndex) { _, _ in startSlide() }
        .onChange(of: isPaused) { _, paused in
            if !paused { resumeAnimation() }
        }
    }

    // MARK: - Slide content

    @ViewBuilder
    private var slideContent: some View {
        switch currentSlide.kind {
        case .opening:
            WrappedTextBlock(
                eyebrow: "sua leitura de agora",
                title: actionModel.title,
                detail: "eu analisei seus sinais e montei isso pra você. vai levando uns \(actionModel.estimatedMinutes) min.",
                tint: currentSlide.bgColor
            )

        case .observation:
            WrappedTextBlock(
                eyebrow: "o que eu notei",
                title: observationTitle,
                detail: actionWhy?.summary ?? actionModel.strategicReason,
                tint: currentSlide.bgColor
            )

        case .trigger:
            WrappedTextBlock(
                eyebrow: "o que tá pesando",
                title: triggerTitle,
                detail: patternAlert?.detail ?? "esse padrão aparece com frequência no seu histórico recente.",
                tint: currentSlide.bgColor
            )

        case .week:
            VStack(alignment: .leading, spacing: 20) {
                WrappedTextBlock(
                    eyebrow: "sua semana",
                    title: weekTitle,
                    detail: weeklyTrend?.summary ?? "",
                    tint: currentSlide.bgColor
                )
                if let trend = weeklyTrend {
                    WrappedWeekBars(trend: trend, tint: currentSlide.bgColor)
                }
            }

        case .impact:
            VStack(alignment: .leading, spacing: 20) {
                WrappedTextBlock(
                    eyebrow: "se você agir agora",
                    title: impactTitle,
                    detail: impactDetail,
                    tint: currentSlide.bgColor
                )
                if let insight = triggerRecoveryInsight {
                    WrappedImpactLines(insight: insight, tint: currentSlide.bgColor)
                }
            }

        case .confidence:
            VStack(alignment: .leading, spacing: 20) {
                WrappedTextBlock(
                    eyebrow: "sua confiança pra agir",
                    title: confidenceTitle,
                    detail: confidenceInsight?.personalizedSummary ?? "",
                    tint: currentSlide.bgColor
                )
                if let c = confidenceInsight {
                    WrappedConfidenceRing(value: c.currentConfidence, tint: currentSlide.bgColor)
                }
            }

        case .action:
            VStack(alignment: .leading, spacing: 24) {
                WrappedTextBlock(
                    eyebrow: "próximo passo",
                    title: actionModel.title,
                    detail: actionModel.detail,
                    tint: currentSlide.bgColor
                )
                HStack(spacing: 12) {
                    Button {
                        // começar — em breve
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("começar agora")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(VenusTheme.primaryGradient)
                        .clipShape(Capsule())
                        .shadow(color: actionAccent.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showFullDetail = true
                    } label: {
                        Text("ver tudo")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(VenusTheme.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(VenusTheme.cardSurface.opacity(0.9))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Navigation

    private func goForward() {
        autoAdvanceTask?.cancel()
        isPaused = false
        if currentIndex < slides.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) { currentIndex += 1 }
        } else {
            dismiss()
        }
    }

    private func goBack() {
        autoAdvanceTask?.cancel()
        isPaused = false
        if currentIndex > 0 {
            withAnimation(.easeInOut(duration: 0.25)) { currentIndex -= 1 }
        } else {
            // reinicia o slide atual
            startSlide()
        }
    }

    private func pauseSlide() {
        guard !isPaused else { return }
        isPaused = true
        accumulatedProgress = progressFill
        autoAdvanceTask?.cancel()
        // congela a animação
        withAnimation(.linear(duration: 0)) { progressFill = accumulatedProgress }
    }

    private func resumeSlide() {
        guard isPaused else { return }
        isPaused = false
    }

    private func resumeAnimation() {
        let remaining = slideDuration * Double(1 - accumulatedProgress)
        guard remaining > 0 else { goForward(); return }

        withAnimation(.linear(duration: remaining)) { progressFill = 1 }

        autoAdvanceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run { goForward() }
        }
    }

    private func startSlide() {
        textVisible = false
        progressFill = 0
        accumulatedProgress = 0
        isPaused = false
        autoAdvanceTask?.cancel()
        seenSlides.insert(currentIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                textVisible = true
            }
        }

        withAnimation(.linear(duration: slideDuration)) { progressFill = 1 }

        autoAdvanceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(slideDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run { goForward() }
        }
    }

    // MARK: - Computed strings

    private var observationTitle: String {
        if let trigger = weeklyInsights?.dominantTrigger { return trigger }
        if let alert = patternAlert { return alert.title }
        return "você tá carregando bastante coisa"
    }

    private var triggerTitle: String {
        if let trigger = weeklyInsights?.dominantTrigger { return trigger }
        if let alert = patternAlert { return alert.title }
        return "tem um padrão se repetindo"
    }

    private var weekTitle: String {
        switch weeklyTrend?.direction {
        case .improving: return "sua semana tá melhorando"
        case .declining: return "sua semana tá mais pesada"
        case .stable:    return "sua semana tá estável"
        case nil:        return "sua semana"
        }
    }

    private var impactTitle: String {
        guard let insight = triggerRecoveryInsight else {
            return "a diferença é real"
        }
        let delta = insight.highlightedProjection.first(where: { $0.dayOffset == 7 })?.delta ?? 0
        if delta > 0.1 { return "você vai se sentir mais leve" }
        if delta > 0.05 { return "dá pra notar a diferença" }
        return "cada passo conta"
    }

    private var impactDetail: String {
        if let insight = triggerRecoveryInsight {
            return insight.highlightedSummary
        }
        return "agir agora muda o rumo dos próximos dias."
    }

    private var confidenceTitle: String {
        guard let c = confidenceInsight else { return "você tá mais forte do que parece" }
        let pct = c.currentConfidence
        if pct >= 0.7 { return "você tá firme pra agir" }
        if pct >= 0.45 { return "você tem base pra isso" }
        return "vai devagar, mas vai"
    }
}

// MARK: - Slide Data

private struct WrappedSlideData {
    enum Kind { case opening, observation, trigger, week, impact, confidence, action }
    let kind: Kind
    let mascotMood: MoodType?
    let bgColor: Color
    let intensity: Int
}

// MARK: - Progress Bar

private struct WrappedProgressBar: View {
    let total: Int
    let current: Int
    let fill: CGFloat
    let seenSlides: Set<Int>

    @Environment(\.colorScheme) private var colorScheme

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.18)
    }
    private var fillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.75)
    }
    private var seenColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.40)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(trackColor)

                        Capsule()
                            .fill(i < current ? seenColor : fillColor)
                            .frame(width: segmentWidth(index: i, totalWidth: geo.size.width))
                    }
                }
                .frame(height: 3)
            }
        }
    }

    private func segmentWidth(index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < current { return totalWidth }
        if index == current { return totalWidth * fill }
        return 0
    }
}

// MARK: - Text Block

private struct WrappedTextBlock: View {
    let eyebrow: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(eyebrow)
                .font(.system(.caption, design: .rounded).weight(.black))
                .foregroundColor(tint)
                .tracking(0.8)

            Text(title)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Week Bars

private struct WrappedWeekBars: View {
    let trend: WeeklyEmotionalTrend
    let tint: Color

    @State private var appeared = false

    private var prev: Double { max(0.1, min(trend.previousWeekScore ?? 0.4, 1)) }
    private var curr: Double { max(0.1, min(trend.currentWeekScore, 1)) }
    private var delta: Double { curr - prev }
    private var deltaLabel: String {
        let pct = Int(abs(delta) * 100)
        if delta > 0.02 { return "+\(pct)% melhor" }
        if delta < -0.02 { return "-\(pct)% mais pesado" }
        return "estável"
    }
    private var deltaColor: Color {
        delta > 0.02 ? tint : delta < -0.02 ? VenusTheme.accentPink : VenusTheme.textSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 20) {
                barColumn(label: "semana passada", value: appeared ? prev : 0, pct: Int(prev * 100), color: VenusTheme.textSecondary.opacity(0.35))
                barColumn(label: "essa semana", value: appeared ? curr : 0, pct: Int(curr * 100), color: tint)
            }
            .frame(height: 90)

            HStack(spacing: 6) {
                Image(systemName: delta > 0.02 ? "arrow.up.right" : delta < -0.02 ? "arrow.down.right" : "minus")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(deltaColor)
                Text(deltaLabel)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(deltaColor)
                Text("em relação à semana passada")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) { appeared = true }
        }
    }

    private func barColumn(label: String, value: Double, pct: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(pct)%")
                .font(.system(.caption2, design: .rounded).weight(.black))
                .foregroundColor(color == tint ? tint : VenusTheme.textSecondary)
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(width: 48, height: max(12, 72 * value))
            Text(label)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
        }
    }
}

// MARK: - Impact Lines

private struct WrappedImpactLines: View {
    let insight: TriggerRecoveryInsight
    let tint: Color

    @State private var appeared = false

    private var withAction: [CGFloat] {
        insight.highlightedProjection.map { CGFloat($0.scoreWithAction) }
    }
    private var withoutAction: [CGFloat] {
        insight.highlightedProjection.map { CGFloat($0.scoreWithoutAction) }
    }
    private var dayLabels: [String] {
        insight.highlightedProjection.enumerated().map { i, _ in
            i == 0 ? "hoje" : i == insight.highlightedProjection.count - 1 ? "+\(insight.highlightedProjection.count - 1)d" : ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                legendDot(color: tint, label: "agindo agora")
                legendDot(color: VenusTheme.textSecondary.opacity(0.4), label: "sem agir")
            }

            GeometryReader { geo in
                ZStack {
                    linePath(values: withoutAction, width: geo.size.width, height: geo.size.height)
                        .stroke(VenusTheme.textSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))

                    linePath(values: withAction, width: geo.size.width, height: geo.size.height)
                        .trim(from: 0, to: appeared ? 1 : 0)
                        .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .animation(.easeInOut(duration: 1.0).delay(0.3), value: appeared)
                }

                // Labels de eixo X
                HStack {
                    Text("hoje")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                    Spacer()
                    Text("+\(insight.highlightedProjection.count - 1) dias")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 80)
        }
        .onAppear { appeared = true }
    }

    private func linePath(values: [CGFloat], width: CGFloat, height: CGFloat) -> Path {
        guard values.count > 1 else { return Path() }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let range = max(maxV - minV, 0.01)
        let step = width / CGFloat(values.count - 1)

        var path = Path()
        for (i, v) in values.enumerated() {
            let x = CGFloat(i) * step
            let y = height - ((v - minV) / range) * height * 0.85
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
        }
    }
}

// MARK: - Confidence Ring

private struct WrappedConfidenceRing: View {
    let value: Double
    let tint: Color

    @State private var appeared = false

    private var label: String {
        if value >= 0.7 { return "alta" }
        if value >= 0.45 { return "média" }
        return "baixa"
    }
    private var description: String {
        if value >= 0.7 { return "Você tem histórico de agir bem nessa situação." }
        if value >= 0.45 { return "Você já passou por isso antes e conseguiu." }
        return "Vai devagar — cada pequeno passo conta." }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.15), lineWidth: 10)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: appeared ? max(0.04, value) : 0)
                    .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80, height: 80)
                    .animation(.spring(response: 1.0, dampingFraction: 0.72).delay(0.2), value: appeared)

                Text("\(Int(value * 100))%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("confiança pra agir")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
                Text(label)
                    .font(.system(.title2, design: .rounded).weight(.black))
                    .foregroundColor(VenusTheme.text)
                Text(description)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - TapHoldZone

private struct TapHoldZone: View {
    let onTap: () -> Void
    let onHold: () -> Void
    let onRelease: () -> Void

    @State private var holdTask: Task<Void, Never>? = nil
    @State private var didHold = false

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if holdTask == nil {
                            didHold = false
                            holdTask = Task {
                                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
                                guard !Task.isCancelled else { return }
                                await MainActor.run {
                                    didHold = true
                                    onHold()
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        holdTask?.cancel()
                        holdTask = nil
                        if didHold {
                            onRelease()
                        } else {
                            onTap()
                        }
                        didHold = false
                    }
            )
    }
}

// MARK: - Waveform

private struct WrappedWaveform: View {
    let tint: Color
    let intensity: Int

    private var scale: Double { 0.3 + (Double(intensity) / 10.0) * 0.7 }
    private var heights: [CGFloat] {
        let base: [CGFloat] = [10, 16, 26, 38, 52, 64, 76, 64, 52, 38, 26, 16, 10]
        return base.map { $0 * scale }
    }

    var body: some View {
        VenusMoodWaveform(
            tint: tint,
            secondaryTint: tint.opacity(0.5),
            barHeights: heights
        )
        .animation(.easeInOut(duration: 0.5), value: intensity)
    }
}
