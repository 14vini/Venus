//
//  BehaviorModels.swift
//  Venus
//
//  Created by kaua on 20/02/26.
//

import Foundation

struct BehaviorProfileContext: Equatable, Sendable {
    let improvementAreas: Set<String>
    let emotionalAreas: Set<String>
    let interests: Set<String>
    let workStartHour: Int?
    let workEndHour: Int?
    let studyStartHour: Int?
    let studyEndHour: Int?

    nonisolated static let empty = BehaviorProfileContext(
        improvementAreas: [],
        emotionalAreas: [],
        interests: [],
        workStartHour: nil,
        workEndHour: nil,
        studyStartHour: nil,
        studyEndHour: nil
    )
}

enum BehaviorDayPeriod: String, Codable, CaseIterable, Hashable, Sendable {
    case morning
    case afternoon
    case evening
    case night
}

enum TodoType: String, Codable, CaseIterable, Hashable, Sendable {
    case routine
    case health
    case generic
}

struct BehaviorMoodEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let dayKey: Date
    let dayPeriod: BehaviorDayPeriod
    let moodType: MoodType
    let moodScore: Double
    let intensity: Int
    let triggers: [String]
    let affectedArea: String?
    let energyLevel: MoodEnergyLevel?
    let availableTime: MoodAvailableTime?
    let controlLevel: MoodControlLevel?
    let mentalClarity: Int?
    let sleepQuality: MoodSleepQuality?
    let stressSignalCount: Int

    nonisolated static func == (lhs: BehaviorMoodEvent, rhs: BehaviorMoodEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.timestamp == rhs.timestamp
            && lhs.dayKey == rhs.dayKey
            && lhs.dayPeriod == rhs.dayPeriod
            && lhs.moodType == rhs.moodType
            && lhs.moodScore == rhs.moodScore
            && lhs.intensity == rhs.intensity
            && lhs.triggers == rhs.triggers
            && lhs.affectedArea == rhs.affectedArea
            && lhs.energyLevel == rhs.energyLevel
            && lhs.availableTime == rhs.availableTime
            && lhs.controlLevel == rhs.controlLevel
            && lhs.mentalClarity == rhs.mentalClarity
            && lhs.sleepQuality == rhs.sleepQuality
            && lhs.stressSignalCount == rhs.stressSignalCount
    }
}

struct BehaviorTodoEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let dayKey: Date
    let isCompleted: Bool
    let type: TodoType
    let isSystemGenerated: Bool

    nonisolated static func == (lhs: BehaviorTodoEvent, rhs: BehaviorTodoEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.dayKey == rhs.dayKey
            && lhs.isCompleted == rhs.isCompleted
            && lhs.type == rhs.type
            && lhs.isSystemGenerated == rhs.isSystemGenerated
    }
}

enum ActionFeedbackStage: String, Codable, Sendable {
    case suggested
    case started
    case completed
}

struct ActionFeedbackRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let kind: NextBestActionKind
    let actionKey: String?
    let stage: ActionFeedbackStage
    let perceivedRelief: Int?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        kind: NextBestActionKind,
        actionKey: String? = nil,
        stage: ActionFeedbackStage,
        perceivedRelief: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.actionKey = actionKey
        self.stage = stage
        self.perceivedRelief = perceivedRelief
    }
}

struct BehaviorActionFeedbackEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let dayKey: Date
    let kind: NextBestActionKind
    let actionKey: String?
    let stage: ActionFeedbackStage
    let perceivedRelief: Int?

    nonisolated static func == (lhs: BehaviorActionFeedbackEvent, rhs: BehaviorActionFeedbackEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.timestamp == rhs.timestamp
            && lhs.dayKey == rhs.dayKey
            && lhs.kind == rhs.kind
            && lhs.actionKey == rhs.actionKey
            && lhs.stage == rhs.stage
            && lhs.perceivedRelief == rhs.perceivedRelief
    }
}

struct BehaviorDailyAggregate: Identifiable, Equatable, Sendable {
    let id: Date
    let dayKey: Date
    var moodEntries: Int
    var moodScoreSum: Double
    var intensitySum: Double
    var lowEnergyCount: Int
    var mediumEnergyCount: Int
    var highEnergyCount: Int
    var claritySum: Double
    var clarityCount: Int
    var sleepPoorCount: Int
    var sleepFairCount: Int
    var sleepGoodCount: Int
    var sleepExcellentCount: Int
    var stressSignalTotal: Int
    var triggerCounts: [String: Int]
    var areaCounts: [String: Int]
    var moodTypeCounts: [MoodType: Int]
    var moodCountByPeriod: [BehaviorDayPeriod: Int]
    var moodScoreSumByPeriod: [BehaviorDayPeriod: Double]
    var todoTotal: Int
    var todoCompleted: Int
    var todoSystemGenerated: Int
    var todoByType: [TodoType: Int]
    var habitTotal: Int
    var habitCompleted: Int
    var actionSuggestedByKind: [NextBestActionKind: Int]
    var actionStartedByKind: [NextBestActionKind: Int]
    var actionCompletedByKind: [NextBestActionKind: Int]
    var reliefSum: Double
    var reliefCount: Int

    nonisolated init(dayKey: Date) {
        self.id = dayKey
        self.dayKey = dayKey
        self.moodEntries = 0
        self.moodScoreSum = 0
        self.intensitySum = 0
        self.lowEnergyCount = 0
        self.mediumEnergyCount = 0
        self.highEnergyCount = 0
        self.claritySum = 0
        self.clarityCount = 0
        self.sleepPoorCount = 0
        self.sleepFairCount = 0
        self.sleepGoodCount = 0
        self.sleepExcellentCount = 0
        self.stressSignalTotal = 0
        self.triggerCounts = [:]
        self.areaCounts = [:]
        self.moodTypeCounts = [:]
        self.moodCountByPeriod = [:]
        self.moodScoreSumByPeriod = [:]
        self.todoTotal = 0
        self.todoCompleted = 0
        self.todoSystemGenerated = 0
        self.todoByType = [:]
        self.habitTotal = 0
        self.habitCompleted = 0
        self.actionSuggestedByKind = [:]
        self.actionStartedByKind = [:]
        self.actionCompletedByKind = [:]
        self.reliefSum = 0
        self.reliefCount = 0
    }

