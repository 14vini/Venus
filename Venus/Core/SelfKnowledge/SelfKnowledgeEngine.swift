//
//  SelfKnowledgeEngine.swift
//  Venus
//
//  Created by Kaua on 09/10/26.
//

import Foundation

final class SelfKnowledgeEngine: Sendable {
    static let shared = SelfKnowledgeEngine()

    init() {}

    // MARK: - Core Diagnosis

    func diagnose(
        userMessage: String,
        readiness: ReadinessEnergyAssessment? = nil,
        recentMoods: [Mood] = [],
        userProfile: UserProfile? = nil,
        currentLens: SelfKnowledgeLens = .socratic
    ) -> SelfKnowledgeDiagnosis {
        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return SelfKnowledgeDiagnosis(activeLens: currentLens)
        }

        let dissonance = detectDissonance(
            text: trimmed,
            readiness: readiness,
            recentMoods: recentMoods,
            userProfile: userProfile
        )

        let defenseMechanism = detectDefenseMechanism(text: trimmed)
        let shadowInsight = detectShadowProjection(text: trimmed)
        let valuesAlert = detectValuesAlert(text: trimmed, profile: userProfile)

        let socraticQuestion = resolveSocraticQuestion(
            lens: currentLens,
            dissonance: dissonance,
            defense: defenseMechanism,
            shadow: shadowInsight,
            valuesAlert: valuesAlert,
            text: trimmed
        )

