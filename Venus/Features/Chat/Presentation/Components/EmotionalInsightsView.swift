//
//  EmotionalInsightsView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct EmotionalInsightsView: View {
    let emotionalState: EmotionalState?
    let onSuggestionTap: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let state = emotionalState {
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(emotionColor(for: state.primaryEmotion))
                        .frame(width: 12, height: 12)

                    Text("Percebo que você está se sentindo \(emotionDescription(for: state.primaryEmotion))")
                        .font(.system(size: 12, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)

                    Spacer()

                    Text("Intensidade: \(state.intensity)/10")
                        .font(.system(size: 11, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                }

                if state.needsSupport {
                    SupportSuggestionCard(
                        emotion: state.primaryEmotion,
                        onTap: onSuggestionTap
                    )
                }
            }
            .padding(16)
            .background(VenusChatVisualStyle.surfaceFill(isDark: colorScheme == .dark))
            .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous)
                    .stroke(VenusChatVisualStyle.surfaceBorder(isDark: colorScheme == .dark), lineWidth: 0.5)
            )
        }
    }

    private func emotionColor(for emotion: EmotionType) -> Color {
        switch emotion {
        case .happy, .excited, .grateful:
            return .green
        case .sad, .lonely:
            return .blue
        case .anxious, .stressed:
            return .orange
        case .angry, .frustrated:
            return .red
        case .neutral:
            return VenusTheme.primary
        }
    }

    private func emotionDescription(for emotion: EmotionType) -> String {
        switch emotion {
        case .happy: return "feliz"
        case .sad: return "triste"
        case .anxious: return "ansioso(a)"
        case .angry: return "irritado(a)"
        case .excited: return "animado(a)"
        case .frustrated: return "frustrado(a)"
        case .lonely: return "sozinho(a)"
        case .stressed: return "estressado(a)"
        case .grateful: return "grato(a)"
        case .neutral: return "neutro"
        }
    }
}
