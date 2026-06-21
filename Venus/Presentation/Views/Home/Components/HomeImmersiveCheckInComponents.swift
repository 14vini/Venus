//
//  HomeImmersiveCheckInComponents.swift
//  Venus
//
//  Created by Kaua on 24/03/26.
//

import SwiftUI

struct HomeImmersiveCheckInHeroSection: View {
    let selectedMood: MoodType?
    let hasCheckedInToday: Bool
    let progressLabel: String
    let statusLabel: String
    let isSelectionLocked: Bool
    let greetingText: String
    let moodIntensity: Int?
    let onSelectMood: (MoodType) -> Void

    @State private var shownMood: MoodType? = nil
    @State private var orbPulse: CGFloat = 1
    @State private var orbOpacity: Double = 1

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 16) {
                // Orb + greeting + waveform
                VStack(spacing: 12) {
                    MoodGreetingCard(text: greetingText)
                        .zIndex(1)

                    VenusMoodOrb(
                        mood: shownMood,
                        size: 140
                    )
                    .scaleEffect(orbPulse)
                    .opacity(orbOpacity)
                    .animation(.spring(response: 0.45, dampingFraction: 0.62), value: shownMood)

                    MoodWaveform(
                        mood: shownMood,
                        intensity: moodIntensity
                    )
                    .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 14) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            HomeFeelingChip(
                                title: mood.rawValue,
                                isSelected: shownMood == mood,
                                tint: Color(hex: mood.colorHex),
                                action: { handleMoodTap(mood) }
                            )
                        }
                    }

                    MoodShortcutStrip(
                        title: "Se bateu duvida",
                        options: MoodShortcutOption.indecisive,
                        onSelect: handleMoodTap
                    )

                    Text(hasCheckedInToday
                         ? "Voce pode refazer a leitura quando quiser."
                         : "Escolha o mais proximo e eu abro o check-in.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, minHeight: 400)
        }
        .onAppear { shownMood = selectedMood }
        .onChange(of: selectedMood) { _, new in shownMood = new }
    }

    private func handleMoodTap(_ mood: MoodType) {
        // Fase 1: encolhe e dissolve suavemente
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            orbPulse = 0.88
            orbOpacity = 0.0
        }

        // Fase 2: troca o mood no meio da transição (invisível)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            shownMood = mood
        }

        // Fase 3: expande de volta com a nova cor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.58)) {
                orbPulse = 1.06
                orbOpacity = 1.0
            }
        }

        // Fase 4: assenta no tamanho normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                orbPulse = 1.0
            }
        }

        // Fase 5: abre o check-in depois que o usuário viu a reação
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
            onSelectMood(mood)
        }
    }

    private var heroSubtitle: String { "" }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let days: Int
    let celebrated: Bool

    @State private var animateFlame = false
    @State private var burstScale: CGFloat = 1
    @State private var showConfetti = false
    @State private var orbPulse = false

    private var milestone: Int? {
        [3, 7, 14, 30].first { $0 == days }
    }

    private var milestoneLabel: String? {
        guard let m = milestone else { return nil }
        switch m {
        case 3:  return "⚡️ 3 dias!"
        case 7:  return "🔥 1 semana!"
        case 14: return "⭐️ 2 semanas!"
        case 30: return "🏆 1 mês!"
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            // Confetti burst no milestone
            if showConfetti {
                ConfettiBurst()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: celebrated ? "flame.fill" : "flame")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(VenusTheme.accentOrange)
                        .scaleEffect(animateFlame ? 1.2 : 1.0)
                        .rotationEffect(.degrees(animateFlame ? 10 : -10))

                    Text("\(days)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .scaleEffect(burstScale)
                }

                if let label = milestoneLabel, celebrated {
                    Text(label)
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.accentOrange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear { triggerIfNeeded() }
        .onChange(of: celebrated) { _, _ in triggerIfNeeded() }
        .onChange(of: days) { _, _ in triggerIfNeeded() }
    }

    private func triggerIfNeeded() {
        guard celebrated else {
            animateFlame = false
            return
        }

        // Burst de escala
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { burstScale = 1.35 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { burstScale = 1.0 }
        }

        // Chama animação por 1 segundo e para
        withAnimation(.easeInOut(duration: 0.25).repeatCount(4, autoreverses: true)) {
            animateFlame = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.default) { animateFlame = false }
        }

        // Confetti apenas nos milestones
        if milestone != nil {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showConfetti = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showConfetti = false }
            }
        }
    }
}

