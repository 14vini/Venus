//
//  MoodCheckInView.swift
//  Venus
//
//  Redesign completo do fluxo de check-in da Venus com o mascote oficial (VenusMoodOrb),
//  slider tátil de arrastar com os dedos, grade adaptativa e suporte completo a Modo Escuro.
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
    @State private var selectedLevel: VenusCheckInMoodLevel = .neutral
    @State private var mascotGazeOffset: CGSize = .zero

    private let totalSteps = 4

    private var topBarIconColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "1F355A")
    }

    private var topBarButtonBackground: Color {
        colorScheme == .dark ? Color(hex: "1A283C").opacity(0.88) : Color.white.opacity(0.80)
    }

    private var quickSaveTextColor: Color {
        colorScheme == .dark ? Color(hex: "93C5FD") : Color(hex: "345DAE")
    }

    private var stepOneTitleColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "101E36")
    }

    var body: some View {
        ZStack {
            // Fundo azul-celeste pastel / noite estrelada adaptável
            VenusCheckInSkyBackground()

            VStack(spacing: 0) {
                // Topo: Botão Voltar / Fechar
                topBarView
                    .padding(.top, 10)

                // Conteúdo da Etapa Atual
                GeometryReader { _ in
                    ZStack {
                        switch currentStep {
                        case 1:
                            stepOneEnergyView
                                .transition(stepTransition)
                        case 2:
                            stepTwoContextView
                                .transition(stepTransition)
                        case 3:
                            stepThreeEmpathyView
                                .transition(stepTransition)
                        case 4:
                            stepFourProjectionView
                                .transition(stepTransition)
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Barra Inferior (para os passos 1 a 3; o passo 4 tem seu próprio CTA)
                if currentStep < totalSteps {
                    VenusCheckInBottomControls(
                        currentStep: currentStep,
                        totalSteps: totalSteps,
                        isNextEnabled: true,
                        isLoading: viewModel.isSaving,
                        onNext: {
                            advanceToNextStep()
                        }
                    )
                    .safeAreaPadding(.bottom, 10)
                }
            }
        }
        .onAppear {
            syncInitialState()
        }
        .onChange(of: viewModel.savedSuccess) { _, success in
            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if let mood = viewModel.selectedMood {
                    onCompleted?(mood)
                }
                dismiss()
            }
        }
    }

    // MARK: - Barra Superior

    private var topBarView: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if currentStep > 1 {
                    goToPreviousStep()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: currentStep == 1 ? "xmark" : "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(topBarIconColor)
                    .frame(width: 40, height: 40)
                    .background(topBarButtonBackground, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.35) : Color(hex: "4A6EB0").opacity(0.12),
                        radius: 8,
                        y: 3
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            if currentStep == 1 {
                // Check-in rápido direto
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    applyCurrentLevelToViewModel()
                    viewModel.saveQuickCheckIn()
                } label: {
                    Text("Salvar rápido")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(quickSaveTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(topBarButtonBackground, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
    }

    // MARK: - Etapa 1: Nível de Produtividade / Energia

    private var stepOneEnergyView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 4)

            // Pergunta Principal em Serif editorial
            Text("Qual é o seu nível de produtividade hoje?")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundColor(stepOneTitleColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)

            Spacer(minLength: 8)

            // Mascote Oficial da Venus no Centro (Interativo com Arraste na tela)
            VenusPastelMascotView(
                level: selectedLevel,
                size: 210,
                isAnimated: true,
                gazeOffset: mascotGazeOffset
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        mascotGazeOffset = CGSize(
                            width: min(max(value.translation.width * 0.12, -18), 18),
                            height: min(max(value.translation.height * 0.12, -12), 12)
                        )
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            mascotGazeOffset = .zero
                        }
                        let threshold: CGFloat = 35
                        if value.translation.width < -threshold {
                            advanceLevel()
                        } else if value.translation.width > threshold {
                            retreatLevel()
                        }
                    }
            )

            Spacer(minLength: 8)

            // Seletor com Carrossel de Texto + Slider de Arrastar com os Dedos
            VenusCheckInCarouselPicker(
                selectedLevel: $selectedLevel,
                onLevelChanged: { _ in
                    applyCurrentLevelToViewModel()
                }
            )
            .padding(.horizontal, 8)

            Spacer(minLength: 8)
        }
    }

    // MARK: - Etapa 2: Contexto e Gatilhos

    private var stepTwoContextView: some View {
        VenusCheckInContextStepView(
            viewModel: viewModel,
            level: selectedLevel
        )
    }

    // MARK: - Etapa 3: Acolhimento e Validação Emocional

    private var stepThreeEmpathyView: some View {
        VenusCheckInEmpathyStepView(
            level: selectedLevel,
            onContinue: {
                advanceToNextStep()
            }
        )
    }

    // MARK: - Etapa 4: Previsão & Plano

    private var stepFourProjectionView: some View {
        VenusCheckInProjectionChartView(
            level: selectedLevel,
            onExplorePlan: {
                applyCurrentLevelToViewModel()
                viewModel.saveCheckIn()
            }
        )
    }

    // MARK: - Transições e Navegação

    private var stepTransition: AnyTransition {
        let insertion: AnyTransition = transitionDirection >= 0
            ? .move(edge: .trailing).combined(with: .opacity)
            : .move(edge: .leading).combined(with: .opacity)

        let removal: AnyTransition = transitionDirection >= 0
            ? .move(edge: .leading).combined(with: .opacity)
            : .move(edge: .trailing).combined(with: .opacity)

        return .asymmetric(insertion: insertion, removal: removal)
    }

    private func advanceToNextStep() {
        applyCurrentLevelToViewModel()

        if currentStep < totalSteps {
            transitionDirection = 1
            withAnimation(.spring(response: 0.50, dampingFraction: 0.86)) {
                currentStep += 1
            }
        }
    }

    private func goToPreviousStep() {
        guard currentStep > 1 else { return }
        transitionDirection = -1
        withAnimation(.spring(response: 0.50, dampingFraction: 0.86)) {
            currentStep -= 1
        }
    }

    private func advanceLevel() {
        if selectedLevel.rawValue < VenusCheckInMoodLevel.allCases.count - 1,
           let next = VenusCheckInMoodLevel(rawValue: selectedLevel.rawValue + 1) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedLevel = next
                UISelectionFeedbackGenerator().selectionChanged()
                applyCurrentLevelToViewModel()
            }
        }
    }

    private func retreatLevel() {
        if selectedLevel.rawValue > 0,
           let prev = VenusCheckInMoodLevel(rawValue: selectedLevel.rawValue - 1) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedLevel = prev
                UISelectionFeedbackGenerator().selectionChanged()
                applyCurrentLevelToViewModel()
            }
        }
    }

    private func syncInitialState() {
        if let mood = viewModel.selectedMood {
            switch mood {
            case .sad: selectedLevel = .veryLow
            case .tired: selectedLevel = .low
            case .calm: selectedLevel = .neutral
            case .happy: selectedLevel = .good
            case .energetic: selectedLevel = .optimal
            case .stressed: selectedLevel = .low
            }
        } else if let energy = viewModel.selectedEnergyLevel {
            switch energy {
            case .low: selectedLevel = .low
            case .medium: selectedLevel = .neutral
            case .high: selectedLevel = .good
            }
        } else {
            selectedLevel = .neutral
        }
        applyCurrentLevelToViewModel()
    }

    private func applyCurrentLevelToViewModel() {
        viewModel.selectMood(selectedLevel.mappedMoodType)
        viewModel.selectEnergyLevel(selectedLevel.mappedEnergyLevel)
    }
}