    var averageMoodScore: Double {
        guard moodEntries > 0 else { return 0 }
        return moodScoreSum / Double(moodEntries)
    }

    var averageIntensity: Double {
        guard moodEntries > 0 else { return 0 }
        return intensitySum / Double(moodEntries)
    }

    var averageClarity: Double? {
        guard clarityCount > 0 else { return nil }
        return claritySum / Double(clarityCount)
    }

    var todoCompletionRate: Double {
        guard todoTotal > 0 else { return 1 }
        return Double(todoCompleted) / Double(todoTotal)
    }

    var habitCompletionRate: Double? {
        guard habitTotal > 0 else { return nil }
        return Double(habitCompleted) / Double(habitTotal)
    }

    var dominantTrigger: String? {
        triggerCounts.max(by: { $0.value < $1.value })?.key
    }

    var dominantMoodType: MoodType? {
        moodTypeCounts.max(by: { $0.value < $1.value })?.key
    }

    var dominantArea: String? {
        areaCounts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Rich recommendation (clusters, actions e playbook)

enum MoodCluster: String, CaseIterable, Codable, Sendable {
    case calmo, feliz, energizado, focado
    case ansioso, estressado, sobrecarregado
    case irritado
    case triste, desmotivado, apatico
    case cansadoFisico, cansadoMental
}

struct MoodSignals: Codable, Equatable, Sendable {
    let fisicos: [String]
    let mentais: [String]
    let gatilhos: [String]
    let duracaoTipica: String
    let risco: [String]
}

struct ActionVariant: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let title: String
    let detail: String
    let duration: Int
    let category: String
    let cautions: [String]
    let isRich: Bool
    let valueTag: String?
    let areaTag: String?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        duration: Int,
        category: String,
        cautions: [String] = [],
        isRich: Bool = false,
        valueTag: String? = nil,
        areaTag: String? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.duration = duration
        self.category = category
        self.cautions = cautions
        self.isRich = isRich
        self.valueTag = valueTag
        self.areaTag = areaTag
    }
}

struct MoodPlaybook: Codable, Equatable, Sendable {
    let cluster: MoodCluster
    let signals: MoodSignals
    let micro: [ActionVariant]
    let altoImpacto: [ActionVariant]
    let copyWhy: [String]
}

struct Moderators: Sendable {
    let tempoMinutos: Int?
    let energia: String?
    let controle: String?
    let clareza: String?
    let area: String?
    let riscoAlto: Bool
    let horario: Date?
}

struct UserContext: Sendable {
    let mood: MoodCluster
    let intensity: Int
    let moderators: Moderators
    let valuePriority: String?
    let area: String?
    let blockedTask: String?
    let easyTask: String?
    let helpsHistory: [UUID: Int]
    let lastActionCategory: String?
}

final class RichRecommendationEngine: Sendable {
    private let playbook: [MoodCluster: MoodPlaybook]

    init(playbook: [MoodCluster: MoodPlaybook] = RichRecommendationEngine.defaultPlaybook) {
        self.playbook = playbook
    }

    func suggest(for context: UserContext) -> ActionVariant? {
        rankedSuggestions(for: context, limit: 1).first
    }

    func rankedSuggestions(for context: UserContext, limit: Int = 5) -> [ActionVariant] {
        guard limit > 0 else { return [] }
        return scoredSuggestions(for: context)
            .prefix(limit)
            .map(\.variant)
    }

    func scoredSuggestions(for context: UserContext) -> [(variant: ActionVariant, score: Int)] {
        if context.moderators.riscoAlto { return [] }
        guard let base = playbook[context.mood] else { return [] }

        let tempo = context.moderators.tempoMinutos ?? 10
        let pool = actionPool(for: base, tempo: tempo)
        let filtered = pool.filter { action in
            if let energia = context.moderators.energia, energia == "baixa",
               action.category == "movimento", action.duration > 15 {
                return false
            }

            if let controle = context.moderators.controle, controle == "baixo",
               (action.category == "organizacao" || action.category == "problem_solving"),
               action.duration > 15 {
                return false
            }

            return true
        }

        return filtered
            .map { action in
                (variant: action, score: score(action, in: context, tempo: tempo))
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    if lhs.variant.duration == rhs.variant.duration {
                        return lhs.variant.title < rhs.variant.title
                    }
                    return lhs.variant.duration < rhs.variant.duration
                }
                return lhs.score > rhs.score
            }
    }

    private func actionPool(for playbook: MoodPlaybook, tempo: Int) -> [ActionVariant] {
        if tempo <= 7 {
            return playbook.micro
        }

        if tempo <= 15 {
            return playbook.micro + playbook.altoImpacto.filter { $0.duration <= 20 }
        }

        return playbook.altoImpacto + playbook.micro
    }

    private func score(_ action: ActionVariant, in context: UserContext, tempo: Int) -> Int {
        var score = 4

        if action.duration <= tempo {
            score += 2
        } else if action.duration <= tempo + 5 {
            score += 1
        }

        if let area = context.area, let tag = action.areaTag, tag == area {
            score += 3
        }
        if let value = context.valuePriority, let vTag = action.valueTag, vTag == value {
            score += 2
        }
        if action.isRich {
            score += 1
        }
        if let last = context.lastActionCategory, last == action.category {
            score -= 1
        }
        if let feedback = context.helpsHistory[action.id] {
            score += feedback
        }

        if let energia = context.moderators.energia {
            if energia == "baixa" && (action.category == "respiracao" || action.category == "auto_cuidado" || action.category == "sono") {
                score += 2
            }
            if energia == "alta" && (action.category == "movimento" || action.category == "behavioral_activation") {
                score += 2
            }
        }

        if let controle = context.moderators.controle, controle == "baixo",
           action.category == "respiracao" || action.category == "grounding" || action.category == "auto_cuidado" {
            score += 2
        }

        if let clareza = context.moderators.clareza, clareza == "baixa",
           action.category == "organizacao" || action.category == "grounding" || action.category == "manutencao" {
            score += 1
        }

        switch context.mood {
        case .ansioso, .estressado:
            if action.category == "respiracao" || action.category == "grounding" || action.category == "movimento" {
                score += 2
            }
        case .sobrecarregado:
            if action.category == "organizacao" || action.category == "problem_solving" || action.category == "auto_cuidado" {
                score += 2
            }
        case .irritado:
            if action.category == "dbt" || action.category == "distress_tolerance" || action.category == "movimento" {
                score += 2
            }
        case .triste, .desmotivado:
            if action.category == "behavioral_activation" || action.category == "act_valor" || action.category == "conexao" {
                score += 2
            }
        case .apatico:
            if action.category == "manutencao" || action.category == "auto_cuidado" || action.category == "act_valor" {
                score += 2
            }
        case .cansadoFisico, .cansadoMental:
            if action.category == "sono" || action.category == "respiracao" || action.category == "manutencao" || action.category == "auto_cuidado" {
                score += 2
            }
        case .calmo, .focado:
            if action.category == "organizacao" || action.category == "behavioral_activation" {
                score += 2
            }
        case .feliz, .energizado:
            if action.category == "behavioral_activation" || action.category == "conexao" || action.category == "movimento" {
                score += 2
            }
        }

        return score
    }
}