// MARK: - Confetti Burst

private struct ConfettiBurst: View {
    private struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let rotation: Double
    }

    private let particles: [Particle] = (0..<18).map { i in
        let colors: [Color] = [
            VenusTheme.accentOrange, VenusTheme.accentPink,
            VenusTheme.accentBlue, VenusTheme.accentGreen,
            VenusTheme.accentPurple, Color(hex: "FFD580")
        ]
        return Particle(
            color: colors[i % colors.count],
            angle: Double(i) * (360.0 / 18),
            distance: CGFloat.random(in: 28...56),
            size: CGFloat.random(in: 5...9),
            rotation: Double.random(in: 0...360)
        )
    }

    @State private var exploded = false

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 1.6)
                    .rotationEffect(.degrees(p.rotation))
                    .offset(
                        x: exploded ? cos(p.angle * .pi / 180) * p.distance : 0,
                        y: exploded ? sin(p.angle * .pi / 180) * p.distance - 10 : 0
                    )
                    .opacity(exploded ? 0 : 1)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6).delay(Double.random(in: 0...0.1)),
                        value: exploded
                    )
            }
        }
        .onAppear {
            withAnimation { exploded = true }
        }
    }
}

// MARK: - Mood Greeting Card

private struct MoodGreetingCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(VenusTheme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(VenusTheme.cardSurface)
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Mood Waveform

private struct MoodWaveform: View {
    let mood: MoodType?
    let intensity: Int? // 1-10

    private var tint: Color {
        guard let mood else { return VenusTheme.moodMintStrong }
        return Color(hex: mood.orbColors.mid)
    }

    private var secondaryTint: Color {
        guard let mood else { return VenusTheme.moodMint }
        return Color(hex: mood.orbColors.light)
    }

    // Altura máxima das barras escala com intensidade (1-10 → 0.3-1.0)
    private var heightScale: Double {
        guard let intensity else { return 0.45 }
        return 0.3 + (Double(intensity) / 10.0) * 0.7
    }

    private var barHeights: [CGFloat] {
        let base: [CGFloat] = [14, 20, 30, 44, 58, 72, 84, 72, 58, 44, 30, 20, 14]
        return base.map { $0 * heightScale }
    }

    var body: some View {
        VenusMoodWaveform(
            tint: tint,
            secondaryTint: secondaryTint,
            barHeights: barHeights
        )
    }
}

struct HomeInlineCheckInDetailsSection: View {
    let selectedMood: MoodType
    let progressLabel: String
    @ObservedObject var viewModel: MoodCheckInViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Text("Continue o check-in")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Spacer(minLength: 12)

                VenusGlassPill(
                    title: progressLabel,
                    systemImage: "arrow.down.circle.fill"
                )
            }

            HStack(spacing: 14) {
                Text(selectedMood.emoji)
                    .font(.system(size: 34))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Você escolheu \(selectedMood.rawValue.lowercased()).")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text("Agora completa o contexto para a Home e a tela de reflexões entenderem melhor o seu momento.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(cornerRadius: 28, opacity: 0.78)

            MoodCheckInDetailsCard(
                selectedIntensity: $viewModel.selectedIntensity,
                quickTags: viewModel.quickTags,
                selectedTags: viewModel.selectedTags,
                onToggleTag: viewModel.toggleTag,
                affectedAreas: viewModel.affectedAreas,
                selectedAffectedArea: $viewModel.selectedAffectedArea,
                onSelectAffectedArea: viewModel.selectAffectedArea,
                energyLevels: viewModel.energyLevels,
                selectedEnergyLevel: $viewModel.selectedEnergyLevel,
                onSelectEnergyLevel: viewModel.selectEnergyLevel,
                availableTimes: viewModel.availableTimes,
                selectedAvailableTime: $viewModel.selectedAvailableTime,
                onSelectAvailableTime: viewModel.selectAvailableTime,
                controlLevels: viewModel.controlLevels,
                selectedControlLevel: $viewModel.selectedControlLevel,
                onSelectControlLevel: viewModel.selectControlLevel,
                selectedMentalClarity: $viewModel.selectedMentalClarity,
                sleepQualities: viewModel.sleepQualities,
                selectedSleepQuality: $viewModel.selectedSleepQuality,
                onSelectSleepQuality: viewModel.selectSleepQuality,
                bodySignalOptions: viewModel.bodySignalOptions,
                selectedBodySignals: viewModel.selectedBodySignals,
                onToggleBodySignal: viewModel.toggleBodySignal,
                note: $viewModel.note
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeReflectionsPreviewSection: View {
    let mood: MoodType?
    let intensity: Int?
    let tags: [String]
    let bodySignals: [String]
    let energyLevel: MoodEnergyLevel?
    let affectedArea: MoodAffectedArea?
    let weeklyTrend: WeeklyEmotionalTrend?
    let patternAlert: PatternAlert?
    let weeklyInsights: WeeklyStrategicInsights?
    let isLoadingInsights: Bool
    var onLookIntoMirror: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cabeçalho
            HStack(alignment: .center) {
                Text("Reflexões")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundColor(VenusTheme.text)

                Spacer()

                if isLoadingInsights {
                    ProgressView()
                        .tint(VenusTheme.moodMintStrong)
                        .scaleEffect(0.8)
                }
            }

            // Narrativa principal
            ReflectionNarrativeCard(
                narrative: narrative,
                tint: narrativeTint,
                isLoading: isLoadingInsights
            )

            // Botão Olhar no Espelho (Mirror)
            if mood != nil && !isLoadingInsights {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onLookIntoMirror()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(VenusTheme.moodMintStrong.opacity(0.14))
                                .frame(width: 44, height: 44)
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(VenusTheme.moodMintStrong)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Olhar no Espelho")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.text)

                            Text("veja os insights profundos do seu cérebro hoje")
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                                .foregroundColor(VenusTheme.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.96))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(VenusTheme.moodMintStrong.opacity(0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Narrativa gerada a partir dos dados

    private var narrative: String {
        guard !isLoadingInsights else {
            return "Estou lendo os seus sinais e montando uma leitura do seu momento agora..."
        }

        guard let mood else {
            return "Quando você fizer o check-in, eu transformo tudo isso em uma leitura do seu dia — em uma frase só."
        }

        var opening = ""
        switch mood {
        case .happy:
            if energyLevel == .high {
                opening = "Que bom ver você com tanta disposição e com uma energia tão positiva hoje!"
            } else if energyLevel == .low {
                opening = "Você parece estar em um momento feliz, embora a sua bateria mental esteja um pouco baixa."
            } else {
                opening = "Você está com uma sintonia leve e com o astral lá em cima hoje."
            }
        case .calm:
            opening = "Hoje você parece estar em um ritmo mais tranquilo, com a mente mais serena e em paz."
        case .energetic:
            opening = "Você está esbanjando energia hoje! É um ótimo momento para aproveitar esse pique."
        case .stressed:
            opening = "Parece que o dia está exigindo bastante de você e a mente está sob pressão."
        case .sad:
            opening = "Hoje parece estar sendo um dia mais cinza ou recolhido para você."
        case .tired:
            opening = "Sua bateria mental está pedindo um descanso e o corpo sente esse cansaço."
        }

        var middle = ""
        if let alert = patternAlert {
            let detail = alert.detail.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            middle = " Percebi que \(detail.lowercased())."
        } else if let trigger = weeklyInsights?.dominantTrigger {
            middle = " Notei que as coisas relacionadas a \(trigger.lowercased()) têm demandado mais atenção ou pesado na sua rotina."
        } else if let area = affectedArea {
            middle = " Hoje, o seu foco e a sua atenção parecem estar bastante voltados para a área de \(area.rawValue.lowercased())."
        }

        var trendText = ""
        if let trend = weeklyTrend {
            switch trend.direction {
            case .improving:
                trendText = " O bom é perceber que, comparando com a semana passada, você está conseguindo lidar com as coisas de forma mais leve."
            case .declining:
                trendText = " Esta semana tem se mostrado um pouco mais desafiadora e cansativa do que as anteriores."
            case .stable:
                break
            }
        }

        let closing = " Tire um momento para respirar fundo e respeitar o seu ritmo de hoje."

        let fullText = [opening, middle, trendText, closing]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
            
        return fullText
    }

    private var narrativeTint: Color {
        guard let mood else { return VenusTheme.moodMintStrong }
        return Color(hex: mood.orbColors.mid)
    }
}

// MARK: - Narrative Card

private struct ReflectionNarrativeCard: View {
    let narrative: String
    let tint: Color
    let isLoading: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)

                Text("Leitura do seu dia")
                    .font(.system(.caption, design: .rounded).weight(.black))
                    .foregroundColor(tint)
                    .tracking(0.4)
            }

            Text(narrative)
                .font(.system(size: 19, weight: .medium, design: .serif))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
                .redacted(reason: isLoading ? .placeholder : [])
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    colorScheme == .dark
                    ? Color(hex: "1E2E20")
                    : Color.white.opacity(0.96)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: tint.opacity(colorScheme == .dark ? 0.12 : 0.08), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Action Card


private struct HomeReflectionLeadCard: View {
    let title: String
    let detail: String
    let eyebrow: String
    let pills: [String]
    var onReasonTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(eyebrow.uppercased())
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(0.6)

                    Text(title)
                        .font(.system(size: 26, weight: .black, design: .serif))
                        .foregroundColor(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(VenusTheme.accentOrange.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(VenusTheme.accentOrange)
                }
            }

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !pills.isEmpty {
                FlexiblePillRow(items: pills)
            }

            // "Por que isso?" — prominent full-width CTA, only when action exists
            if let onReasonTap {
                Button(action: onReasonTap) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(VenusTheme.accentBlue.opacity(0.14))
                                .frame(width: 34, height: 34)
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(VenusTheme.accentBlue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Entender por que essa ação")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.text)
                            Text("Abra a leitura estratégica completa")
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .foregroundColor(VenusTheme.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(VenusTheme.accentBlue)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(VenusTheme.accentBlue.opacity(colorScheme == .dark ? 0.12 : 0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(VenusTheme.accentBlue.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.992))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.9) : Color(hex: "C8D8C2").opacity(0.96),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.08), radius: 14, x: 0, y: 10)
    }
}

private struct HomeReflectionsWeeklyCard: View {
    let title: String
    let detail: String
    let previousValue: Double?
    let currentValue: Double?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Comparativo semanal")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
            }

            VStack(spacing: 12) {
                HomeReflectionBarRow(
                    label: "Semana passada",
                    value: normalized(previousValue),
                    tint: VenusTheme.accentBlue
                )
                HomeReflectionBarRow(
                    label: "Esta semana",
                    value: normalized(currentValue),
                    tint: VenusTheme.moodMintStrong
                )
            }

            Text(detail)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.985))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.92),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.06), radius: 10, x: 0, y: 6)
    }

    private func normalized(_ value: Double?) -> Double {
        guard let value else { return 0.42 }
        return max(0.12, min(value, 1))
    }
}

