//
//  EmotionalInsightsView.swift
//  Venus
//
//  Displays emotional insights and contextual support
//

import SwiftUI

struct EmotionalInsightsView: View {
    let emotionalState: EmotionalState?
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        if let state = emotionalState {
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(emotionColor(for: state.primaryEmotion))
                        .frame(width: 12, height: 12)
                    
                    Text("Percebo que você está se sentindo \(emotionDescription(for: state.primaryEmotion))")
                        .font(.caption)
                        .foregroundColor(VenusTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("Intensidade: \(state.intensity)/10")
                        .font(.caption2)
                        .foregroundColor(VenusTheme.textSecondary)
                }
                
                if state.needsSupport {
                    SupportSuggestionCard(
                        emotion: state.primaryEmotion,
                        onTap: onSuggestionTap
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VenusTheme.surface.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(emotionColor(for: state.primaryEmotion).opacity(0.3), lineWidth: 1)
                    )
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