// MARK: - Embedded playbook (JSON seed)

extension RichRecommendationEngine {
    // swiftlint:disable line_length
    private static let embeddedPlaybookJSON: String = """
[
  {
    "cluster": "ansioso",
    "signals": {
      "fisicos": ["taquicardia", "respiração curta", "sudorese", "tensão muscular"],
      "mentais": ["preocupação futura", "catastrofização", "inquietação"],
      "gatilhos": ["provas", "prazos", "conflitos", "saúde", "finanças"],
      "duracaoTipica": "minutos–horas",
      "risco": ["ataques de pânico frequentes", "uso de álcool/remédios para acalmar"]
    },
    "micro": [
      { "id": "11111111-1111-1111-1111-111111111111", "title": "Pausa para respirar (4-4-4)", "detail": "Inspire por 4 segundos, segure por 4 e expire por 4. Faça no seu tempo.", "duration": 5, "category": "respiracao", "cautions": ["evitar retenção longa se problema respiratório/cardiaco"], "isRich": false },
      { "id": "11111111-1111-1111-1111-111111111112", "title": "Dar o primeiro micro-passo", "detail": "Escolha uma tarefa e faça apenas o primeiro passo simples, como abrir o arquivo ou a página.", "duration": 5, "category": "organizacao", "cautions": [], "isRich": true, "areaTag": "trabalho" },
      { "id": "11111111-1111-1111-1111-111111111113", "title": "Esvaziar a cabeça no papel", "detail": "Escreva tudo o que está na sua mente em um papel, sem julgamentos, apenas para esvaziar a cabeça.", "duration": 3, "category": "organizacao", "cautions": [], "isRich": true }
    ],
    "altoImpacto": [
      { "id": "11111111-1111-1111-1111-111111111114", "title": "Simplificar um problema difícil", "detail": "Escreva o problema em uma linha, pense em três saídas simples, escolha uma e dê o primeiro passo hoje.", "duration": 20, "category": "problem_solving", "cautions": [], "isRich": true, "areaTag": "trabalho" },
      { "id": "11111111-1111-1111-1111-111111111115", "title": "Caminhada leve para respirar", "detail": "Caminhe calmamente por 20 minutos, soltando o ar pela boca bem devagar.", "duration": 20, "category": "movimento", "cautions": ["evitar HIIT se muito ativado"], "isRich": false },
      { "id": "11111111-1111-1111-1111-111111111116", "title": "Planejar o dia de amanhã", "detail": "Apenas escolha três coisas importantes para focar amanhã e uma que você vai deixar para depois sem culpa.", "duration": 15, "category": "organizacao", "isRich": true }
    ],
    "copyWhy": [
      "Pensei nessa respiração para te ajudar a soltar um pouco da tensão acumulada que você relatou.",
      "Que tal focar em apenas um passo simples do trabalho hoje? Isso ajuda a tirar aquela sensação de que está tudo acumulado."
    ]
  },
  {
    "cluster": "sobrecarregado",
    "signals": {
      "fisicos": ["tensão geral", "fadiga"],
      "mentais": ["sensação de não dar conta", "querer desligar", "dificuldade de priorizar"],
      "gatilhos": ["muitas demandas simultâneas", "crises financeiras", "cuidados com outros"],
      "duracaoTipica": "dias–semanas",
      "risco": ["abandono de responsabilidades", "choro frequente"]
    },
    "micro": [
      { "id": "22222222-2222-2222-2222-222222222221", "title": "Desapegar de uma tarefa hoje", "detail": "Olhe para a sua lista e escolha uma tarefa para riscar ou adiar hoje. Sinta o alívio de simplificar.", "duration": 5, "category": "organizacao", "isRich": true },
      { "id": "22222222-2222-2222-2222-222222222222", "title": "Quebrar a tarefa em 3 mini-passos", "detail": "Pegue aquela tarefa que parece enorme e escreva três passos bem pequenininhos para começar.", "duration": 5, "category": "organizacao", "isRich": true },
      { "id": "22222222-2222-2222-2222-222222222223", "title": "Beber um copo d'água com calma", "detail": "Tome um copo d'água devagar e olhe pela janela por dois minutos, descansando a vista.", "duration": 3, "category": "auto_cuidado", "isRich": false }
    ],
    "altoImpacto": [
      { "id": "22222222-2222-2222-2222-222222222224", "title": "Definir a prioridade principal", "detail": "Separe suas tarefas entre urgentes e secundárias. Foque apenas no que realmente precisa de atenção hoje.", "duration": 20, "category": "organizacao", "isRich": true },
      { "id": "22222222-2222-2222-2222-222222222225", "title": "Passar adiante ou adiar uma pendência", "detail": "Escolha uma tarefa para passar para outra pessoa ou deixar para a semana que vem, aliviando o seu dia.", "duration": 15, "category": "problem_solving", "isRich": true },
      { "id": "22222222-2222-2222-2222-222222222226", "title": "Caminhada rápida para desanuviar", "detail": "Dê uma volta de 15 minutos ao ar livre, no seu ritmo e sem olhar para o celular.", "duration": 15, "category": "movimento", "isRich": false }
    ],
    "copyWhy": [
      "Limpar algumas tarefas da sua lista ajuda a tirar o peso das costas e devolve a sensação de controle.",
      "Organizar o dia com foco no que realmente importa ajuda a diminuir o barulho mental e a sobrecarga."
    ]
  },
  {
    "cluster": "irritado",
    "signals": {
      "fisicos": ["mandíbula travada", "calor no corpo"],
      "mentais": ["impaciência", "explosões pequenas"],
      "gatilhos": ["trânsito", "frustrações repetidas", "falta de sono"],
      "duracaoTipica": "minutos–horas",
      "risco": ["agressões verbais/físicas"]
    },
    "micro": [
      { "id": "33333333-3333-3333-3333-333333333331", "title": "Mudar de ambiente por uns instantes", "detail": "Mude de cômodo e observe três objetos simples ao seu redor para trazer a mente de volta ao presente.", "duration": 4, "category": "grounding", "isRich": true },
      { "id": "33333333-3333-3333-3333-333333333332", "title": "Refrescar o rosto e respirar", "detail": "Lave as mãos ou o rosto com água fria e faça três respirações profundas para dar um respiro à mente.", "duration": 3, "category": "dbt", "isRich": true },
      { "id": "33333333-3333-3333-3333-333333333333", "title": "Anotar desabafos em um rascunho", "detail": "Se estiver no impulso de responder algo, escreva em um papel tudo o que quer evitar dizer em público.", "duration": 2, "category": "distress_tolerance", "isRich": true }
    ],
    "altoImpacto": [
      { "id": "33333333-3333-3333-3333-333333333334", "title": "Fazer um respiro consciente (STOP)", "detail": "Pare por um instante, respire fundo, observe seus sentimentos e depois decida o que fazer com calma.", "duration": 10, "category": "dbt", "isRich": true },
      { "id": "33333333-3333-3333-3333-333333333335", "title": "Alongamento firme para soltar a tensão", "detail": "Faça um alongamento um pouco mais firme ou caminhe num ritmo ativo para descarregar a tensão física.", "duration": 15, "category": "movimento", "isRich": false },
      { "id": "33333333-3333-3333-3333-333333333336", "title": "Escrever rascunho de conversa difícil", "detail": "Escreva o que você gostaria de falar naquela conversa difícil, mas guarde apenas como rascunho por enquanto.", "duration": 12, "category": "relacionamento", "isRich": true, "areaTag": "relacao" }
    ],
    "copyWhy": [
      "Trazer a mente de volta para o presente acalma os impulsos e te dá um respiro para decidir o que fazer com calma."
    ]
  },
  {
    "cluster": "triste",
    "signals": {
      "fisicos": ["peso no peito", "baixa energia"],
      "mentais": ["choro fácil", "visão pessimista", "isolamento"],
      "gatilhos": ["perdas", "rejeições", "solidão"],
      "duracaoTipica": "horas–dias",
      "risco": ["ideação de morte", "isolamento extremo"]
    },
    "micro": [
      { "id": "44444444-4444-4444-4444-444444444441", "title": "Mandar uma mensagem para um amigo", "detail": "Mande uma mensagem curta para alguém de confiança dividindo um pouco de como foi o seu dia.", "duration": 3, "category": "conexao", "isRich": true, "areaTag": "relacao" },
      { "id": "44444444-4444-4444-4444-444444444442", "title": "Ouvir sua música favorita", "detail": "Escolha uma música que combine com o seu estado de espírito e reserve quatro minutos para apenas ouvi-la.", "duration": 4, "category": "auto_cuidado", "isRich": false },
      { "id": "44444444-4444-4444-4444-444444444443", "title": "Um momento rápido de diversão", "detail": "Tire dois minutinhos para ver algo leve que te faça sorrir, como um meme ou um vídeo curto.", "duration": 2, "category": "behavioral_activation", "isRich": true, "valueTag": "conexao" }
    ],
    "altoImpacto": [
      { "id": "44444444-4444-4444-4444-444444444444", "title": "Fazer algo que te dê orgulho", "detail": "Dedique 15 a 20 minutos a uma atividade simples que se alinhe com o que você valoriza na vida.", "duration": 20, "category": "act_valor", "isRich": true },
      { "id": "44444444-4444-4444-4444-444444444445", "title": "Caminhada leve ouvindo música ou podcast", "detail": "Faça uma caminhada tranquila ouvindo uma música suave ou uma história leve.", "duration": 20, "category": "movimento", "isRich": false },
      { "id": "44444444-4444-4444-4444-444444444446", "title": "Terminar uma pequena pendência", "detail": "Termine uma tarefa bem simples que estava pendente para sentir aquela boa sensação de dever cumprido.", "duration": 15, "category": "behavioral_activation", "isRich": true }
    ],
    "copyWhy": [
      "Conversar com quem gostamos e concluir pequenas coisas ajuda a trazer um sentimento bom de acolhimento e capacidade.",
      "Agir em sintonia com o que você valoriza traz mais sentido ao seu dia e melhora o ânimo de forma leve."
    ]
  },
  {
    "cluster": "desmotivado",
    "signals": {
      "fisicos": ["corpo pesado"],
      "mentais": ["procrastinação", "sensação de tanto faz"],
      "gatilhos": ["falta de sentido no trabalho/curso", "fracassos seguidos"],
      "duracaoTipica": "dias",
      "risco": ["abandono de metas importantes"]
    },
    "micro": [
      { "id": "55555555-5555-5555-5555-555555555551", "title": "Focar em algo por apenas 2 minutos", "detail": "Escolha algo que queira começar e concorde em trabalhar nele por apenas dois minutos. O mais difícil é começar.", "duration": 2, "category": "behavioral_activation", "isRich": true },
      { "id": "55555555-5555-5555-5555-555555555552", "title": "Preparar a mesa ou o material para começar", "detail": "Prepare o ambiente ou abra os materiais para uma tarefa travada. Deixe tudo pronto para quando quiser agir.", "duration": 3, "category": "organizacao", "isRich": true },
      { "id": "55555555-5555-5555-5555-555555555553", "title": "Combinar um esforço curto com um agrado", "detail": "Faça um esforço focado de 5 minutos e se dê um agrado logo em seguida, como um café ou um descanso curto.", "duration": 7, "category": "motivacao", "isRich": true }
    ],
    "altoImpacto": [
      { "id": "55555555-5555-5555-5555-555555555554", "title": "Foco de 15 minutos sem distrações", "detail": "Coloque um cronômetro de 15 minutos e foque em uma tarefa importante, sem distrações até o alarme tocar.", "duration": 15, "category": "behavioral_activation", "isRich": true },
      { "id": "55555555-5555-5555-5555-555555555555", "title": "Anotar 3 coisas leves para fazer amanhã", "detail": "Escreva três coisas para amanhã: uma tarefa necessária, uma ligada a algo que você gosta e uma que dê prazer.", "duration": 15, "category": "organizacao", "isRich": true },
      { "id": "55555555-5555-5555-5555-555555555556", "title": "Lembrar por que essa tarefa é importante", "detail": "Reflita por um instante sobre a importância dessa tarefa para você e defina um passo simples para realizá-la.", "duration": 10, "category": "act_valor", "isRich": true }
    ],
    "copyWhy": [
      "Focar em uma tarefa por pouco tempo ajuda a vencer a preguiça e dar o primeiro passo.",
      "Alternar obrigações com momentos de prazer evita aquela sensação de cansaço e desânimo com a rotina."
    ]
  },
  {
    "cluster": "apatico",
    "signals": {
      "fisicos": ["baixa reatividade"],
      "mentais": ["sem interesse", "sem emoção"],
      "gatilhos": ["burnout", "estresse crônico"],
      "duracaoTipica": "semanas",
      "risco": ["dificuldade para tarefas básicas"]
    },
    "micro": [
      { "id": "66666666-6666-6666-6666-666666666661", "title": "Lavar o rosto ou arrumar a cama", "detail": "Faça um carinho simples em você ou no seu espaço: lave o rosto com água fresca ou arrume a sua cama.", "duration": 5, "category": "auto_cuidado", "isRich": true },
      { "id": "66666666-6666-6666-6666-666666666662", "title": "Beber água perto de uma janela", "detail": "Beba um bom copo d'água perto de uma janela ou na luz do dia para despertar o corpo e a mente.", "duration": 3, "category": "auto_cuidado", "isRich": false },
      { "id": "66666666-6666-6666-6666-666666666663", "title": "Arrumar um cantinho da bagunça", "detail": "Organize uma pequena coisa rápida, como levar o lixo para fora ou guardar alguns objetos fora do lugar.", "duration": 5, "category": "manutencao", "isRich": true }
    ],
    "altoImpacto": [
      { "id": "66666666-6666-6666-6666-666666666664", "title": "Arrumar a mesa de trabalho por 20 minutos", "detail": "Tire 20 minutos para arrumar e organizar aquele cantinho da bagunça que te incomoda diariamente.", "duration": 20, "category": "manutencao", "isRich": true },
      { "id": "66666666-6666-6666-6666-666666666665", "title": "Dedicar 10 minutos a algo valioso para você", "detail": "Dedique 10 minutos a algo que você gosta muito ou que considera importante para o seu crescimento.", "duration": 10, "category": "act_valor", "isRich": true },
      { "id": "66666666-6666-6666-6666-666666666666", "title": "Caminhada leve para esticar as pernas", "detail": "Faça uma caminhada leve ou um alongamento suave, sem nenhuma cobrança ou meta de desempenho.", "duration": 15, "category": "movimento", "isRich": false }
    ],
    "copyWhy": [
      "Fazer algo manual ajuda a movimentar o corpo e quebrar a inércia, sem que você precise se cobrar demais.",
      "Focar poucos minutos em algo que você ama ajuda a recuperar o ânimo e o sentido do dia."
    ]
  },
  {
    "cluster": "cansadoFisico",
    "signals": {
      "fisicos": ["sonolência", "dor no corpo"],
      "mentais": ["foco baixo", "irritabilidade leve"],
      "gatilhos": ["poucas horas de sono", "esforço físico"],
      "duracaoTipica": "1–2 dias",
      "risco": ["sonolência ao dirigir", "semanas seguidas"]
    },
    "micro": [
      { "id": "77777777-7777-7777-7777-777777777771", "title": "Cuidar das suas necessidades básicas", "detail": "Faça uma pausa rápida e pergunte-se: preciso comer, beber água ou ir ao banheiro? Cuide disso agora.", "duration": 4, "category": "auto_cuidado", "isRich": true },
      { "id": "77777777-7777-7777-7777-777777777772", "title": "Fechar os olhos por 5 minutos", "detail": "Feche os olhos ou olhe para a paisagem por 5 minutos, permitindo que a sua mente descanse do excesso de telas.", "duration": 5, "category": "sono", "isRich": false },
      { "id": "77777777-7777-7777-7777-777777777773", "title": "Alongamento rápido de 3 pontos", "detail": "Estique o pescoço, solte os ombros e relaxe a lombar, segurando cada posição por 30 segundos.", "duration": 3, "category": "movimento", "isRich": false }
    ],
    "altoImpacto": [
      { "id": "77777777-7777-7777-7777-777777777774", "title": "Mini cochilo revigorante", "detail": "Tire um cochilo rápido de 10 a 20 minutos com um despertador. Evite passar disso para não acordar cansado.", "duration": 15, "category": "sono", "isRich": false },
      { "id": "77777777-7777-7777-7777-777777777775", "title": "Desacelerar antes de dormir", "detail": "Prepare o seu sono: tome um banho morno e desligue as telas e luzes fortes meia hora antes de deitar.", "duration": 20, "category": "sono", "isRich": true },
      { "id": "77777777-7777-7777-7777-777777777776", "title": "Reduzir a lista de tarefas de amanhã", "detail": "Olhe para a agenda de amanhã, diminua a cobrança sobre você e garanta que terá pelo menos uma pausa marcada.", "duration": 10, "category": "organizacao", "isRich": true }
    ],
    "copyWhy": [
      "Cuidar das necessidades do corpo, como beber água ou comer algo leve, devolve a disposição num instante.",
      "Um sono de qualidade e contato com a luz do dia são os melhores remédios para combater a fadiga."
    ]
  },
  {
    "cluster": "cansadoMental",
    "signals": {
      "fisicos": ["cefaleia", "tensão ocular"],
      "mentais": ["saturação de informação", "brain fog"],
      "gatilhos": ["tela demais", "multitarefa", "redes sociais"],
      "duracaoTipica": "horas–1 dia",
      "risco": ["erros graves", "lapsos de atenção"]
    },
    "micro": [
      { "id": "88888888-8888-8888-8888-888888888881", "title": "Ficar 5 minutos longe de telas", "detail": "Fique 5 minutos sem olhar nenhuma tela, apenas respirando com calma e descansando os olhos.", "duration": 5, "category": "grounding", "isRich": false },
      { "id": "88888888-8888-8888-8888-888888888882", "title": "Fazer algo manual e offline", "detail": "Faça algo simples com as mãos e longe do celular, como regar uma planta ou organizar uma gaveta pequena.", "duration": 7, "category": "manutencao", "isRich": true },
      { "id": "88888888-8888-8888-8888-888888888883", "title": "Anotar o que consumiu sua energia hoje", "detail": "Anote três coisas ou aplicativos que consumiram muito da sua energia mental hoje para ficar de olho.", "duration": 3, "category": "organizacao", "isRich": true }
    ],
    "altoImpacto": [
      { "id": "88888888-8888-8888-8888-888888888884", "title": "Desconexão total offline por 20 minutos", "detail": "Tire 20 minutos de desconexão total: caminhe sem rumo, arrume uma gaveta ou folheie um livro físico.", "duration": 20, "category": "manutencao", "isRich": true },
      { "id": "88888888-8888-8888-8888-888888888885", "title": "Rascunhar o dia de amanhã no papel", "detail": "Anote em um papel físico três coisas importantes para o seu dia de amanhã, deixando os aplicativos de lado.", "duration": 10, "category": "organizacao", "isRich": true },
      { "id": "88888888-8888-8888-8888-888888888886", "title": "Respiração pausada e ritmada", "detail": "Faça 10 minutos de respiração pausada: inspire contando até cinco e expire contando até cinco.", "duration": 10, "category": "respiracao", "isRich": false }
    ],
    "copyWhy": [
      "Ficar longe do celular e movimentar o corpo alivia o cansaço mental causado pelo excesso de informação.",
      "Organizar o dia usando papel e caneta traz clareza para a mente sem os estímulos das telas."
    ]
  }
]
"""
    // swiftlint:enable line_length

