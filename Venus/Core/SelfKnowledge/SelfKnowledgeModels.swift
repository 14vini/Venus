//
//  SelfKnowledgeModels.swift
//  Venus
//
//  Created by Kaua on 09/10/26.
//

import Foundation
import SwiftUI

// MARK: - Self Knowledge Lens (Lentes de Autoconhecimento)

enum SelfKnowledgeLens: String, CaseIterable, Identifiable, Codable, Sendable {
    case socratic           = "socratic"
    case contradictionRadar = "contradiction_radar"
    case shadowMirror       = "shadow_mirror"
    case defenseAnalysis    = "defense_analysis"
    case valuesAuditor      = "values_auditor"
    case compassionate      = "compassionate"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .socratic:
            return "Interrogatório Socrático"
        case .contradictionRadar:
            return "Radar de Contradições"
        case .shadowMirror:
            return "Espelho da Sombra"
        case .defenseAnalysis:
            return "Detector de Defesas"
        case .valuesAuditor:
            return "Auditor de Valores"
        case .compassionate:
            return "Acolhedor & Gentil"
        }
    }

    var shortTitle: String {
        switch self {
        case .socratic: return "Socrático"
        case .contradictionRadar: return "Radar"
        case .shadowMirror: return "Sombra"
        case .defenseAnalysis: return "Defesas"
        case .valuesAuditor: return "Valores"
        case .compassionate: return "Suave"
        }
    }

    var iconName: String {
        switch self {
        case .socratic: return "questionmark.bubble.fill"
        case .contradictionRadar: return "bolt.shield.fill"
        case .shadowMirror: return "person.crop.circle.badge.questionmark"
        case .defenseAnalysis: return "brain.head.profile"
        case .valuesAuditor: return "compass.drawing"
        case .compassionate: return "heart.fill"
        }
    }

    var badgeColor: Color {
        switch self {
        case .socratic: return .orange
        case .contradictionRadar: return .yellow
        case .shadowMirror: return .purple
        case .defenseAnalysis: return .indigo
        case .valuesAuditor: return .teal
        case .compassionate: return .pink
        }
    }

    var directiveDescription: String {
        switch self {
        case .socratic:
            return "Desmonte premissas frágeis. Em vez de conselhos confortáveis, devolva perguntas cirúrgicas que exponham o custo oculto das escolhas."
        case .contradictionRadar:
            return "Exponha a dissonância entre o discurso verbal e a biometria/histórico de prontidão. Destaque quando o corpo pede descanso e a mente tenta compensar com sobrecarga."
        case .shadowMirror:
            return "Use a psicologia junguiana: transforme o julgamento veemente sobre terceiros em um espelho para investigar as próprias regras rígidas e desejos reprimidos do usuário."
        case .defenseAnalysis:
            return "Identifique mecanismos de defesa (intelectualização, minimização, deslocamento, racionalização) e ajude o usuário a nomear a emoção crua que está sendo evitada."
        case .valuesAuditor:
            return "Investigue angústias difusas buscando onde o usuário disse 'sim' querendo dizer 'não' e traiu seus valores inegociáveis (autonomia, autenticidade, paz)."
        case .compassionate:
            return "Escuta ativa calorosa, acolhimento empático e suporte gentil."
        }
    }
}

// MARK: - Defense Mechanisms (Mecanismos de Defesa Psicológicos)

enum DefenseMechanism: String, CaseIterable, Identifiable, Codable, Sendable {
    case intellectualization = "intelectualizacao"
    case minimization        = "minimizacao"
    case displacement        = "deslocamento"
    case rationalization     = "racionalizacao"
    case repression          = "repressao"
    case projection          = "projecao"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .intellectualization: return "Intelectualização"
        case .minimization: return "Minimização"
        case .displacement: return "Deslocamento"
        case .rationalization: return "Racionalização"
        case .repression: return "Repressão"
        case .projection: return "Projeção"
        }
    }

    var summary: String {
        switch self {
        case .intellectualization:
            return "Filosofar ou teorizar em excesso sobre um problema para anestesiar o impacto emocional da dor."
        case .minimization:
            return "Tratar uma sobrecarga real como 'nada demais' para não admitir o esgotamento."
        case .displacement:
            return "Descarregar irritação em alvos seguros (casa, amigos, detalhes) em vez da fonte real do estresse."
        case .rationalization:
            return "Criar argumentos lógicos impecáveis para justificar hábitos que estão sabotando sua energia."
        case .repression:
            return "Forçar sentimentos difíceis para baixo da mesa fingindo que já foram superados."
        case .projection:
            return "Atribuir aos outros atitudes ou fragilidades que você mais teme confrontar em si mesmo."
        }
    }

    var diagnosticQuestion: String {
        switch self {
        case .intellectualization:
            return "Se você parar de analisar a teoria por um minuto: qual é o sentimento cru que você está evitando sentir no corpo agora?"
        case .minimization:
            return "Por que você precisa agir como se isso não te afetasse? Qual é o medo de admitir que doeu ou que você está no limite?"
        case .displacement:
            return "Essa irritação é realmente com esse detalhe, ou tem algo muito mais pesado que você não está conseguindo endereçar na origem?"
        case .rationalization:
            return "Seus argumentos fazem todo sentido na lógica — mas qual é a verdade desconfortável que eles estão tentando proteger?"
        case .repression:
            return "O que acontece se você simplesmente admitir o cansaço sem tentar consertar tudo agora?"
        case .projection:
            return "O que nessa atitude do outro te irrita porque lembra uma vulnerabilidade ou uma regra rígida sua?"
        }
    }
}