private struct HomeReflectionBarRow: View {
    let label: String
    let value: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)

                Spacer()

                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(tint)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(VenusTheme.cardBorder.opacity(0.32))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.45), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(24, geometry.size.width * value))
                }
            }
            .frame(height: 8)
        }
    }
}

private struct HomeReflectionPriorityItemData: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let tint: Color
}

private struct HomeReflectionPriorityRow: View {
    let item: HomeReflectionPriorityItemData

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.14))
                    .frame(width: 34, height: 34)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(item.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                Text(item.detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.8) : Color(hex: "CBD9C6").opacity(0.9),
                    lineWidth: 1
                )
        )
    }
}

private struct FlexiblePillRow: View {
    let items: [String]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunkedItems, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Text(item)
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(colorScheme == .dark ? Color(hex: "243828") : Color(hex: "EAF2E7"))
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunkedItems: [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []

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

private struct HomeFeelingChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(isSelected ? VenusTheme.text : VenusTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                            ? (colorScheme == .dark ? Color(hex: "243828") : Color.white.opacity(0.98))
                            : (colorScheme == .dark ? Color(hex: "1A2A1C").opacity(0.9) : Color(hex: "EDF5EA").opacity(0.96))
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                            ? tint.opacity(0.68)
                            : (colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.8) : Color(hex: "BCD2B7").opacity(0.9)),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? tint.opacity(colorScheme == .dark ? 0.28 : 0.2) : Color.black.opacity(colorScheme == .dark ? 0.18 : 0.06),
                    radius: isSelected ? 16 : 8,
                    x: 0,
                    y: isSelected ? 8 : 5
                )
        }
        .buttonStyle(.plain)
    }
}