    static let defaultPlaybook: [MoodCluster: MoodPlaybook] = {
        guard let data = embeddedPlaybookJSON.data(using: .utf8) else { return [:] }
        let decoder = JSONDecoder()
        if let items = try? decoder.decode([MoodPlaybook].self, from: data) {
            var dictionary = Dictionary(uniqueKeysWithValues: items.map { ($0.cluster, $0) })
            supplementalPlaybooks.forEach { dictionary[$0.cluster] = $0 }
            return dictionary
        }
        return Dictionary(uniqueKeysWithValues: supplementalPlaybooks.map { ($0.cluster, $0) })
    }()

    private static let supplementalPlaybooks: [MoodPlaybook] = [
        MoodPlaybook(
            cluster: .calmo,
            signals: MoodSignals(
                fisicos: ["respiração mais solta", "ombros menos tensos"],
                mentais: ["clareza suave", "menos ruído interno"],
                gatilhos: ["rotina organizada", "pausa recente", "ambiente estável"],
                duracaoTipica: "horas",
                risco: ["falsa sensação de que não precisa proteger esse estado"]
            ),
            micro: [
                action(id: "91000000-0000-0000-0000-000000000001", title: "Registrar o que está dando certo", detail: "Anote três coisas simples que deixaram o seu dia mais leve e agradável hoje.", duration: 3, category: "organizacao", isRich: true),
                action(id: "91000000-0000-0000-0000-000000000002", title: "Proteger a próxima hora", detail: "Escolha apenas uma prioridade tranquila para focar na próxima hora, sem pressa.", duration: 5, category: "organizacao", isRich: true),
                action(id: "91000000-0000-0000-0000-000000000003", title: "Respiração pausada de 4 minutos", detail: "Feche os olhos por quatro minutos e respire devagar para manter esse ritmo bom.", duration: 4, category: "respiracao", isRich: false)
            ],
            altoImpacto: [
                action(id: "91000000-0000-0000-0000-000000000004", title: "Momento de foco tranquilo", detail: "Dedique 20 minutos a uma atividade importante, trabalhando com calma e sem interrupções.", duration: 20, category: "behavioral_activation", isRich: true, areaTag: "trabalho"),
                action(id: "91000000-0000-0000-0000-000000000005", title: "Preparar o fim do dia", detail: "Organize o ambiente e deixe tudo pronto para a sua noite ser tranquila e sem pendências.", duration: 15, category: "organizacao", isRich: true),
                action(id: "91000000-0000-0000-0000-000000000006", title: "Ajustar um cantinho acolhedor", detail: "Organize ou limpe o espaço físico que mais ajuda você a se sentir em paz.", duration: 15, category: "manutencao", isRich: true)
            ],
            copyWhy: [
                "Como o seu momento está mais calmo, vale a pena usar essa clareza para planejar o restante do dia com tranquilidade.",
                "Quando estamos em paz, pequenas decisões tomadas com calma costumam render excelentes frutos."
            ]
        ),
        MoodPlaybook(
            cluster: .feliz,
            signals: MoodSignals(
                fisicos: ["rosto mais leve", "mais disposição para contato"],
                mentais: ["mais abertura", "mais presença"],
                gatilhos: ["boas notícias", "conexão", "sensação de progresso"],
                duracaoTipica: "horas",
                risco: ["gastar toda a energia sem intenção"]
            ),
            micro: [
                action(id: "92000000-0000-0000-0000-000000000001", title: "Dividir uma alegria curta", detail: "Mande uma mensagem rápida para alguém querido contando algo legal do seu dia.", duration: 3, category: "conexao", isRich: true, areaTag: "relacao"),
                action(id: "92000000-0000-0000-0000-000000000002", title: "Agradecimento rápido", detail: "Lembre-se de três coisas simples pelas quais você se sente grato hoje.", duration: 3, category: "gratidao", isRich: true),
                action(id: "92000000-0000-0000-0000-000000000003", title: "Aproveitar o embalo para resolver algo", detail: "Use a leveza deste momento para terminar uma tarefa simples de forma rápida.", duration: 5, category: "behavioral_activation", isRich: true)
            ],
            altoImpacto: [
                action(id: "92000000-0000-0000-0000-000000000004", title: "Reconhecer seu progresso", detail: "Tire 15 minutos para valorizar o que você já conquistou, sem correr direto para a próxima cobrança.", duration: 15, category: "motivacao", isRich: true),
                action(id: "92000000-0000-0000-0000-000000000005", title: "Avanço importante no embalo bom", detail: "Use essa energia para mover uma frente que importa para você.", duration: 20, category: "behavioral_activation", isRich: true, areaTag: "trabalho"),
                action(id: "92000000-0000-0000-0000-000000000006", title: "Conectar-se com alguém querido", detail: "Marque ou faça um contato curto com alguém seguro.", duration: 15, category: "conexao", isRich: true, areaTag: "relacao")
            ],
            copyWhy: [
                "Aproveite que o seu astral está bom para espalhar essa energia positiva e fortalecer conexões.",
                "Momentos bons costumam render ainda mais quando viram memória de avanço real."
            ]
        ),
        MoodPlaybook(
            cluster: .energizado,
            signals: MoodSignals(
                fisicos: ["mais impulso", "corpo ligado"],
                mentais: ["vontade de agir", "mais iniciativa"],
                gatilhos: ["boa notícia", "descanso", "senso de oportunidade"],
                duracaoTipica: "horas",
                risco: ["dispersão", "assumir coisa demais"]
            ),
            micro: [
                action(id: "93000000-0000-0000-0000-000000000001", title: "Canalizar sua energia", detail: "Escolha um único objetivo para a próxima hora e direcione sua disposição para ele.", duration: 4, category: "behavioral_activation", isRich: true),
                action(id: "93000000-0000-0000-0000-000000000002", title: "Uma pausa para respirar fundo", detail: "Faça um momento de pausa rápida para decidir o próximo passo antes de sair fazendo tudo ao mesmo tempo.", duration: 3, category: "grounding", isRich: true),
                action(id: "93000000-0000-0000-0000-000000000003", title: "Limpar as distrações ao redor", detail: "Silencie notificações e feche abas desnecessárias para manter o foco no que importa.", duration: 5, category: "organizacao", isRich: true)
            ],
            altoImpacto: [
                action(id: "93000000-0000-0000-0000-000000000004", title: "Foco intenso de 20 minutos", detail: "Dedique 20 minutos a uma tarefa importante, aproveitando seu pique máximo.", duration: 20, category: "behavioral_activation", isRich: true),
                action(id: "93000000-0000-0000-0000-000000000005", title: "Alongar e movimentar o corpo", detail: "Faça uma caminhada ativa ou alongamentos para usar essa disposição física de forma saudável.", duration: 15, category: "movimento", isRich: false),
                action(id: "93000000-0000-0000-0000-000000000006", title: "Proteger seu momento produtivo", detail: "Garanta que você terá tempo reservado hoje para focar na sua tarefa mais importante.", duration: 10, category: "organizacao", isRich: true)
            ],
            copyWhy: [
                "Com a energia em alta, o ideal é dar uma direção clara para evitar a sensação de dispersão.",
                "Sua disposição está excelente! Vamos aproveitar para avançar com foco no que realmente importa."
            ]
        ),
        MoodPlaybook(
            cluster: .focado,
            signals: MoodSignals(
                fisicos: ["corpo estável", "respiração mais regular"],
                mentais: ["clareza alta", "atenção mais firme"],
                gatilhos: ["boa organização", "menos interrupção", "objetivo claro"],
                duracaoTipica: "1–3 horas",
                risco: ["passar do ponto e esquecer pausas"]
            ),
            micro: [
                action(id: "94000000-0000-0000-0000-000000000001", title: "Concluir uma etapa importante", detail: "Aproveite os próximos 5 minutos para fechar a parte mais urgente que está aberto.", duration: 5, category: "behavioral_activation", isRich: true, areaTag: "trabalho"),
                action(id: "94000000-0000-0000-0000-000000000002", title: "Anotar o próximo passo simples", detail: "Antes de fazer uma pausa, anote qual será o próximo mini-passo para facilitar a volta.", duration: 3, category: "organizacao", isRich: true),
                action(id: "94000000-0000-0000-0000-000000000003", title: "Blindar seu tempo de trabalho", detail: "Silencie o celular e avise as pessoas para proteger essa ótima janela de foco.", duration: 4, category: "organizacao", isRich: true)
            ],
            altoImpacto: [
                action(id: "94000000-0000-0000-0000-000000000004", title: "Trabalho profundo de 20 minutos", detail: "Foque por 20 minutos em uma única atividade que fará a maior diferença no seu dia.", duration: 20, category: "behavioral_activation", isRich: true, areaTag: "trabalho"),
                action(id: "94000000-0000-0000-0000-000000000005", title: "Organizar o progresso recente", detail: "Registre o que você já fez e defina a próxima meta enquanto sua mente está bem clara.", duration: 12, category: "organizacao", isRich: true),
                action(id: "94000000-0000-0000-0000-000000000006", title: "Fazer uma revisão de encerramento", detail: "Faça um checklist rápido de 10 minutos para garantir que não restaram pendências invisíveis.", duration: 10, category: "organizacao", isRich: true)
            ],
            copyWhy: [
                "Você está numa boa faixa de clareza agora, então vale proteger isso para render de verdade.",
                "Em momentos de foco, a melhor ação costuma ser a que transforma clareza em avanço concreto."
            ]
        ),
        MoodPlaybook(
            cluster: .estressado,
            signals: MoodSignals(
                fisicos: ["tensão no pescoço", "respiração curta", "pressão no corpo"],
                mentais: ["urgência demais", "muita cobrança ao mesmo tempo"],
                gatilhos: ["muitas interrupções", "pressão externa", "prazos"],
                duracaoTipica: "horas",
                risco: ["agir no impulso", "espalhar a tensão no resto do dia"]
            ),
            micro: [
                action(id: "95000000-0000-0000-0000-000000000001", title: "Respiração lenta com ombros soltos", detail: "Inspire devagar e solte o ar soprando suavemente, relaxando os ombros a cada ciclo.", duration: 4, category: "respiracao", isRich: false),
                action(id: "95000000-0000-0000-0000-000000000002", title: "Limpar a mesa de trabalho", detail: "Organize ou guarde papéis e objetos ao seu redor para diminuir a bagunça visual.", duration: 5, category: "organizacao", isRich: true),
                action(id: "95000000-0000-0000-0000-000000000003", title: "Nomear o que está pesando", detail: "Escreva em um papel, de forma simples, o que mais está preocupando você neste momento.", duration: 3, category: "organizacao", isRich: true)
            ],
            altoImpacto: [
                action(id: "95000000-0000-0000-0000-000000000004", title: "Caminhada tranquila para respirar", detail: "Caminhe calmamente por 15 a 20 minutos, soltando o ar bem devagar para acalmar o corpo.", duration: 20, category: "movimento", isRich: false),
                action(id: "95000000-0000-0000-0000-000000000005", title: "Pausa em silêncio com água fresca", detail: "Tome um copo d'água devagar, sente-se em um lugar silencioso e respire sem cobranças.", duration: 12, category: "auto_cuidado", isRich: true),
                action(id: "95000000-0000-0000-0000-000000000006", title: "Definir prioridades para as próximas horas", detail: "Decida o que você realmente precisa fazer hoje, o que pode adiar e o que vai ignorar por enquanto.", duration: 15, category: "organizacao", isRich: true)
            ],
            copyWhy: [
                "Seu corpo e sua mente estão pedindo um respiro. Vamos baixar a pressão antes de exigir mais esforço.",
                "Quando o estresse sobe, reduzir o ruído e dar direção clara costuma funcionar melhor do que insistir na força."
            ]
        )
    ]