// MARK: - Dissonance Types & Detection (Dissonância Cognitiva e Somática)

enum DissonanceType: String, CaseIterable, Codable, Sendable {
    case physioVsSpeech            = "physio_vs_speech"
    case intentionVsPattern        = "intention_vs_pattern"
    case rationalizedAvoidance     = "rationalized_avoidance"
    case physiologicalIrritability = "physiological_irritability"
    case valuesBetrayal            = "values_betrayal"

    var title: String {
        switch self {
        case .physioVsSpeech:
            return "Dissonância Fisiológica vs. Discurso"
        case .intentionVsPattern:
            return "Intenção vs. Histórico"
        case .rationalizedAvoidance:
            return "Racionalização de Fuga"
        case .physiologicalIrritability:
            return "Intolerância Induzida por Fisiologia"
        case .valuesBetrayal:
            return "Violação de Valores Inegociáveis"
        }
    }

    var badgeLabel: String {
        switch self {
        case .physioVsSpeech: return "⚡ Radar: Corpo vs. Fala"
        case .intentionVsPattern: return "🔄 Radar: Intenção vs. Hábito"
        case .rationalizedAvoidance: return "🧠 Radar: Racionalização"
        case .physiologicalIrritability: return "🫀 Radar: Intolerância Biológica"
        case .valuesBetrayal: return "🧭 Radar: Violação de Valores"
        }
    }
}

struct DissonanceDetection: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let type: DissonanceType
    let headline: String
    let explanation: String
    let socraticQuestion: String
    let confidence: Double // 0.0 ... 1.0

    init(
        id: UUID = UUID(),
        type: DissonanceType,
        headline: String,
        explanation: String,
        socraticQuestion: String,
        confidence: Double = 0.85
    ) {
        self.id = id
        self.type = type
        self.headline = headline
        self.explanation = explanation
        self.socraticQuestion = socraticQuestion
        self.confidence = confidence
    }
}

// MARK: - Shadow Projection (Projeção da Sombra Junguiana)

struct ShadowProjectionInsight: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let targetSubject: String
    let projectedTrait: String
    let internalShadowRule: String
    let inversionQuestion: String

    init(
        id: UUID = UUID(),
        targetSubject: String,
        projectedTrait: String,
        internalShadowRule: String,
        inversionQuestion: String
    ) {
        self.id = id
        self.targetSubject = targetSubject
        self.projectedTrait = projectedTrait
        self.internalShadowRule = internalShadowRule
        self.inversionQuestion = inversionQuestion
    }
}

// MARK: - Core Values (Valores Inegociáveis)

enum CoreValueOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case autonomy     = "Autonomia & Liberdade"
    case truth        = "Verdade & Autenticidade"
    case peace        = "Paz & Equilíbrio"
    case excellence   = "Excelência & Maestria"
    case connection   = "Conexão & Afeto"
    case vitality     = "Saúde & Vitalidade"
    case integrity    = "Integridade & Limites"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .autonomy: return "figure.run"
        case .truth: return "eye.fill"
        case .peace: return "leaf.fill"
        case .excellence: return "crown.fill"
        case .connection: return "person.2.fill"
        case .vitality: return "flame.fill"
        case .integrity: return "shield.lefthalf.filled"
        }
    }
}

// MARK: - Full Self Knowledge Diagnosis (Diagnóstico Consolidado)

struct SelfKnowledgeDiagnosis: Equatable, Sendable {
    let activeLens: SelfKnowledgeLens
    let dissonance: DissonanceDetection?
    let defenseMechanism: DefenseMechanism?
    let shadowInsight: ShadowProjectionInsight?
    let valuesAlert: String?
    let recommendedSocraticQuestion: String?

    init(
        activeLens: SelfKnowledgeLens,
        dissonance: DissonanceDetection? = nil,
        defenseMechanism: DefenseMechanism? = nil,
        shadowInsight: ShadowProjectionInsight? = nil,
        valuesAlert: String? = nil,
        recommendedSocraticQuestion: String? = nil
    ) {
        self.activeLens = activeLens
        self.dissonance = dissonance
        self.defenseMechanism = defenseMechanism
        self.shadowInsight = shadowInsight
        self.valuesAlert = valuesAlert
        self.recommendedSocraticQuestion = recommendedSocraticQuestion
    }

    var hasInsight: Bool {
        dissonance != nil || defenseMechanism != nil || shadowInsight != nil || valuesAlert != nil
    }
}