        return SelfKnowledgeDiagnosis(
            activeLens: currentLens,
            dissonance: dissonance,
            defenseMechanism: defenseMechanism,
            shadowInsight: shadowInsight,
            valuesAlert: valuesAlert,
            recommendedSocraticQuestion: socraticQuestion
        )
    }

    // MARK: - 1. Radar de Contradições (Dissonance Detection)

    func detectDissonance(
        text: String,
        readiness: ReadinessEnergyAssessment?,
        recentMoods: [Mood],
        userProfile: UserProfile?
    ) -> DissonanceDetection? {
        let lower = text.lowercased()
        let readinessScore = readiness?.score ?? fallbackReadinessScore(from: recentMoods)
        let isLowReadiness = readinessScore <= 5.0

        // A. Intolerância Induzida por Fisiologia Baixa
        if isLowReadiness && matchesPhysiologicalIrritabilityKeywords(in: lower) {
            let scoreFormatted = String(format: "%.1f", readinessScore)
            return DissonanceDetection(
                type: .physiologicalIrritability,
                headline: "Intolerância Social Induzida por Bateria Biológica Esgotada",
                explanation: "Seu Readiness atual está em \(scoreFormatted)/10. Quando a reserva do sistema nervoso cai, o limiar de paciência despenca — o problema frequentemente não são as pessoas, mas a falta de recuperação biológica.",
                socraticQuestion: "As pessoas ao seu redor realmente ficaram subitamente incompetentes, ou é a sua bateria interna que está sem margem para absorver qualquer atrito hoje?",
                confidence: 0.92
            )
        }

        // B. Dissonância Fisiológica vs. Discurso de Hiperfoco/Sobrecarga
        if isLowReadiness && matchesHyperdriveKeywords(in: lower) {
            let scoreFormatted = String(format: "%.1f", readinessScore)
            return DissonanceDetection(
                type: .physioVsSpeech,
                headline: "Corpo em Reserva vs. Discurso de Aceleração",
                explanation: "Sua bateria biológica calculada está em \(scoreFormatted)/10, mas você está planejando esforço intenso ou estender a jornada. Isso é compensação reativa, não clareza mental.",
                socraticQuestion: "Você está querendo produzir agora por clareza e vigor real, ou está tentando anestesiar uma sensação de atraso ou culpa que o trabalho noturno não vai curar?",
                confidence: 0.95
            )
        }

        // C. Violação de Valores Inegociáveis (Angústia Difusa)
        if matchesValuesBetrayalKeywords(in: lower) {
            return DissonanceDetection(
                type: .valuesBetrayal,
                headline: "Angústia Difusa: Sinais de Auto-traição de Princípios",
                explanation: "Um aperto ou peso sem causa externa óbvia é o sinal clássico de que você fez uma concessão contra um valor inegociável seu para evitar conflito recente.",
                socraticQuestion: "Em qual conversa das últimas 48 horas você disse 'sim' querendo dizer 'não'? Onde você negociou um limite seu?",
                confidence: 0.88
            )
        }

        // D. Racionalização de Fuga
        if matchesRationalizationAvoidanceKeywords(in: lower) {
            return DissonanceDetection(
                type: .rationalizedAvoidance,
                headline: "Intelectualização de uma Dor Emocional",
                explanation: "Você está construindo uma explicação fria e lógica para contornar uma vulnerabilidade que não quer sentir no corpo.",
                socraticQuestion: "Se você pausar a lógica por trinta segundos: qual é o sentimento cru e desconfortável que está por trás dessa explicação perfeita?",
                confidence: 0.82
            )
        }

        return nil
    }

    // MARK: - 2. Detector de Mecanismos de Defesa

    func detectDefenseMechanism(text: String) -> DefenseMechanism? {
        let lower = text.lowercased()

        // 1. Minimização
        let minimizationTerms = [
            "não foi nada", "nao foi nada", "vida que segue", "tô acostumado", "to acostumado",
            "bobagem minha", "besteira", "nem liguei", "nada demais", "não me afeta", "nao me afeta",
            "já superei", "ja superei", "é bobagem", "e bobagem"
        ]
        if minimizationTerms.contains(where: { lower.contains($0) }) {
            return .minimization
        }

        // 2. Intelectualização
        let intellectualizationTerms = [
            "estatisticamente", "analisando friamente", "sob uma ótica puramente",
            "teoricamente falando", "em termos objetivos e lógicos", "uma questão puramente analítica",
            "não sinto nada a respeito, só acho que", "se olharmos sociologicamente"
        ]
        if intellectualizationTerms.contains(where: { lower.contains($0) }) {
            return .intellectualization
        }

        // 3. Deslocamento
        let displacementTerms = [
            "irritado com essa bagunça", "odio dessa louça", "perdi a cabeça por uma besteira",
            "estou descontando", "qualquer coisinha me tira do sério", "estourando por bobeira",
            "explodi com"
        ]
        if displacementTerms.contains(where: { lower.contains($0) }) {
            return .displacement
        }

        // 4. Racionalização
        let rationalizationTerms = [
            "não tinha outra escolha", "nao tinha outra escolha", "era a única opção",
            "qualquer um no meu lugar faria", "fui obrigado a", "não tive como evitar",
            "eu precisava fazer isso senão"
        ]
        if rationalizationTerms.contains(where: { lower.contains($0) }) {
            return .rationalization
        }

        // 5. Projeção
        let projectionTerms = [
            "ele é tão invejoso", "ela só quer atenção", "todo mundo quer me ferrar",
            "são todos falsos", "as pessoas só pensam em si", "ninguém presta"
        ]
        if projectionTerms.contains(where: { lower.contains($0) }) {
            return .projection
        }

        return nil
    }

    // MARK: - 3. Espelho da Sombra (Shadow Work / Jung)

    func detectShadowProjection(text: String) -> ShadowProjectionInsight? {
        let lower = text.lowercased()

        // Padrões de forte irritação com terceiros
        let projectionPatterns: [(trigger: String, trait: String, shadowRule: String)] = [
            ("folgado", "folga e descanso alheio", "Você tem pânico de parecer preguiçoso e se pune quando descansa"),
            ("preguiçoso", "falta de esforço alheio", "Sua regra interna exige hiper-produção para você se sentir com valor"),
            ("arrogante", "autoafirmação e orgulho alheio", "Você teme ocupar espaço ou ser julgado quando expressa confiança"),
            ("carente", "necessidade de afeto alheia", "Você rejeita a sua própria necessidade de pedir ajuda e ser cuidado"),
            ("egoísta", "imposição de limites alheios", "Você tem extrema dificuldade de dizer 'não' e ressente quem diz com facilidade"),
            ("se faz de vítima", "vulnerabilidade alheia", "Você se orgulha de aguentar tudo sozinho, mesmo quando está quebrando por dentro")
        ]

        let judgmentMarkers = ["detesto como", "odeio quando", "não suporto", "nao suporto", "me irrita que", "morro de raiva", "tão chato como"]
        let hasStrongJudgment = judgmentMarkers.contains { lower.contains($0) }

        for pattern in projectionPatterns {
            if lower.contains(pattern.trigger) && (hasStrongJudgment || lower.contains("ele ") || lower.contains("ela ") || lower.contains("fulano")) {
                let question = "O que nessa atitude de \(pattern.trait) ameaça a regra severa que você se impõe? O que aconteceria se você se permitisse 10% dessa liberdade?"
                return ShadowProjectionInsight(
                    targetSubject: pattern.trigger,
                    projectedTrait: pattern.trait,
                    internalShadowRule: pattern.shadowRule,
                    inversionQuestion: question
                )
            }
        }

        return nil
    }

    // MARK: - 4. Auditoria de Valores

    func detectValuesAlert(text: String, profile: UserProfile?) -> String? {
        let lower = text.lowercased()
        if matchesValuesBetrayalKeywords(in: lower) {
            return "Angústia de auto-traição detectada. Investigue onde você negociou um limite fundamental recente."
        }
        return nil
    }

    // MARK: - Socratic Question Resolution

    private func resolveSocraticQuestion(
        lens: SelfKnowledgeLens,
        dissonance: DissonanceDetection?,
        defense: DefenseMechanism?,
        shadow: ShadowProjectionInsight?,
        valuesAlert: String?,
        text: String
    ) -> String? {
        // Se houver dissonância imediata, a pergunta socrática dela tem prioridade máxima
        if let d = dissonance {
            return d.socraticQuestion
        }

        // Se houver projeção de sombra detectada
        if let s = shadow {
            return s.inversionQuestion
        }

        // Se houver mecanismo de defesa detectado
        if let def = defense {
            return def.diagnosticQuestion
        }

        // Caso a lente seja estritamente socrática, aplicar heurística sobre o texto
        if lens == .socratic {
            return generateGenericSocraticPrompt(for: text)
        }

        return nil
    }

    private func generateGenericSocraticPrompt(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("tenho que") || lower.contains("preciso") || lower.contains("obrigado") {
            return "O que exatamente você acredita que desmorona se você simplesmente não fizer isso hoje?"
        }
        if lower.contains("medo") || lower.contains("inseguro") || lower.contains("ansioso") {
            return "Qual é a história catastrófica mais extrema que a sua mente está criando, e qual é a evidência real a favor dela?"
        }
        return "Qual é a verdade desconfortável sobre essa situação que você está tentando não enxergar?"
    }

    // MARK: - Prompt Injection Builder (Para OpenRouter / LLM)

    func buildPromptEnrichment(
        diagnosis: SelfKnowledgeDiagnosis,
        lens: SelfKnowledgeLens,
        readiness: ReadinessEnergyAssessment?,
        profile: UserProfile?
    ) -> String {
        var section = "\n\n=== MOTOR DE AUTOCONHECIMENTO DA VENUS ===\n"
        section += "Lente Ativa: \(lens.title) (\(lens.shortTitle))\n"
        section += "Diretriz da Lente: \(lens.directiveDescription)\n"

        if let r = readiness {
            section += "\n[BIOMETRIA & READINESS REAL]:\n"
            section += "- Score de Prontidão: \(String(format: "%.1f", r.score))/10 (\(r.stateTitle))\n"
            section += "- Foco: \(r.focusMetric.title) (\(r.focusMetric.statusText))\n"
            section += "- Corpo: \(r.bodyMetric.title) (\(r.bodyMetric.statusText))\n"
            section += "- Sono: \(r.sleepMetric.title) (\(r.sleepMetric.statusText))\n"
        }

        if let d = diagnosis.dissonance {
            section += "\n[⚡ RADAR DE CONTRADIÇÕES DISPARADO]:\n"
            section += "- Tipo: \(d.type.title)\n"
            section += "- Diagnóstico: \(d.explanation)\n"
            section += "- Pergunta Socrática Recomendada: \"\(d.socraticQuestion)\"\n"
            section += "- INSTRUÇÃO: Aponte delicadamente mas com total lucidez essa contradição na sua resposta. Não passe pano.\n"
        }

        if let def = diagnosis.defenseMechanism {
            section += "\n[🧠 MECANISMO DE DEFESA IDENTIFICADO]:\n"
            section += "- Mecanismo: \(def.title) (\(def.summary))\n"
            section += "- Pergunta Cirúrgica: \"\(def.diagnosticQuestion)\"\n"
            section += "- INSTRUÇÃO: Ajude o usuário a perceber que está usando \(def.title) para se proteger de sentir a dor real.\n"
        }

        if let shadow = diagnosis.shadowInsight {
            section += "\n[🪞 ESPELHO DA SOMBRA JUNGIANA ATIVADO]:\n"
            section += "- Alvo da crítica: \(shadow.targetSubject)\n"
            section += "- Regra interna tirânica do usuário: \(shadow.internalShadowRule)\n"
            section += "- Pergunta de Inversão: \"\(shadow.inversionQuestion)\"\n"
            section += "- INSTRUÇÃO: Inverta o foco do terceiro para a regra interna rígida do próprio usuário.\n"
        }

        if let q = diagnosis.recommendedSocraticQuestion, diagnosis.dissonance == nil && diagnosis.shadowInsight == nil {
            section += "\n[PERGUNTA SOCRÁTICA SUGERIDA]:\n"
            section += "- Considere finalizar ou direcionar seu questionamento com: \"\(q)\"\n"
        }

        section += "\nREGRAS CRUCIAIS:\n"
        section += "1. Jamais seja agressiva ou punitiva; seja cirúrgica, lúcida e compassiva.\n"
        section += "2. Não dê respostas fáceis ou conselhos clichês de autoajuda.\n"
        section += "3. Conclua com UMA pergunta afiada que force a autorreflexão real.\n"
        section += "==========================================\n"

        return section
    }

    // MARK: - Private Keyword Matchers

    private func matchesHyperdriveKeywords(in text: String) -> Bool {
        let terms = [
            "virar a noite", "varar a noite", "varar a madrugada", "virar a madrugada",
            "trabalhar até tarde", "mais uma task", "mais um projeto", "compensar",
            "produzir mais", "acelerar", "dar um gás", "dar um gas", "não posso parar",
            "nao posso parar", "adiantar a semana", "adiantar trabalho", "sou produtivo na madrugada",
            "vou abrir mais uma", "render mais", "hiperfoco"
        ]
        return terms.contains { text.contains($0) }
    }

    private func matchesPhysiologicalIrritabilityKeywords(in text: String) -> Bool {
        let terms = [
            "sem paciência", "sem paciencia", "não aguento ninguém", "nao aguento ninguem",
            "não suporto ninguém", "nao suporto ninguem", "todo mundo é burro", "povo lerdo",
            "ninguém faz nada", "ninguem faz nada", "pessoas me irritam", "irritado com todo mundo",
            "sem saco para pessoas", "falta de competência alheia", "incompetentes", "estou sem paciência"
        ]
        return terms.contains { text.contains($0) }
    }

    private func matchesValuesBetrayalKeywords(in text: String) -> Bool {
        let terms = [
            "aperto no peito", "angústia estranha", "angustia estranha", "sensação ruim e não sei",
            "sensacao ruim e nao sei", "nada deu errado mas", "vazio no peito", "estranho por dentro",
            "peso sem motivo", "angustiado sem saber", "algo errado comigo", "peso no peito"
        ]
        return terms.contains { text.contains($0) }
    }

    private func matchesRationalizationAvoidanceKeywords(in text: String) -> Bool {
        let terms = [
            "não sinto nada, só acho", "na verdade é puramente lógico", "só estou sendo realista",
            "não estou chateado, é só a dinâmica", "estatisticamente é o esperado", "não é pessoal, só acho"
        ]
        return terms.contains { text.contains($0) }
    }

    private func fallbackReadinessScore(from moods: [Mood]) -> Double {
        guard let latest = moods.last else { return 7.5 }
        switch latest.type {
        case .energetic: return 9.0
        case .happy: return 8.2
        case .calm: return 7.5
        case .tired: return 4.0
        case .stressed: return 3.2
        case .sad: return 3.0
        }
    }
}