    private static func action(
        id: String,
        title: String,
        detail: String,
        duration: Int,
        category: String,
        cautions: [String] = [],
        isRich: Bool,
        valueTag: String? = nil,
        areaTag: String? = nil
    ) -> ActionVariant {
        ActionVariant(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            detail: detail,
            duration: duration,
            category: category,
            cautions: cautions,
            isRich: isRich,
            valueTag: valueTag,
            areaTag: areaTag
        )
    }
}

// MARK: - Helpers

extension MoodType {
    var cluster: MoodCluster {
        switch self {
        case .calm: return .calmo
        case .happy: return .feliz
        case .energetic: return .energizado
        case .stressed: return .estressado
        case .sad: return .triste
        case .tired: return .cansadoFisico
        }
    }
}

struct PatternSignal: Equatable, Sendable {
    let key: String
    let impact: Double
    let recurrence: Double
    let confidence: Double
    let controllability: Double
    let detail: String
    let suggestedFocus: String
}

enum ActionSuggestionCategory: String, Codable, Hashable, Sendable {
    case execution
    case recovery
    case planning
    case communication
    case movement
}

extension NextBestActionKind {
    var category: ActionSuggestionCategory {
        switch self {
        case .resolveAvoidedTask,
                .firstStepActivation,
                .solveOneProblem,
                .finishSmallWin,
                .timerSprint:
            return .execution
        case .difficultMessage,
                .safeDraft,
                .supportMessage,
                .shareGoodMoment:
            return .communication
        case .weeklyPlanning,
                .mentalUnload,
                .scopeReduction,
                .taskBreakdown,
                .delegateOneThing,
                .paperPlanning,
                .protectPeakWindow,
                .frictionCleanup,
                .valueReconnect,
                .gratitudeMoment,
                .celebrationBreak:
            return .planning
        case .quickExercise,
                .walkingRegulation,
                .softStretch,
                .physicalDischarge:
            return .movement
        case .sleepReset,
                .breathReset,
                .sensoryPause,
                .sceneShift,
                .coolDownReset,
                .environmentReset,
                .mechanicalCare,
                .hydrationReset,
                .microRest,
                .analogReset,
                .bodyScan,
                .deepDisconnect,
                .pleasureBoost:
            return .recovery
        }
    }
}

