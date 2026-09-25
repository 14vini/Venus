//
//  VoiceAndTextInputStep.swift
//  Venus
//
//  Created by Kaua on 23/09/26.
//

import SwiftUI
import Speech
import AVFoundation

struct VoiceAndTextInputStep: View {
    @Binding var userProfile: UserProfile
    
    @State private var textInput: String = ""
    @State private var isRecording: Bool = false
    @State private var recordingPulse: Bool = false
    @FocusState private var isTextFocused: Bool
    
    private let speechService: SpeechRecognitionServiceProtocol = DependencyContainer.shared.makeSpeechRecognitionService()
    
    private let quickSuggestions = [
        "⚡ Semana de entregas pesadas",
        "🌙 Sono ruim nos últimos dias",
        "🎯 Focado(a) em um grande projeto",
        "🌿 Buscando mais equilíbrio e clareza"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "calibração pessoal",
                title: "Quer me contar algo sobre seu momento?",
                subtitle: "Fale pelo microfone ou digite o que está no seu radar hoje.",
                systemImage: "waveform.and.mic",
                tint: VenusTheme.accentBlue,
                accessory: !textInput.isEmpty ? "preenchido" : "opcional"
            )
            
            // Glassmorphic Input Area
            VenusCard(cornerRadius: 24, padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack(alignment: .topLeading) {
                        if textInput.isEmpty && !isRecording {
                            Text("Ex: Tive uma semana corrida com prazos apertados e sinto minha cabeça cheia...")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(VenusTheme.textSecondary.opacity(0.7))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $textInput)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.text)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 110, maxHeight: 150)
                            .focused($isTextFocused)
                            .onChange(of: textInput) { _, newValue in
                                userProfile.contextNote = newValue
                            }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.12))
                    
                    // Bottom Action Row: Mic Recording Button & Audio Waves
                    HStack(spacing: 12) {
                        // Microphone Button
                        Button {
                            toggleVoiceRecording()
                        } label: {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(isRecording ? VenusTheme.accentOrange : VenusTheme.accentBlue)
                                        .frame(width: 38, height: 38)
                                        .scaleEffect(recordingPulse ? 1.2 : 1.0)
                                        .animation(
                                            isRecording ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                                            value: recordingPulse
                                        )
                                    
                                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text(isRecording ? "Ouvindo... Toque para parar" : "Falar por voz")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundColor(isRecording ? VenusTheme.accentOrange : VenusTheme.accentBlue)
                            }
                            .padding(.vertical, 4)
                            .padding(.trailing, 10)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        if !textInput.isEmpty {
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                textInput = ""
                                userProfile.contextNote = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(VenusTheme.textSecondary.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Quick Suggestion Chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Ou escolha um padrão rápido:")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
                    .padding(.horizontal, 4)
                
                FlowLayout(spacing: 8) {
                    ForEach(quickSuggestions, id: \.self) { chip in
                        suggestionChip(chip)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .onAppear {
            textInput = userProfile.contextNote
            speechService.requestPermissions()
        }
        .onDisappear {
            if isRecording {
                speechService.stopRecording()
                isRecording = false
            }
        }
    }
    
    private func toggleVoiceRecording() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if isRecording {
            speechService.stopRecording()
            isRecording = false
            recordingPulse = false
        } else {
            isTextFocused = false
            do {
                try speechService.startRecording(
                    onTextRecognized: { recognizedText in
                        DispatchQueue.main.async {
                            self.textInput = recognizedText
                            self.userProfile.contextNote = recognizedText
                        }
                    },
                    onError: { _ in
                        DispatchQueue.main.async {
                            self.isRecording = false
                            self.recordingPulse = false
                        }
                    }
                )
                isRecording = true
                recordingPulse = true
            } catch {
                isRecording = false
                recordingPulse = false
            }
        }
    }
    
    private func suggestionChip(_ text: String) -> some View {
        let isSelected = textInput == text
        
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                textInput = text
                userProfile.contextNote = text
            }
        } label: {
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(isSelected ? .white : VenusTheme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? VenusTheme.accentBlue : Color.clear,
                    in: Capsule()
                )
                .glassEffect(isSelected ? .clear : .regular.interactive(), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout Helper
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + lineHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

#Preview {
    VoiceAndTextInputStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
