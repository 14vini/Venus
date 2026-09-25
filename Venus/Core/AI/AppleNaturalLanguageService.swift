//
//  AppleNaturalLanguageService.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import Foundation
import NaturalLanguage

/// Apple Natural Language on-device sentiment and crisis analysis
final class AppleNaturalLanguageService: Sendable {
    static let shared = AppleNaturalLanguageService()
    
    private init() {}
    
    /// Analyzes the text on-device using Apple's NaturalLanguage framework
    func analyze(text: String) -> EmotionalState {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .neutral()
        }
        
        let lowercased = trimmed.lowercased()
        
        // 1. Guardrail de Crise (Detecção Imediata Offline)
        let isCrisis = checkCrisisKeywords(in: lowercased)
        
        // 2. Apple NLTagger Sentiment Analysis
        let sentimentScore = computeSentimentScore(for: trimmed)
        
        // 3. Keyword and Emotion Mapping
        let (emotion, intensity, keywords) = classifyEmotion(from: lowercased, sentimentScore: sentimentScore)
        
        let needsSupport = isCrisis || [.anxious, .sad, .angry, .stressed, .lonely, .frustrated].contains(emotion) || sentimentScore < -0.3
        
        return EmotionalState(
            primaryEmotion: emotion,
            intensity: isCrisis ? 10 : intensity,
            needsSupport: needsSupport,
            keywords: keywords,
            sentimentScore: sentimentScore,
            isCrisisRisk: isCrisis
        )
    }
    
    private func computeSentimentScore(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        if let sentimentScoreString = sentiment?.rawValue, let score = Double(sentimentScoreString) {
            return score // -1.0 (very negative) to 1.0 (very positive)
        }
        return 0.0
    }
    
    private func checkCrisisKeywords(in text: String) -> Bool {
        let crisisTerms = [
            "me matar", "suicídio", "suicidio", "acabar com tudo", "não quero mais viver",
            "nao quero mais viver", "cortar meus pulsos", "tirar minha vida", "morrer de vez",
            "vontade de sumir e nao voltar", "desistir da minha vida", "me enforcar",
            "overdose", "me jogar", "dar fim a tudo"
        ]
        return crisisTerms.contains { text.contains($0) }
    }
    
    private func classifyEmotion(from text: String, sentimentScore: Double) -> (EmotionType, Int, [String]) {
        let emotionKeywords: [(EmotionType, [String])] = [
            (.anxious, ["ansiedade", "ansioso", "ansiosa", "nervoso", "nervosa", "preocupado", "preocupada", "medo", "pânico", "panico", "angústia", "angustia", "taquicardia", "inquieto", "agitado"]),
            (.sad, ["triste", "tristeza", "deprimido", "deprimida", "melancolia", "chateado", "chateada", "desanimado", "desanimada", "vazio", "choro", "chorando", "luto", "pesado", "dor no peito"]),
            (.stressed, ["estresse", "estressado", "estressada", "sobrecarregado", "sobrecarregada", "pressão", "pressao", "exaustão", "exaustao", "esgotado", "esgotada", "sem tempo", "queimado", "burnout"]),
            (.lonely, ["sozinho", "sozinha", "solidão", "solidao", "isolado", "isolada", "abandonado", "abandonada", "incompreendido", "incompreendida", "rejeitado", "sem amigos"]),
            (.angry, ["raiva", "irritado", "irritada", "furioso", "furiosa", "bravo", "brava", "ódio", "odio", "revolta", "indignado", "indignada"]),
            (.frustrated, ["frustrado", "frustrada", "frustração", "frustracao", "travado", "travada", "impotente", "não consigo", "decepcionado", "decepcionada"]),
            (.grateful, ["grato", "grata", "gratidão", "gratidao", "obrigado", "obrigada", "abençoado", "agradecido", "agradecida", "sorte"]),
            (.excited, ["animado", "animada", "empolgado", "empolgada", "feliz", "alegre", "eufórico", "euforica", "ótimo", "otimo", "radiante", "esperançoso"]),
            (.happy, ["feliz", "contente", "satisfeito", "satisfeita", "bem", "tranquilo", "tranquila", "paz", "leve", "harmonia"])
        ]
        
        var matchedKeywords: [String] = []
        var detectedEmotion: EmotionType = .neutral
        var maxMatches = 0
        
        for (emotion, keywords) in emotionKeywords {
            let matches = keywords.filter { text.contains($0) }
            if matches.count > maxMatches {
                maxMatches = matches.count
                detectedEmotion = emotion
                matchedKeywords = matches
            }
        }
        
        if detectedEmotion == .neutral {
            if sentimentScore > 0.3 {
                detectedEmotion = .happy
            } else if sentimentScore < -0.3 {
                detectedEmotion = .sad
            }
        }
        
        let intensityModifier = (text.contains("muito") || text.contains("extremamente") || text.contains("demais") || text.contains("insuportável")) ? 2 : 0
        let baseIntensity = (detectedEmotion == .neutral) ? 5 : 6
        let intensity = min(10, max(1, baseIntensity + intensityModifier))
        
        return (detectedEmotion, intensity, matchedKeywords)
    }
}