struct BehaviorPatternIndicators: Equatable, Sendable {
    let dominantNegativeTrigger: String?
    let bestWeekday: Int?
    let worstWeekday: Int?
    let bestPeriod: BehaviorDayPeriod?
    let worstPeriod: BehaviorDayPeriod?
    let recentDeclineDays: Int
    let hasSleepImpact: Bool
    let hasEmotionalProcrastination: Bool
    let hasHabitCorrelation: Bool
    let lowClarityDays: Int
    let highStressDays: Int
}

struct BehaviorPatternAnalysis: Equatable, Sendable {
    let weeklyTrend: WeeklyEmotionalTrend
    let indicators: BehaviorPatternIndicators
    let signals: [PatternSignal]
    let primaryAlert: PatternAlert?
}

struct ActionHistorySummary: Equatable, Sendable {
    let lastSuggestedAt: [NextBestActionKind: Date]
    let lastSuggestedAtByActionKey: [String: Date]
    let recentSuggestedKinds: [NextBestActionKind]
    let recentSuggestedActionKeys: [String]
    let suggestedCategoryCountsLast7Days: [ActionSuggestionCategory: Int]
    let startedCountByKind: [NextBestActionKind: Int]
    let completionRateByKind: [NextBestActionKind: Double]
    let reliefAverageByKind: [NextBestActionKind: Double]

    nonisolated static let empty = ActionHistorySummary(
        lastSuggestedAt: [:],
        lastSuggestedAtByActionKey: [:],
        recentSuggestedKinds: [],
        recentSuggestedActionKeys: [],
        suggestedCategoryCountsLast7Days: [:],
        startedCountByKind: [:],
        completionRateByKind: [:],
        reliefAverageByKind: [:]
    )
}
