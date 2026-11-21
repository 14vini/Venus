//
//  VenusWellnessMode.swift
//  Venus
//
//  Modos de bem-estar e regulação do sistema nervoso representados
//  pelos seixos translúcidos da Home (Stress, Sleep, Burnout, Meditation, Anxiety, Rest).
//

import SwiftUI

public enum VenusWellnessMode: String, CaseIterable, Identifiable, Sendable {
    case stress
    case sleep
    case burnout
    case meditation
    case rest
    case anxiety

    public var id: String { rawValue }

    /// Rótulo exibido no seixo de vidro
    public var label: String {
        switch self {
        case .stress:     return "Stress"
        case .sleep:      return "Sleep"
        case .burnout:    return "Burnout"
        case .meditation: return "Meditation"
        case .rest:       return "Sleep"
        case .anxiety:    return "Anxiety"
        }
    }

    /// Primeira linha do título grande da Home ("Start Your Stress")
    public var titleFirst: String {
        switch self {
        case .stress:     return "Stress"
        case .sleep:      return "Sleep"
        case .burnout:    return "Burnout"
        case .meditation: return "Mindful"
        case .rest:       return "Sensory"
        case .anxiety:    return "Anxiety"
        }
    }

    /// Segunda linha do título grande da Home ("Relief Mode")
    public var titleSecond: String {
        switch self {
        case .stress:     return "Relief Mode"
        case .sleep:      return "Restoration Mode"
        case .burnout:    return "Recovery Mode"
        case .meditation: return "Presence Mode"
        case .rest:       return "Pause Mode"
        case .anxiety:    return "Soothing Mode"
        }
    }

    /// Subtítulo explicativo com foco no sistema nervoso
    public var subtitle: String {
        switch self {
        case .stress:
            return "Calm your nervous system and reduce tension."
        case .sleep:
            return "Downregulate sensory input and drift into deep rest."
        case .burnout:
            return "Release chronic cognitive load and recharge vital energy."
        case .meditation:
            return "Anchor into the present moment with conscious breathing."
        case .rest:
            return "Dim mental stimulation and reset focus and attention."
        case .anxiety:
            return "Gently soften racing thoughts and ground your awareness."
        }
    }

    /// SF Symbol associado ao seixo
    public var iconSystemName: String {
        switch self {
        case .stress:     return "waveform.path.ecg"
        case .sleep:      return "cloud.fill"
        case .burnout:    return "leaf.fill"
        case .meditation: return "figure.mind.and.body"
        case .rest:       return "eye.fill"
        case .anxiety:    return "wind"
        }
    }

    /// Cor de brilho ativo do seixo
    public var activeAuraColor: Color {
        switch self {
        case .stress:     return Color(hex: "FDE8D7") // Tom âmbar/pêssego quente do screenshot
        case .sleep:      return Color(hex: "D8E2F8") // Azul lavanda suave
        case .burnout:    return Color(hex: "FAD9CD") // Coral quente
        case .meditation: return Color(hex: "CEF3ED") // Menta etéreo
        case .rest:       return Color(hex: "D3E9F5") // Azul gelo brumoso
        case .anxiety:    return Color(hex: "D0ECF7") // Ciano celeste
        }
    }

    /// Humor correspondente no modelo da Venus
    var associatedMood: MoodType {
        switch self {
        case .stress:     return .stressed
        case .sleep:      return .tired
        case .burnout:    return .sad
        case .meditation: return .calm
        case .rest:       return .tired
        case .anxiety:    return .stressed
        }
    }

    /// Prompt inicial para abrir o diálogo com a IA da Venus
    public var promptSuggestion: String {
        switch self {
        case .stress:
            return "Quero acalmar meu sistema nervoso e aliviar a tensão do estresse agora."
        case .sleep:
            return "Ajude-me a desacelerar a mente para uma noite de descanso profundo e restaurador."
        case .burnout:
            return "Estou me sentindo mentalmente exausto e sobrecarregado. Como posso me recuperar hoje?"
        case .meditation:
            return "Gostaria de uma pausa consciente de 2 minutos para respirar e centrar a mente."
        case .rest:
            return "Preciso de uma pausa rápida de descompressão sensorial para clarear os pensamentos."
        case .anxiety:
            return "Estou sentindo uma onda de ansiedade. Me guie para desacelerar e aterrar."
        }
    }
}
