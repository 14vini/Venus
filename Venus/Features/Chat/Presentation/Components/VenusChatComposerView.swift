//
//  VenusChatComposerView.swift
//  Venus
//
//  Composer fixo no rodapé: campo multilinha que cresce com o texto, microfone
//  à esquerda e CTA escuro à direita. Durante a resposta, o CTA vira "parar".
//  Fica fora da sobreposição do ScrollView (safeAreaInset) para nunca esconder
//  a última mensagem.
//

import SwiftUI

struct VenusChatComposerView: View {
    @Binding var text: String
    /// Binding de foco vindo da tela (o teclado é dispensado também pelo scroll).
    var isFocused: FocusState<Bool>.Binding

    let isStreaming: Bool
    let isRecording: Bool
    let waveAnimation: Bool
    let replyingTo: ChatMessage?

    let onSend: (String) -> Void
    let onStop: () -> Void
    let onToggleRecording: () -> Void
    let onCancelReply: () -> Void
    let onDismissKeyboard: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 8) {
            if isRecording {
                recordingIndicator
            }

            if let replyingTo {
                replyPreview(replyingTo)
            }

            HStack(alignment: .bottom, spacing: 6) {
                microphoneButton

                TextField("", text: $text, axis: .vertical)
                    .lineLimit(1...6)
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .focused(isFocused)
                    .padding(.vertical, 9)
                    .frame(minHeight: 44)
                    // Placeholder próprio: o cinza do sistema some sobre a
                    // cápsula clara, então a cor é controlada explicitamente.
                    .overlay(alignment: .leading) {
                        if text.isEmpty {
                            Text(VenusChatVisualStyle.composerPlaceholder)
                                .font(.system(size: 15, weight: .light, design: .rounded))
                                .foregroundStyle(VenusChatVisualStyle.placeholderColor(isDark: isDark))
                                .padding(.vertical, 9)
                                .allowsHitTesting(false)
                                .transition(.opacity)
                        }
                    }

                if isFocused.wrappedValue {
                    Button(action: onDismissKeyboard) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(VenusTheme.textSecondary)
                            .frame(width: 30, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(VenusChatSpringPressStyle())
                    .transition(.scale.combined(with: .opacity))
                }

                sendButton
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: VenusChatVisualStyle.composerRadius, style: .continuous)
                    .fill(VenusChatVisualStyle.composerFill(isDark: isDark))
            )
            .overlay(
                RoundedRectangle(cornerRadius: VenusChatVisualStyle.composerRadius, style: .continuous)
                    .stroke(VenusChatVisualStyle.composerBorder(isDark: isDark), lineWidth: 0.6)
            )
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: isRecording)
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: replyingTo?.id)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isFocused.wrappedValue)
        .padding(.horizontal, VenusChatVisualStyle.chromeHorizontalInset)
        .padding(.bottom, 8)
        .frame(maxWidth: VenusChatVisualStyle.chromeMaxWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ações

    private var microphoneButton: some View {
        Button(action: onToggleRecording) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                .font(.system(size: 19, weight: .light))
                .foregroundStyle(isRecording ? .red : VenusTheme.textSecondary)
                .frame(width: 36, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(VenusChatSpringPressStyle())
        .accessibilityLabel(isRecording ? "Parar gravação" : "Gravar voz")
    }

    private var sendButton: some View {
        Button {
            if isStreaming {
                // O haptic de parar é disparado pelo próprio ViewModel.
                onStop()
            } else {
                guard hasText else { return }
                let message = text
                text = ""
                VenusChatHaptics.light()
                onSend(message)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(VenusChatVisualStyle.darkPill(isDark: isDark))
                    .frame(width: 40, height: 40)

                Image(systemName: isStreaming ? "stop.fill" : "arrow.up")
                    .font(.system(size: isStreaming ? 12 : 15, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.6)
            )
        }
        .buttonStyle(VenusChatSpringPressStyle())
        .disabled(!isStreaming && !hasText)
        .opacity((isStreaming || hasText) ? 1 : 0.42)
        .accessibilityLabel(isStreaming ? "Parar resposta" : "Enviar mensagem")
    }

    // MARK: - Contexto

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .foregroundStyle(.red)
                .scaleEffect(waveAnimation ? 1.18 : 0.84)
                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: waveAnimation)

            Text("Gravando... toque no microfone para parar")
                .font(.system(size: 12, weight: .light, design: .rounded))
                .foregroundStyle(.red)
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(VenusChatVisualStyle.suggestionFill(isDark: isDark))
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func replyPreview(_ message: ChatMessage) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(VenusChatVisualStyle.lilac)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.isFromUser ? "Você" : "Venus")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(VenusTheme.primary)

                Text(VenusChatVisualStyle.displayText(message.content))
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }

            Spacer(minLength: 4)

            Button {
                VenusChatHaptics.light()
                onCancelReply()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(VenusChatSpringPressStyle())
            .accessibilityLabel("Cancelar resposta")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: VenusChatVisualStyle.controlRadius, style: .continuous)
                .fill(VenusChatVisualStyle.suggestionFill(isDark: isDark))
        )
        .padding(.horizontal, 2)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ComposerPreview()
}

private struct ComposerPreview: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            VenusChatBackground()
            VStack {
                Spacer()
                VenusChatComposerView(
                    text: $text,
                    isFocused: $isFocused,
                    isStreaming: false,
                    isRecording: false,
                    waveAnimation: false,
                    replyingTo: nil,
                    onSend: { _ in },
                    onStop: {},
                    onToggleRecording: {},
                    onCancelReply: {},
                    onDismissKeyboard: { isFocused = false }
                )
            }
        }
    }
}
