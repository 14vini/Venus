//
//  MoodCheckInView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct MoodCheckInView: View {
    @ObservedObject var viewModel: MoodCheckInViewModel
    var ritualProgressLabel: String = "Ritual"
    var onCompleted: ((MoodType) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentStep: Int = 1
    @State private var transitionDirection: Int = 1
    @State private var bottomControlsHeight: CGFloat = 0
    @State private var selectedSentimentId: String? = nil
    
    private let totalSteps = 5

    struct SentimentOption: Identifiable, Equatable {
        let id: String
        let displayName: String
        let moodType: MoodType
    }

    private let sentimentOptions = [
        SentimentOption(id: "calm", displayName: "Calmo", moodType: .calm),
        SentimentOption(id: "neutral", displayName: "Neutro", moodType: .calm),
        SentimentOption(id: "happy", displayName: "Feliz", moodType: .happy),
        SentimentOption(id: "excited", displayName: "Animado", moodType: .happy),
        SentimentOption(id: "energetic", displayName: "Energizado", moodType: .energetic),
        SentimentOption(id: "stressed", displayName: "Estressado", moodType: .stressed),
        SentimentOption(id: "anxious", displayName: "Ansioso", moodType: .stressed),
        SentimentOption(id: "overwhelmed", displayName: "Sobrecarregado", moodType: .stressed),
        SentimentOption(id: "sad", displayName: "Triste", moodType: .sad),
        SentimentOption(id: "sensitive", displayName: "Sensível", moodType: .sad),
        SentimentOption(id: "tired", displayName: "Cansado", moodType: .tired),
        SentimentOption(id: "no_energy", displayName: "Sem pique", moodType: .tired)
    ]

    private var palette: OnboardingVisualPalette {
        switch currentStep {
        case 1:
            return OnboardingVisualPalette(
                accent: VenusTheme.primary,
                secondary: VenusTheme.accentBlue,
                tertiary: VenusTheme.accentPurple,
                moods: [.happy, .calm, .tired]
            )
        case 2:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentBlue,
                secondary: VenusTheme.accentPurple,
                tertiary: VenusTheme.primary,
                moods: [.calm, .tired, .happy]
            )
        case 3:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentGreen,
                secondary: VenusTheme.primary,
                tertiary: VenusTheme.accentBlue,
                moods: [.happy, .calm, .energetic]
            )
        case 4:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentPurple,
                secondary: VenusTheme.accentBlue,
                tertiary: VenusTheme.primary,
                moods: [.tired, .calm, .happy]
            )
        default:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentOrange,
                secondary: VenusTheme.accentPink,
                tertiary: VenusTheme.primary,
                moods: [.stressed, .calm, .happy]
            )
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return viewModel.selectedZenithEnergy != nil && viewModel.selectedMood != nil
        case 2:
            return !viewModel.selectedTags.isEmpty && viewModel.selectedAffectedArea != nil
        case 3:
            return viewModel.selectedAvailableTime != nil && viewModel.selectedControlLevel != nil
        case 4:
            return viewModel.selectedSleepQuality != nil
        case 5:
            return !viewModel.selectedBodySignals.isEmpty && !viewModel.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    private var validationMessage: String {
        switch currentStep {
        case 1:
            if viewModel.selectedZenithEnergy == nil {
                return "Selecione a bateria mental de hoje"
            }
            return "Selecione o sentimento predominante"
        case 2:
            if viewModel.selectedTags.isEmpty {
                return "Selecione pelo menos um gatilho"
            }
            return "Selecione a área mais afetada"
        case 3:
            if viewModel.selectedAvailableTime == nil {
                return "Selecione o tempo disponível agora"
            }
            return "Marque se a situação está sob controle"
        case 4:
            return "Selecione a qualidade do seu sono"
        case 5:
            if viewModel.selectedBodySignals.isEmpty {
                return "Selecione os sinais do seu corpo"
            }
            return "Escreva uma nota curta sobre o seu momento"
        default:
            return ""
        }
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
            // Underlay Onboarding Background (Waves and Gradients only, mascot orbs removed for performance)
            OnboardingAnimatedBackground(palette: palette, isAnimated: true)
                .animation(.easeInOut(duration: 0.7), value: currentStep)

            VStack(spacing: 0) {
                // Top HUD (no glass background, matching onboarding style)
                topHUDView
                    .safeAreaPadding(.top, 16)
                
                // Content Scroll view
                GeometryReader { geometry in
                    ScrollViewReader { scrollProxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: 1)
                                    .id("top")

                                currentStepView
                                    .id(currentStep)
                                    .transition(stepTransition)
                                    .safeAreaPadding(.top, 24)
                                    .safeAreaPadding(.bottom, max(132, bottomControlsHeight + 24))
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
            .overlay(alignment: .bottom) {
                bottomControlsView
                    .safeAreaPadding(.bottom, 12)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            if let mood = viewModel.selectedMood, selectedSentimentId == nil {
                selectedSentimentId = sentimentOptions.first(where: { $0.moodType == mood })?.id
            }
        }
        .onChange(of: viewModel.savedSuccess) { _, success in
            if success, let mood = viewModel.selectedMood {
                onCompleted?(mood)
                dismiss()
            }
        }
    }

    private var topHUDView: some View {
        HStack(spacing: 12) {
            topBackButton
            
            VenusProgressBar(currentStep: currentStep, totalSteps: totalSteps, tint: palette.accent)
                .allowsHitTesting(false)
            
            Text(ritualProgressLabel)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: Capsule())
        }
        .padding(.horizontal, 24)
    }

    private var topBackButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if currentStep > 1 {
                goToPreviousStep()
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: currentStep > 1 ? "chevron.left" : "xmark")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(palette.accent)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
                .glassEffect(.clear, in: Circle())
        }
        .buttonStyle(.plain)
        .buttonStyle(OnboardingPressableButtonStyle())
        .accessibilityLabel(currentStep > 1 ? "Voltar" : "Fechar")
    }

    private func progressColor(for index: Int) -> Color {
        if index < currentStep { return palette.accent.opacity(0.34) }
        if index == currentStep { return palette.accent }
        return colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.12)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 1:
            stepOneView
        case 2:
            stepTwoView
        case 3:
            stepThreeView
        case 4:
            stepFourView
        case 5:
            stepFiveView
        default:
            EmptyView()
        }
    }

    private var stepOneView: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingStepHeader(
                eyebrow: "Etapa 1 de 5",
                title: "Como está sua energia?",
                subtitle: "Selecione sua bateria mental e o sentimento predominante de hoje.",
                systemImage: "bolt.fill",
                tint: palette.accent
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Bateria mental de hoje")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                
                EnergySelectionGrid(
                    selectedEnergy: viewModel.selectedZenithEnergy,
                    tint: palette.accent,
                    onSelect: { viewModel.selectZenithEnergy($0) }
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Sentimento predominante")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                
                VenusWrappedLayout(spacing: 8, lineSpacing: 12) {
                    ForEach(sentimentOptions) { option in
                        VenusInterestChipSimple(
                            title: option.displayName,
                            isSelected: selectedSentimentId == option.id,
                            tint: palette.accent,
                            onTap: {
                                selectedSentimentId = option.id
                                viewModel.selectMood(option.moodType)
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var stepTwoView: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingStepHeader(
                eyebrow: "Etapa 2 de 5",
                title: "O que motivou isso?",
                subtitle: "Marque os gatilhos e a área da sua vida que está sendo mais impactada.",
                systemImage: "bolt.heart.fill",
                tint: palette.accent
            )
            
            fieldSection("Gatilhos") {
                FlowChips(options: viewModel.quickTags, selectedOptions: viewModel.selectedTags, onToggle: viewModel.toggleTag, tint: palette.accent)
            }
            
            fieldSection("Área mais afetada") {
                FlowSingleChoice(options: viewModel.affectedAreas.map(\.rawValue), selectedOption: viewModel.selectedAffectedArea?.rawValue, tint: palette.accent) { rawValue in
                    if let area = viewModel.affectedAreas.first(where: { $0.rawValue == rawValue }) {
                        viewModel.selectAffectedArea(area)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var stepThreeView: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingStepHeader(
                eyebrow: "Etapa 3 de 5",
                title: "Sua situação atual",
                subtitle: "Defina sua disponibilidade e percepção de controle no momento.",
                systemImage: "clock.fill",
                tint: palette.accent
            )
            
            fieldSection("Tempo disponível agora") {
                FlowSingleChoice(options: viewModel.availableTimes.map(\.rawValue), selectedOption: viewModel.selectedAvailableTime?.rawValue, tint: palette.accent) { rawValue in
                    if let item = viewModel.availableTimes.first(where: { $0.rawValue == rawValue }) {
                        viewModel.selectAvailableTime(item)
                    }
                }
            }
            
            fieldSection("Isso está sob seu controle?") {
                FlowSingleChoice(options: viewModel.controlLevels.map(\.rawValue), selectedOption: viewModel.selectedControlLevel?.rawValue, tint: palette.accent) { rawValue in
                    if let item = viewModel.controlLevels.first(where: { $0.rawValue == rawValue }) {
                        viewModel.selectControlLevel(item)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var stepFourView: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingStepHeader(
                eyebrow: "Etapa 4 de 5",
                title: "Mente & Sono",
                subtitle: "Como está sua clareza de pensamento e como foi seu sono recente?",
                systemImage: "brain.headprofile.fill",
                tint: palette.accent
            )
            
            fieldSection("Clareza mental") {
                SimpleSliderCard(
                    value: $viewModel.selectedMentalClarity,
                    lowLabel: "Confuso",
                    highLabel: "Claro",
                    tint: palette.accent
                )
            }
            
            fieldSection("Qualidade do sono") {
                FlowSingleChoice(options: viewModel.sleepQualities.map(\.rawValue), selectedOption: viewModel.selectedSleepQuality?.rawValue, tint: palette.accent) { rawValue in
                    if let item = viewModel.sleepQualities.first(where: { $0.rawValue == rawValue }) {
                        viewModel.selectSleepQuality(item)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var stepFiveView: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingStepHeader(
                eyebrow: "Etapa 5 de 5",
                title: "Sinais & Nota",
                subtitle: "Marque sensações físicas e adicione uma breve anotação do seu dia.",
                systemImage: "pencil.and.outline",
                tint: palette.accent
            )
            
            fieldSection("Sinais no corpo") {
                FlowChips(options: viewModel.bodySignalOptions, selectedOptions: viewModel.selectedBodySignals, onToggle: viewModel.toggleBodySignal, tint: palette.accent)
            }
            
            fieldSection("Nota curta") {
                TextField("Ex: reunião puxada ou momento leve", text: $viewModel.note, axis: .vertical)
                    .lineLimit(3...5)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .padding(16)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(VenusTheme.cardBorder, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 24)
    }

    private var bottomControlsView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Validation Message
                if !canProceed {
                    Text(validationMessage)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Next / Conclude Button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    goToNextStep()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(currentStep == totalSteps ? "Concluir" : "Próximo")
                                .font(.system(.headline, design: .rounded).weight(.black))
                            Image(systemName: currentStep == totalSteps ? "checkmark.circle.fill" : "chevron.right")
                                .font(.system(size: 14, weight: .black))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
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
                        color: canProceed ? palette.accent.opacity(colorScheme == .dark ? 0.22 : 0.26) : .clear,
                        radius: 18,
                        x: 0,
                        y: 12
                    )
                }
                .buttonStyle(.plain)
                .buttonStyle(OnboardingPressableButtonStyle())
                .disabled(!canProceed || viewModel.isSaving)
                .opacity(canProceed ? 1 : 0.72)
                .overlay(alignment: .top) {
                    VenusGlassCrown(tint: palette.accent)
                        .padding(.horizontal, 10)
                        .padding(.top, 3)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.78 : 0.92)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.16 : 0.24),
                                    Color.clear,
                                    Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.34 : 0.10), radius: 22, x: 0, y: 10)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        )
        .readHeight { height in
            bottomControlsHeight = height
        }
    }

    private func goToPreviousStep() {
        guard currentStep > 1 else { return }
        transitionDirection = -1
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            currentStep -= 1
        }
    }

    private func goToNextStep() {
        guard canProceed else { return }
        if currentStep < totalSteps {
            transitionDirection = 1
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                currentStep += 1
            }
        } else {
            viewModel.saveCheckIn()
        }
    }

    private func fieldSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
            content()
        }
    }
}

private struct FlowChips: View {
    let options: [String]
    let selectedOptions: Set<String>
    let onToggle: (String) -> Void
    var tint: Color = VenusTheme.primary

    var body: some View {
        VenusWrappedLayout(spacing: 8, lineSpacing: 12) {
            ForEach(options, id: \.self) { option in
                VenusInterestChipSimple(
                    title: option,
                    isSelected: selectedOptions.contains(option),
                    tint: tint,
                    onTap: { onToggle(option) }
                )
            }
        }
    }
}

private struct FlowSingleChoice: View {
    let options: [String]
    let selectedOption: String?
    var tint: Color = VenusTheme.primary
    let onSelect: (String) -> Void

    var body: some View {
        VenusWrappedLayout(spacing: 8, lineSpacing: 12) {
            ForEach(options, id: \.self) { option in
                VenusInterestChipSimple(
                    title: option,
                    isSelected: selectedOption == option,
                    tint: tint,
                    onTap: { onSelect(option) }
                )
            }
        }
    }
}

private struct SimpleSliderCard: View {
    @Binding var value: Double
    let lowLabel: String
    let highLabel: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(Int(value))/10")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(tint)
                Spacer()
            }

            Slider(value: $value, in: 1...10, step: 1)
                .tint(tint)

            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(VenusTheme.cardBorder, lineWidth: 1)
        )
    }
}

private struct VenusGlassCrown: View {
    var tint: Color = VenusTheme.primary

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.22 : 0.34),
                        tint.opacity(colorScheme == .dark ? 0.12 : 0.18),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 16)
            .blur(radius: 0.2)
            .mask(
                Capsule(style: .continuous)
                    .padding(.horizontal, 6)
            )
            .opacity(0.9)
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
