//
//  SupportSuggestionCard.swift
//  Venus
//
//  Provides contextual wellness suggestions
//

import SwiftUI

struct SupportSuggestionCard: View {
    let emotion: EmotionType
    let onTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestionIcon)
                    .foregroundColor(VenusTheme.primary)
                    .font(.system(size: 14, weight: .semibold))
                
                Text("Sugestão de bem-estar")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(VenusTheme.text)
                
                Spacer()
            }
            
            Text(suggestionText)
                .font(.caption)
                .foregroundColor(VenusTheme.textSecondary)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                Button(action: { onTap(suggestionAction) }) {
                    HStack {
                        Text("Conversar")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(VenusTheme.primary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(VenusTheme.primary.opacity(0.05))
        )
    }
    
    private var suggestionIcon: String {
        switch emotion {
        case .anxious, .stressed:
            return "wind"
        case .sad, .lonely:
            return "heart"
        case .angry, .frustrated:
            return "flame"
        default:
            return "sparkles"
        }
    }
    
    private var suggestionText: String {
        switch emotion {
        case .anxious:
            return "A respiração 4-7-8 pode ajudar a acalmar a ansiedade rapidamente."
        case .sad:
            return "Escrever sobre seus sentimentos pode trazer alívio e clareza."
        case .stressed:
            return "Uma pausa de 5 minutos com respiração consciente pode reduzir o estresse."
        case .lonely:
            return "Conectar-se com alguém querido ou dar uma caminhada pode ajudar."
        case .angry:
            return "Contar até 10 devagar ou fazer alongamentos pode liberar a tensão."
        case .frustrated:
            return "Dar um passo para trás e respirar pode trazer nova perspectiva."
        default:
            return "Que tal uma respiração consciente para se centrar?"
        }
    }
    
    private var actionButtonText: String {
        switch emotion {
        case .anxious, .stressed:
            return "Fazer respiração"
        case .sad, .lonely:
            return "Escrever sentimentos"
        case .angry, .frustrated:
            return "Técnica de calma"
        default:
            return "Tentar agora"
        }
    }
    
    private var suggestionAction: String {
        switch emotion {
        case .anxious:
            return "Vamos fazer a respiração 4-7-8 juntos? Inspire por 4, segure por 7, expire por 8."
        case .sad:
            return "Que tal escrever três coisas que você sente agora? Não precisa ser perfeito, apenas honesto."
        case .stressed:
            return "Vamos fazer uma pausa? Respire fundo comigo: inspire... segure... expire devagar."
        case .lonely:
            return "A solidão é difícil. Que tal pensarmos em alguém especial para você e como se conectar?"
        case .angry:
            return "Vamos acalmar essa energia? Conte comigo: 1... 2... 3... respire fundo a cada número."
        case .frustrated:
            return "Frustração acontece. Que tal darmos um passo para trás e vermos isso de outro ângulo?"
        default:
            return "Vamos nos centrar com três respirações profundas juntos?"
        }
    }
}