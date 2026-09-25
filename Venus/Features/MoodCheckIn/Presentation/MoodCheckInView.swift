//
//  MoodCheckInView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct MoodCheckInView: View {
    @Bindable var viewModel: MoodCheckInViewModel
    var ritualProgressLabel: String = "Ritual"
    var onCompleted: ((MoodType) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentStep: Int = 1
    @State private var transitionDirection: Int = 1
    @State private var bottomControlsHeight: CGFloat = 0
    @State private var selectedSentimentId: String? = nil
    
    enum CheckInFlowType {
        case unset
        case traditional
        case somatic
    }
    
    @State private var flowType: CheckInFlowType = .unset
    @State private var somaticStep: Int = 1
    @State private var somaticTemperature: String? = nil
    @State private var somaticTension: String? = nil
    
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
        if flowType == .unset { return false }
        if flowType == .somatic && currentStep == 1 {
            switch somaticStep {
            case 1: return somaticTemperature != nil
            case 2: return somaticTension != nil
            case 3: return viewModel.selectedEnergyLevel != nil && viewModel.selectedMood != nil
            default: return true
            }
        }
        
        switch currentStep {
        case 1:
            return viewModel.selectedEnergyLevel != nil && viewModel.selectedMood != nil
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
        if flowType == .unset { return "" }
        if flowType == .somatic && currentStep == 1 {
            switch somaticStep {
            case 1: return "Selecione a temperatura do seu corpo"
            case 2: return "Selecione a tensão do seu corpo"
            case 3: return "Selecione o sentimento que mais se aproxima"
            default: return ""
            }
        }
        
        switch currentStep {
        case 1:
            if viewModel.selectedEnergyLevel == nil {
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
            OnboardingAnimatedBackground(palette: palette, isAnimated: true)
                .animation(.easeInOut(duration: 0.7), value: currentStep)

            VStack(spacing: 0) {
                topHUDView
                    .safeAreaPadding(.top, 16)
                
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
        }
        .padding(.horizontal, 24)
    }

    private var topBackButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if flowType == .unset {
                dismiss()
            } else {
                goToPreviousStep()
            }
        } label: {
            Image(systemName: (flowType == .unset) ? "xmark" : "chevron.left")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(palette.accent)
                .frame(width: 40, height: 40)
                .contentShape(Circle())
                .glassEffect(.clear, in: Circle())
        }
        .buttonStyle(.plain)
        .buttonStyle(OnboardingPressableButtonStyle())
        .accessibilityLabel(flowType == .unset ? "Fechar" : "Voltar")
    }

    @ViewBuilder
    private var currentStepView: some View {
        if flowType == .unset {
            triageView
        } else if flowType == .somatic && currentStep == 1 {
            somaticStepView
        } else {
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
    }

    private var triageView: some View {
        VStack(alignment: .leading, spacing: 32) {
            OnboardingStepHeader(
                eyebrow: "Triagem",
                title: "Como você prefere fazer seu check-in hoje?",
                subtitle: "Você pode escolher diretamente o que sente, ou deixar que a gente ajude através dos sinais do seu corpo.",
                systemImage: "waveform.path.ecg",
                tint: palette.accent
            )
            
            VStack(spacing: 16) {
                triageCard(
                    title: "Sei o que sinto",
                    subtitle: "Selecionar sentimento predominante diretamente.",
                    icon: "heart.fill",
                    color: VenusTheme.accentBlue
                ) {
                    transitionDirection = 1
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        flowType = .traditional
                    }
                }
                
                triageCard(
                    title: "Estou confuso",
                    subtitle: "Sonda somática guiada pelos sinais do corpo.",
                    icon: "sparkles",
                    color: VenusTheme.accentPurple
                ) {
                    transitionDirection = 1
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        flowType = .somatic
                        somaticStep = 1
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func triageCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .glassEffect(.regular, in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                    
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(VenusTheme.textSecondary)
            }
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(VenusTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .buttonStyle(OnboardingPressableButtonStyle())
    }

    @ViewBuilder
    private var somaticStepView: some View {
        switch somaticStep {
        case 1:
            somaticTemperatureView
        case 2:
            somaticTensionView
        case 3:
            somaticSuggestionView
        default:
            EmptyView()
        }
    }

    private var somaticTemperatureView: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingStepHeader(
                eyebrow: "Sonda Somática 1/3",
                title: "Temperatura",
                subtitle: "Concentre-se no seu corpo. Como está a sua temperatura agora?",
                systemImage: "thermometer",
                tint: palette.accent
            )
            
            VStack(spacing: 12) {
                somaticChoice(title: "Frio / Arrepios", isSelected: somaticTemperature == "Frio") {
                    somaticTemperature = "Frio"
                    autoAdvanceSomatic()
                }
                somaticChoice(title: "Neutro / Normal", isSelected: somaticTemperature == "Neutro") {
                    somaticTemperature = "Neutro"
                    autoAdvanceSomatic()
                }
                somaticChoice(title: "Quente / Suor", isSelected: somaticTemperature == "Quente") {
                    somaticTemperature = "Quente"
                    autoAdvanceSomatic()
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var somaticTensionView: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingStepHeader(
                eyebrow: "Sonda Somática 2/3",
                title: "Tensão Muscular",
                subtitle: "Como você sente seus músculos e a sua respiração?",
                systemImage: "figure.mind.and.body",
                tint: palette.accent
            )
            
            VStack(spacing: 12) {
                somaticChoice(title: "Pesado / Sem energia", isSelected: somaticTension == "Pesado") {
                    somaticTension = "Pesado"
                    autoAdvanceSomatic()
                }
                somaticChoice(title: "Relaxado / Leve", isSelected: somaticTension == "Relaxado") {
                    somaticTension = "Relaxado"
                    autoAdvanceSomatic()
                }
                somaticChoice(title: "Tenso / Agitado", isSelected: somaticTension == "Tenso") {
                    somaticTension = "Tenso"
                    autoAdvanceSomatic()
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var somaticSuggestionView: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingStepHeader(
                eyebrow: "Sonda Somática 3/3",
                title: "Reflexo do Espelho",
                subtitle: "Baseado no seu corpo, aqui estão alguns sentimentos que se conectam ao seu estado atual. Escolha o que mais faz sentido.",
                systemImage: "sparkles.rectangle.stack",
                tint: palette.accent
            )
            
            VenusWrappedLayout(spacing: 8, lineSpacing: 12) {
                ForEach(suggestedMoodsForSomatic()) { option in
                    VenusInterestChipSimple(
                        title: option.displayName,
                        isSelected: selectedSentimentId == option.id,
                        tint: palette.accent,
                        onTap: {
                            selectedSentimentId = option.id
                            viewModel.selectMood(option.moodType)
                            viewModel.selectEnergyLevel(energyFor(mood: option.moodType))
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func somaticChoice(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(isSelected ? .white : VenusTheme.text)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(
                                colors: [palette.accent, palette.accent.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.clear)
                    }
                }
            )
            .glassEffect(isSelected ? .clear : .regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? palette.accent : VenusTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .buttonStyle(OnboardingPressableButtonStyle())
    }

    private func autoAdvanceSomatic() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            transitionDirection = 1
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                if somaticStep < 3 {
                    somaticStep += 1
                }
            }
        }
    }

    private func suggestedMoodsForSomatic() -> [SentimentOption] {
        let isLowEnergy = somaticTension == "Pesado"
        let isHighEnergy = somaticTension == "Tenso"
        let isWarm = somaticTemperature == "Quente"
        
        var suggestions: [SentimentOption] = []
        
        if isLowEnergy {
            suggestions = sentimentOptions.filter { $0.moodType == .tired || $0.moodType == .sad || $0.id == "calm" }
        } else if isHighEnergy {
            suggestions = sentimentOptions.filter { $0.moodType == .stressed || $0.moodType == .energetic || $0.id == "anxious" }
        } else {
            if isWarm {
                suggestions = sentimentOptions.filter { $0.moodType == .happy || $0.moodType == .calm || $0.id == "excited" }
            } else {
                suggestions = sentimentOptions.filter { $0.moodType == .calm || $0.moodType == .sad || $0.id == "neutral" }
            }
        }
        
        if !suggestions.contains(where: { $0.id == "neutral" }) {
            if let n = sentimentOptions.first(where: { $0.id == "neutral" }) { suggestions.append(n) }
        }
        
        return Array(suggestions.prefix(6))
    }

    private func energyFor(mood: MoodType) -> MoodEnergyLevel {
        switch mood {
        case .tired, .sad, .stressed: return .low
        case .calm, .happy: return .medium
        case .energetic: return .high
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
                    selectedEnergy: viewModel.selectedEnergyLevel,
                    tint: palette.accent,
                    onSelect: { viewModel.selectEnergyLevel($0) }
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

                // Check-in rápido de 10s: só energia + humor
                if viewModel.isQuickSaveReady {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        viewModel.saveQuickCheckIn()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(viewModel.isSaving ? "Salvando…" : "Salvar rápido (10s)")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                        }
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(palette.accent.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSaving)
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
                if !canProceed {
                    Text(validationMessage)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if flowType != .unset {
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
        if flowType == .unset { return }
        
        if flowType == .somatic && currentStep == 1 {
            if somaticStep > 1 {
                transitionDirection = -1
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                    somaticStep -= 1
                }
                return
            } else {
                transitionDirection = -1
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                    flowType = .unset
                }
                return
            }
        }
        
        if flowType == .traditional && currentStep == 1 {
            transitionDirection = -1
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                flowType = .unset
            }
            return
        }
        
        guard currentStep > 1 else { return }
        transitionDirection = -1
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            currentStep -= 1
        }
    }

    private func goToNextStep() {
        guard canProceed else { return }
        
        if flowType == .somatic && currentStep == 1 {
            if somaticStep < 3 {
                transitionDirection = 1
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                    somaticStep += 1
                }
                return
            }
        }
        
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
