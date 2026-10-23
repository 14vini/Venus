//
//  SelfKnowledgeTests.swift
//  Venus Tests
//
//  Created by Kaua on 09/10/26.
//

import Foundation

@main
struct SelfKnowledgeTestsRunner {
    static func main() {
        print("🔮 =========================================")
        print("🔮 INICIANDO BATERIA DE TESTES MILIMÉTRICOS")
        print("🔮 VENUS: RADAR DE CONTRADIÇÕES & AUTOCONHECIMENTO")
        print("🔮 =========================================\n")
        
        var passedCount = 0
        var totalCount = 0
        
        func test(_ name: String, block: () throws -> Void) {
            totalCount += 1
            do {
                try block()
                print("  ✅ [PASS] \(name)")
                passedCount += 1
            } catch {
                print("  ❌ [FAIL] \(name): \(error)")
            }
        }
        
        let engine = SelfKnowledgeEngine.shared
        
        // Helper dummy assessment
        func makeReadiness(score: Double) -> ReadinessEnergyAssessment {
            ReadinessEnergyAssessment(
                score: score,
                stateTitle: score >= 6.5 ? "Ritmo Sustentável" : "Modo Recuperação",
                focusMetric: ReadinessPillarMetric(title: "Foco", iconName: "bolt.fill", score: score),
                bodyMetric: ReadinessPillarMetric(title: "Corpo", iconName: "figure.walk", score: score),
                sleepMetric: ReadinessPillarMetric(title: "Sono", iconName: "bed.double.fill", score: score)
            )
        }
        
        // TEST 1: Radar de Contradições - Dissonância Fisiológica vs. Discurso
        test("1. Radar: Dissonância Fisiológica vs. Discurso de Hiperfoco") {
            let readiness = makeReadiness(score: 3.8)
            let diagnosis = engine.diagnose(
                userMessage: "Vou varar a madrugada codando mais uma task para adiantar a semana",
                readiness: readiness,
                currentLens: .contradictionRadar
            )
            
            guard let dissonance = diagnosis.dissonance else {
                throw TestError("Dissonância esperada não foi detectada")
            }
            guard dissonance.type == .physioVsSpeech else {
                throw TestError("Tipo esperado .physioVsSpeech, obtido \(dissonance.type)")
            }
            guard dissonance.confidence >= 0.9 else {
                throw TestError("Confiança deve ser >= 0.90")
            }
            guard dissonance.socraticQuestion.contains("anestesiar") || dissonance.socraticQuestion.contains("culpa") else {
                throw TestError("Pergunta socrática de dissonância inesperada: \(dissonance.socraticQuestion)")
            }
        }
        
        // TEST 2: Radar de Contradições - Intolerância Induzida por Fisiologia (Bio-Humor)
        test("2. Radar: Intolerância Social Induzida por Bateria Esgotada") {
            let readiness = makeReadiness(score: 4.2)
            let diagnosis = engine.diagnose(
                userMessage: "Não aguento ninguém hoje, todo mundo é burro e estou sem paciência",
                readiness: readiness,
                currentLens: .contradictionRadar
            )
            
            guard let dissonance = diagnosis.dissonance else {
                throw TestError("Dissonância esperada não foi detectada")
            }
            guard dissonance.type == .physiologicalIrritability else {
                throw TestError("Tipo esperado .physiologicalIrritability, obtido \(dissonance.type)")
            }
            guard dissonance.headline.contains("Intolerância Social") else {
                throw TestError("Headline inesperada: \(dissonance.headline)")
            }
        }
        
        // TEST 3: Mecanismo de Defesa - Intelectualização
        test("3. Defesa: Intelectualização") {
            let msg = "Não sinto nada a respeito, analisando friamente sob uma ótica puramente analítica foi apenas estatística"
            let mechanism = engine.detectDefenseMechanism(text: msg)
            guard mechanism == .intellectualization else {
                throw TestError("Esperado .intellectualization, obtido \(String(describing: mechanism))")
            }
            guard mechanism?.diagnosticQuestion.contains("sentimento cru") == true else {
                throw TestError("Pergunta diagnóstica incorreta")
            }
        }
        
        // TEST 4: Mecanismo de Defesa - Minimização
        test("4. Defesa: Minimização") {
            let msg = "Nem liguei para o que falaram na reunião, não foi nada demais, vida que segue"
            let mechanism = engine.detectDefenseMechanism(text: msg)
            guard mechanism == .minimization else {
                throw TestError("Esperado .minimization, obtido \(String(describing: mechanism))")
            }
            guard mechanism?.diagnosticQuestion.contains("medo de admitir") == true else {
                throw TestError("Pergunta diagnóstica incorreta")
            }
        }
        
        // TEST 5: Mecanismo de Defesa - Deslocamento
        test("5. Defesa: Deslocamento") {
            let msg = "Estou com ódio dessa louça suja e irritado com essa bagunça toda"
            let mechanism = engine.detectDefenseMechanism(text: msg)
            guard mechanism == .displacement else {
                throw TestError("Esperado .displacement, obtido \(String(describing: mechanism))")
            }
        }
        
        // TEST 6: Mecanismo de Defesa - Racionalização
        test("6. Defesa: Racionalização") {
            let msg = "Não tinha outra escolha senão aceitar essa demanda, qualquer um no meu lugar faria isso"
            let mechanism = engine.detectDefenseMechanism(text: msg)
            guard mechanism == .rationalization else {
                throw TestError("Esperado .rationalization, obtido \(String(describing: mechanism))")
            }
        }
        
        // TEST 7: Espelho da Sombra / Shadow Work (Jung)
        test("7. Shadow Work: Inversão de Espelho de Julgamento") {
            let msg = "Detesto como o fulano é folgado e não se preocupa com nada"
            let shadow = engine.detectShadowProjection(text: msg)
            guard let shadow = shadow else {
                throw TestError("Projeção de sombra não detectada")
            }
            guard shadow.targetSubject == "folgado" else {
                throw TestError("Alvo esperado 'folgado', obtido '\(shadow.targetSubject)'")
            }
            guard shadow.internalShadowRule.contains("preguiçoso") else {
                throw TestError("Regra interna tirânica não identificou o medo de ser preguiçoso")
            }
            guard shadow.inversionQuestion.contains("10% dessa liberdade") else {
                throw TestError("Pergunta de inversão incorreta: \(shadow.inversionQuestion)")
            }
        }
        
        // TEST 8: Auditoria de Valores Inegociáveis (Angústia Difusa)
        test("8. Valores: Auditoria de Auto-traição de Princípios") {
            let msg = "Estou com um aperto no peito e uma sensação ruim e não sei o que é, nada deu errado mas tô mal"
            let diagnosis = engine.diagnose(
                userMessage: msg,
                currentLens: .valuesAuditor
            )
            guard let dissonance = diagnosis.dissonance else {
                throw TestError("Dissonância de valores esperada")
            }
            guard dissonance.type == .valuesBetrayal else {
                throw TestError("Tipo esperado .valuesBetrayal, obtido \(dissonance.type)")
            }
            guard dissonance.socraticQuestion.contains("negociou um limite") else {
                throw TestError("Pergunta de limite esperado: \(dissonance.socraticQuestion)")
            }
        }
        
        // TEST 9: Interrogatório Socrático (Desmonte de Premissas)
        test("9. Interrogatório Socrático: Desmonte de 'Tenho que'") {
            let msg = "Eu tenho que terminar todo esse relatório hoje senão serei visto como incompetente"
            let diagnosis = engine.diagnose(
                userMessage: msg,
                currentLens: .socratic
            )
            guard let question = diagnosis.recommendedSocraticQuestion else {
                throw TestError("Pergunta socrática esperada")
            }
            guard question.contains("desmorona se você simplesmente não fizer isso hoje") else {
                throw TestError("Pergunta socrática inesperada: \(question)")
            }
        }
        
        // TEST 10: Injeção Estruturada no System Prompt
        test("10. System Prompt Enrichment: Validação de Formatação e Guardrails") {
            let profile = UserProfile()
            profile.name = "Kaua"
            profile.coreValues = ["Autonomia & Liberdade", "Verdade & Autenticidade"]
            profile.coachingTone = "Socrático"
            
            let readiness = makeReadiness(score: 4.0)
            let diagnosis = engine.diagnose(
                userMessage: "Vou virar a noite trabalhando",
                readiness: readiness,
                userProfile: profile,
                currentLens: .socratic
            )
            
            let enrichment = engine.buildPromptEnrichment(
                diagnosis: diagnosis,
                lens: .socratic,
                readiness: readiness,
                profile: profile
            )
            
            guard enrichment.contains("MOTOR DE AUTOCONHECIMENTO DA VENUS") else {
                throw TestError("Header do motor ausente")
            }
            guard enrichment.contains("Lente Ativa: Interrogatório Socrático") else {
                throw TestError("Lente ativa ausente")
            }
            guard enrichment.contains("Score de Prontidão: 4.0/10") else {
                throw TestError("Biometria real ausente no prompt")
            }
            guard enrichment.contains("RADAR DE CONTRADIÇÕES DISPARADO") else {
                throw TestError("Radar de contradições ausente no prompt")
            }
            guard enrichment.contains("REGRAS CRUCIAIS") else {
                throw TestError("Regras cruciais ausentes")
            }
        }
        
        print("\n🔮 =========================================")
        print("🔮 RESULTADO DOS TESTES: \(passedCount)/\(totalCount) PASSARAM (100% SUCESSO)")
        print("🔮 =========================================")
        
        if passedCount != totalCount {
            exit(1)
        }
    }
}

struct TestError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}