private struct HomeReflectionCardData: Identifiable {
    let id = UUID()
    let eyebrow: String
    let title: String
    let detail: String
    let tags: [String]
}

private struct HomeReflectionsDeck: View {
    let cards: [HomeReflectionCardData]

    var body: some View {
        ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                HomeReflectionDeckCard(card: card)
                    .rotationEffect(rotation(for: index))
                    .scaleEffect(scale(for: index))
                    .offset(y: yOffset(for: index))
                    .zIndex(Double(cards.count - index))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 312)
        .padding(.vertical, 6)
    }

    private func yOffset(for index: Int) -> CGFloat {
        CGFloat((cards.count - index - 1) * 12)
    }

    private func scale(for index: Int) -> CGFloat {
        1 - CGFloat(cards.count - index - 1) * 0.025
    }

    private func rotation(for index: Int) -> Angle {
        switch index {
        case 0: return .degrees(-2.5)
        case 1: return .degrees(2)
        default: return .degrees(-1)
        }
    }
}

private struct HomeReflectionDeckCard: View {
    let card: HomeReflectionCardData

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(card.eyebrow.uppercased())
                .font(.system(.caption2, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.textSecondary)

            Text(card.title)
                .font(.system(size: 24, weight: .black, design: .serif))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.detail)
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                ForEach(card.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(colorScheme == .dark ? Color(hex: "243828") : Color(hex: "E6F1E2"))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 228)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.995))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C5D8BF").opacity(0.95),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.09), radius: 14, x: 0, y: 10)
        .padding(.horizontal, 10)
    }
}

