//
//  MirrorEngine.swift
//  Venus
//
//  Created by Kaua on 18/06/26.
//

import Foundation

struct MirrorInsight: Equatable, Sendable {
    public let reflectionText: String
    public let probability: Double
    public let dominantCorrelation: String 
}

final class MirrorEngine {
    
    init() {}
    
    /// Generates a reflection insight mimicking a sophisticated statistical engine
    /// crossing current state with historical insights.
    func generateReflection(
        insights: WeeklyStrategicInsights?,
        analysis: BehaviorPatternAnalysis? = nil
    ) -> MirrorInsight {
        
        let trigger = insights?.dominantTrigger ?? "sua rotina"
        
        // Simulating probability logic:
        let isStressHigh = (analysis?.indicators.highStressDays ?? 0) >= 2
        let hasHabitDrop = analysis?.indicators.hasHabitCorrelation == true
        
        var probability = 0.60
        if isStressHigh { probability += 0.20 }
        if hasHabitDrop { probability += 0.10 }
        probability = min(0.95, probability)
        
        let percentageText = "\(Int(probability * 100))%"
        
        var reflection = ""
        var correlation = ""
        
        if isStressHigh && insights?.dominantTrigger != nil {
            correlation = "Estresse Alto + \(trigger.capitalized)"
            reflection = "Percebi que nas últimas vezes que você lidou com \(trigger.lowercased()) em dias estressantes, há uma chance de \(percentageText) de sua ansiedade subir. Por isso, preparei um espaço seguro para você."
        } else if let window = insights?.criticalWindow {
            correlation = "Janela Crítica: \(window)"
            // Extrair "sua janela critica recorrente é a tarde" -> "tarde"
            let windowLower = window.lowercased().replacingOccurrences(of: "sua janela crítica recorrente é a ", with: "")
            reflection = "O meu espelho mostra um padrão: é durante a \(windowLower) que você costuma precisar de mais apoio. Estou aqui com você."
        } else if hasHabitDrop {
            correlation = "Queda de Hábitos"
            reflection = "Notei que a correria recente bagunçou um pouco o seu ritmo. Tirei um tempo para preparar algo rápido para ajudar a reencontrar o centro."
        } else {
            correlation = "Reflexo do Dia"
            reflection = "Sinto que o dia de hoje tem exigido um pouco mais da sua energia. Preparei esse respiro especialmente para cuidar de você agora."
        }
        
        return MirrorInsight(
            reflectionText: reflection,
            probability: probability,
            dominantCorrelation: correlation
        )
    }
}
