//
//  BehaviorModels.swift
//  Venus
//
//  Created by Codex on 20/02/26.
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
    let stage: ActionFeedbackStage
    let perceivedRelief: Int?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        kind: NextBestActionKind,
        stage: ActionFeedbackStage,
        perceivedRelief: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.stage = stage
        self.perceivedRelief = perceivedRelief
    }
}

struct BehaviorActionFeedbackEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let dayKey: Date
    let kind: NextBestActionKind
    let stage: ActionFeedbackStage
    let perceivedRelief: Int?

    nonisolated static func == (lhs: BehaviorActionFeedbackEvent, rhs: BehaviorActionFeedbackEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.timestamp == rhs.timestamp
            && lhs.dayKey == rhs.dayKey
            && lhs.kind == rhs.kind
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
        if context.moderators.riscoAlto { return nil }
        guard let base = playbook[context.mood] else { return nil }

        let tempo = context.moderators.tempoMinutos ?? 10
        let pool: [ActionVariant]
        if tempo <= 7 {
            pool = base.micro
        } else if tempo <= 15 {
            pool = base.micro + base.altoImpacto.filter { $0.duration <= 15 }
        } else {
            pool = base.altoImpacto
        }

        let filtered = pool.filter { action in
            if let energia = context.moderators.energia, energia == "baixa",
               action.category == "movimento", action.duration > 15 { return false }
            if let controle = context.moderators.controle, controle == "baixo",
               action.category == "organizacao", action.duration > 15 { return false }
            return true
        }

        var scored: [(ActionVariant, Int)] = filtered.map { ($0, 0) }
        for index in scored.indices {
            var score = scored[index].1
            let action = scored[index].0

            if let area = context.area, let tag = action.areaTag, tag == area { score += 2 }
            if let value = context.valuePriority, let vTag = action.valueTag, vTag == value { score += 2 }
            if action.isRich { score += 1 }
            if let last = context.lastActionCategory, last == action.category { score -= 1 }
            if let feedback = context.helpsHistory[action.id] { score += feedback }

            scored[index].1 = score
        }

        return scored.sorted { $0.1 > $1.1 }.first?.0
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
      { "id": "11111111-1111-1111-1111-111111111111", "title": "Respiração box 4-4-4", "detail": "3–5 min, contar 4-4-4, ritmo lento.", "duration": 5, "category": "respiracao", "cautions": ["evitar retenção longa se problema respiratório/cardiaco"], "isRich": false },
      { "id": "11111111-1111-1111-1111-111111111112", "title": "Mini passo da tarefa travada", "detail": "Abra o TODO e faça só o primeiro passo (ex.: abrir arquivo).", "duration": 5, "category": "organizacao", "cautions": [], "isRich": true, "areaTag": "trabalho" },
      { "id": "11111111-1111-1111-1111-111111111113", "title": "Brain dump de 3 minutos", "detail": "Liste tudo sem organizar; esvazie a cabeça.", "duration": 3, "category": "organizacao", "cautions": [], "isRich": true }
    ],
    "altoImpacto": [
      { "id": "11111111-1111-1111-1111-111111111114", "title": "Resolver um problema (PST light)", "detail": "1 frase do problema, 3 soluções, escolha 1 e planeje hoje.", "duration": 20, "category": "problem_solving", "cautions": [], "isRich": true, "areaTag": "trabalho" },
      { "id": "11111111-1111-1111-1111-111111111115", "title": "Caminhada + expiração longa", "detail": "20 min andando, expira 2x mais longo que inspira.", "duration": 20, "category": "movimento", "cautions": ["evitar HIIT se muito ativado"], "isRich": false },
      { "id": "11111111-1111-1111-1111-111111111116", "title": "Revisão de amanhã (anti-caos)", "detail": "Escolha 3 prioridades + 1 coisa que NÃO fará.", "duration": 15, "category": "organizacao", "isRich": true }
    ],
    "copyWhy": [
      "Sugerimos respiração porque você relatou tensão no corpo.",
      "Propusemos resolver 1 passo do trabalho para reduzir pressão imediata."
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
      { "id": "22222222-2222-2222-2222-222222222221", "title": "Escolher o que sai da lista", "detail": "Remova 1 tarefa do dia sem culpa.", "duration": 5, "category": "organizacao", "isRich": true },
      { "id": "22222222-2222-2222-2222-222222222222", "title": "Dividir tarefa gigante em 3 passos", "detail": "Escreva só 3 subpassos simples.", "duration": 5, "category": "organizacao", "isRich": true },
      { "id": "22222222-2222-2222-2222-222222222223", "title": "Água + pausa sensorial", "detail": "Beber água e olhar para longe 2 min.", "duration": 3, "category": "auto_cuidado", "isRich": false }
    ],
    "altoImpacto": [
      { "id": "22222222-2222-2222-2222-222222222224", "title": "Sessão de priorização 20 min", "detail": "Marque A/B/C; mantenha só A hoje.", "duration": 20, "category": "organizacao", "isRich": true },
      { "id": "22222222-2222-2222-2222-222222222225", "title": "Delegar ou adiar 1 item", "detail": "Escolha algo para delegar/adiar conscientemente.", "duration": 15, "category": "problem_solving", "isRich": true },
      { "id": "22222222-2222-2222-2222-222222222226", "title": "Caminhada descarrego", "detail": "15 min ritmo moderado, longe de telas.", "duration": 15, "category": "movimento", "isRich": false }
    ],
    "copyWhy": [
      "Remover itens reduz carga percebida e devolve controle.",
      "Priorizar A/B/C corta ruído e baixa sobrecarga."
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
      { "id": "33333333-3333-3333-3333-333333333331", "title": "Mudança de cena dirigida", "detail": "Vá para outro cômodo, note 3 coisas da mesma cor.", "duration": 4, "category": "grounding", "isRich": true },
      { "id": "33333333-3333-3333-3333-333333333332", "title": "Água fria nas mãos + 3 respirações", "detail": "DBT TIPP light para baixar ativação.", "duration": 3, "category": "dbt", "isRich": true },
      { "id": "33333333-3333-3333-3333-333333333333", "title": "Escrever o que NÃO vai dizer", "detail": "1 frase que quer evitar falar no impulso.", "duration": 2, "category": "distress_tolerance", "isRich": true }
    ],
    "altoImpacto": [
      { "id": "33333333-3333-3333-3333-333333333334", "title": "STOP guiado", "detail": "Stop, Tomar ar, Observar, Proceder com intenção.", "duration": 10, "category": "dbt", "isRich": true },
      { "id": "33333333-3333-3333-3333-333333333335", "title": "Descarga física segura", "detail": "10–15 min caminhada vigorosa ou alongamento forte.", "duration": 15, "category": "movimento", "isRich": false },
      { "id": "33333333-3333-3333-3333-333333333336", "title": "Rascunho de conversa difícil", "detail": "Escreva e salve; não enviar agora.", "duration": 12, "category": "relacionamento", "isRich": true, "areaTag": "relacao" }
    ],
    "copyWhy": [
      "Grounding reduz impulso; STOP dá intervalo para escolher resposta."
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
      { "id": "44444444-4444-4444-4444-444444444441", "title": "Mensagem curta para alguém seguro", "detail": "Envie 1 frase começando com “Hoje eu me senti…”", "duration": 3, "category": "conexao", "isRich": true, "areaTag": "relacao" },
      { "id": "44444444-4444-4444-4444-444444444442", "title": "Música-medicina", "detail": "Ouça 1 faixa que combina com o momento.", "duration": 4, "category": "auto_cuidado", "isRich": false },
      { "id": "44444444-4444-4444-4444-444444444443", "title": "Prazer mínimo conhecido", "detail": "2 min de algo que marcou como prazeroso (ex.: meme).", "duration": 2, "category": "behavioral_activation", "isRich": true, "valueTag": "conexao" }
    ],
    "altoImpacto": [
      { "id": "44444444-4444-4444-4444-444444444444", "title": "Bloco de valor (ACT)", "detail": "15–20 min em algo ligado a um valor escolhido.", "duration": 20, "category": "act_valor", "isRich": true },
      { "id": "44444444-4444-4444-4444-444444444445", "title": "Passeio leve com áudio", "detail": "20 min ao ar livre ouvindo algo que acalme ou combine.", "duration": 20, "category": "movimento", "isRich": false },
      { "id": "44444444-4444-4444-4444-444444444446", "title": "Finalizar algo pequeno", "detail": "Concluir uma parte de um projeto para senso de domínio.", "duration": 15, "category": "behavioral_activation", "isRich": true }
    ],
    "copyWhy": [
      "Conexão e pequenas vitórias elevam prazer/domínio.",
      "Ação baseada em valor alinha humor e propósito."
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
      { "id": "55555555-5555-5555-5555-555555555551", "title": "Pegar impulso de 2 min", "detail": "Trabalhe 2 min em algo que importa (valor).", "duration": 2, "category": "behavioral_activation", "isRich": true },
      { "id": "55555555-5555-5555-5555-555555555552", "title": "Primeiro tijolo", "detail": "Escolha 1 tarefa travada e faça só o setup.", "duration": 3, "category": "organizacao", "isRich": true },
      { "id": "55555555-5555-5555-5555-555555555553", "title": "Micro-recompensa", "detail": "Combine 5 min de esforço + 2 min de algo gostoso.", "duration": 7, "category": "motivacao", "isRich": true }
    ],
    "altoImpacto": [
      { "id": "55555555-5555-5555-5555-555555555554", "title": "Sprint de 15 min (timebox)", "detail": "Timer 15 min; tarefa ligada a valor.", "duration": 15, "category": "behavioral_activation", "isRich": true },
      { "id": "55555555-5555-5555-5555-555555555555", "title": "Planejar 3 ações amanhã", "detail": "1 obrigatória, 1 de valor, 1 de prazer.", "duration": 15, "category": "organizacao", "isRich": true },
      { "id": "55555555-5555-5555-5555-555555555556", "title": "Reconectar com valor", "detail": "Escreva 3 linhas sobre por que importa e 1 passo.", "duration": 10, "category": "act_valor", "isRich": true }
    ],
    "copyWhy": [
      "Tempo curto + valor aumenta chance de começar.",
      "Misturar obrigação + prazer evita ‘tanto faz’."
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
      { "id": "66666666-6666-6666-6666-666666666661", "title": "Autocuidado mecânico", "detail": "Trocar roupa de cama ou lavar rosto.", "duration": 5, "category": "auto_cuidado", "isRich": true },
      { "id": "66666666-6666-6666-6666-666666666662", "title": "Hidratar + luz", "detail": "Beber água e 2 min em luz natural.", "duration": 3, "category": "auto_cuidado", "isRich": false },
      { "id": "66666666-6666-6666-6666-666666666663", "title": "Tarefa de manutenção", "detail": "Rodar lavadora ou tirar lixo.", "duration": 5, "category": "manutencao", "isRich": true }
    ],
    "altoImpacto": [
      { "id": "66666666-6666-6666-6666-666666666664", "title": "Bloco mecânico com sentido", "detail": "20 min arrumando espaço que atrapalha todo dia.", "duration": 20, "category": "manutencao", "isRich": true },
      { "id": "66666666-6666-6666-6666-666666666665", "title": "Valor mínimo", "detail": "10 min em algo simples ligado a um valor.", "duration": 10, "category": "act_valor", "isRich": true },
      { "id": "66666666-6666-6666-6666-666666666666", "title": "Ativação física suave", "detail": "15 min alongar/passear devagar, sem meta.", "duration": 15, "category": "movimento", "isRich": false }
    ],
    "copyWhy": [
      "Ação mecânica quebra inércia sem exigir emoção.",
      "Valor mínimo reinicia senso de propósito."
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
      { "id": "77777777-7777-7777-7777-777777777771", "title": "Checagem básica", "detail": "Comeu? Bebeu água? Banheiro? Resolva 1 agora.", "duration": 4, "category": "auto_cuidado", "isRich": true },
      { "id": "77777777-7777-7777-7777-777777777772", "title": "Microdescanso sem tela", "detail": "5 min olhos fechados ou olhar janela.", "duration": 5, "category": "sono", "isRich": false },
      { "id": "77777777-7777-7777-7777-777777777773", "title": "Alongar 3 pontos", "detail": "Pescoço, ombros, lombar (30s cada).", "duration": 3, "category": "movimento", "isRich": false }
    ],
    "altoImpacto": [
      { "id": "77777777-7777-7777-7777-777777777774", "title": "Soneca curta", "detail": "10–20 min, alarme; evitar >20 min.", "duration": 15, "category": "sono", "isRich": false },
      { "id": "77777777-7777-7777-7777-777777777775", "title": "Ritual de sono hoje", "detail": "Banho morno, reduzir luz/tela 30 min antes.", "duration": 20, "category": "sono", "isRich": true },
      { "id": "77777777-7777-7777-7777-777777777776", "title": "Planejar amanhã leve", "detail": "Rebaixar expectativas, bloquear 1 pausa.", "duration": 10, "category": "organizacao", "isRich": true }
    ],
    "copyWhy": [
      "Resolver necessidades básicas melhora energia rapidamente.",
      "Sono e luz controlam o ciclo e reduzem fadiga."
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
      { "id": "88888888-8888-8888-8888-888888888881", "title": "5 min sem telas", "detail": "Olhar longe, respirar diafragmaticamente.", "duration": 5, "category": "grounding", "isRich": false },
      { "id": "88888888-8888-8888-8888-888888888882", "title": "Atividade analógica", "detail": "Regar planta, arrumar 1 microespaço.", "duration": 7, "category": "manutencao", "isRich": true },
      { "id": "88888888-8888-8888-8888-888888888883", "title": "Anotar o que drena", "detail": "Liste 3 apps ou tarefas que drenaram hoje.", "duration": 3, "category": "organizacao", "isRich": true }
    ],
    "altoImpacto": [
      { "id": "88888888-8888-8888-8888-888888888884", "title": "Reset mental offline", "detail": "20 min sem telas: caminhar ou arrumar gaveta.", "duration": 20, "category": "manutencao", "isRich": true },
      { "id": "88888888-8888-8888-8888-888888888885", "title": "Planejar amanhã em papel", "detail": "3 ações em papel; sem apps.", "duration": 10, "category": "organizacao", "isRich": true },
      { "id": "88888888-8888-8888-8888-888888888886", "title": "Respiração coerente 6 cpm", "detail": "10 min (in 5s, out 5s).", "duration": 10, "category": "respiracao", "isRich": false }
    ],
    "copyWhy": [
      "Reduzir tela e fazer algo físico baixa overload.",
      "Papel e organização offline clareiam mente saturada."
    ]
  }
]
"""
    // swiftlint:enable line_length

    static let defaultPlaybook: [MoodCluster: MoodPlaybook] = {
        guard let data = embeddedPlaybookJSON.data(using: .utf8) else { return [:] }
        let decoder = JSONDecoder()
        if let items = try? decoder.decode([MoodPlaybook].self, from: data) {
            return Dictionary(uniqueKeysWithValues: items.map { ($0.cluster, $0) })
        }
        return [:]
    }()
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
        case .resolveAvoidedTask:
            return .execution
        case .sleepReset:
            return .recovery
        case .environmentReset:
            return .recovery
        case .quickExercise:
            return .movement
        case .difficultMessage:
            return .communication
        case .deepDisconnect:
            return .recovery
        case .weeklyPlanning:
            return .planning
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
    let recentSuggestedKinds: [NextBestActionKind]
    let suggestedCategoryCountsLast7Days: [ActionSuggestionCategory: Int]
    let startedCountByKind: [NextBestActionKind: Int]
    let completionRateByKind: [NextBestActionKind: Double]
    let reliefAverageByKind: [NextBestActionKind: Double]

    nonisolated static let empty = ActionHistorySummary(
        lastSuggestedAt: [:],
        recentSuggestedKinds: [],
        suggestedCategoryCountsLast7Days: [:],
        startedCountByKind: [:],
        completionRateByKind: [:],
        reliefAverageByKind: [:]
    )
}