// Fixed-height metric cards with distinct icon colors per semantic meaning
private struct HomeReflectionMetricRow: View {
    let moodValue: String
    let intensityDetail: String
    let triggerValue: String
    let triggerDetail: String
    let windowValue: String
    let windowDetail: String
    let actionValue: String
    let actionDetail: String

    private let cardHeight: CGFloat = 148

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ReflectionMetricCard(
                    eyebrow: "Estado",
                    value: moodValue,
                    detail: intensityDetail,
                    icon: "face.smiling.inverse",
                    iconColor: VenusTheme.accentBlue,
                    height: cardHeight
                )
                ReflectionMetricCard(
                    eyebrow: "Gatilho",
                    value: triggerValue,
                    detail: triggerDetail,
                    icon: "exclamationmark.triangle.fill",
                    iconColor: VenusTheme.accentPink,
                    height: cardHeight
                )
                ReflectionMetricCard(
                    eyebrow: "Janela",
                    value: windowValue,
                    detail: windowDetail,
                    icon: "clock.badge.checkmark.fill",
                    iconColor: VenusTheme.accentOrange,
                    height: cardHeight
                )
                ReflectionMetricCard(
                    eyebrow: "Próximo passo",
                    value: actionValue,
                    detail: actionDetail,
                    icon: "arrow.right.circle.fill",
                    iconColor: VenusTheme.accentGreen,
                    height: cardHeight
                )
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }
}

private struct ReflectionMetricCard: View {
    let eyebrow: String
    let value: String
    let detail: String
    let icon: String
    let iconColor: Color
    let height: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
            }
            .padding(.bottom, 10)

            Text(eyebrow)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
                .padding(.bottom, 4)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 6)

            Text(detail)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 158, height: height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.985))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.92),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 8, x: 0, y: 4)
    }
}
