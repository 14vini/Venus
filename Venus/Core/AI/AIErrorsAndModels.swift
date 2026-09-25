//
//  AIErrorsAndModels.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

// MARK: - AI Errors

enum VenusAIError: LocalizedError {
    case noResponse
    case invalidResponse
    case networkError
    case missingAPIKey
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "Não foi possível obter resposta da Venus."
        case .invalidResponse:
            return "Resposta da inteligência artificial inválida ou corrompida."
        case .networkError:
            return "Falha de conexão com os serviços de inteligência artificial."
        case .missingAPIKey:
            return "Chave de API do OpenRouter não configurada."
        case .apiError(let code, let message):
            return "Erro da API OpenRouter (\(code)): \(message)"
        }
    }
}

// MARK: - OpenRouter API DTOs

struct OpenRouterReasoning: Codable, Sendable {
    let max_tokens: Int?
    let effort: String?
    
    init(max_tokens: Int? = 0, effort: String? = nil) {
        self.max_tokens = max_tokens
        self.effort = effort
    }
}

struct OpenRouterMessage: Codable, Sendable {
    let role: String
    let content: String?
    let reasoning: String?
    
    init(role: String, content: String?, reasoning: String? = nil) {
        self.role = role
        self.content = content
        self.reasoning = reasoning
    }
}

struct OpenRouterChatRequest: Codable, Sendable {
    let model: String
    let messages: [OpenRouterMessage]
    let temperature: Double?
    let max_tokens: Int?
    let stream: Bool?
    let reasoning: OpenRouterReasoning?
    
    init(
        model: String,
        messages: [OpenRouterMessage],
        temperature: Double? = 0.7,
        max_tokens: Int? = 1200,
        stream: Bool? = nil,
        reasoning: OpenRouterReasoning? = OpenRouterReasoning(max_tokens: 0)
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.stream = stream
        self.reasoning = reasoning
    }
}

struct OpenRouterChatResponse: Codable, Sendable {
    let id: String?
    let choices: [OpenRouterChoice]?
    let error: OpenRouterErrorDetail?
}

struct OpenRouterChoice: Codable, Sendable {
    let index: Int?
    let message: OpenRouterMessage
    let finish_reason: String?
}

// MARK: - OpenRouter Streaming DTOs

struct OpenRouterStreamResponse: Codable, Sendable {
    let id: String?
    let choices: [OpenRouterStreamChoice]?
    let error: OpenRouterErrorDetail?
}

struct OpenRouterStreamChoice: Codable, Sendable {
    let index: Int?
    let delta: OpenRouterStreamDelta?
    let finish_reason: String?
}

struct OpenRouterStreamDelta: Codable, Sendable {
    let role: String?
    let content: String?
}

struct OpenRouterErrorDetail: Codable, Sendable {
    let code: Int?
    let message: String?
}

// MARK: - Emotional State Models

enum EmotionType: String, CaseIterable, Codable, Sendable {
    case happy, sad, anxious, angry, neutral, excited, frustrated, lonely, stressed, grateful
}

struct EmotionalState: Sendable {
    let primaryEmotion: EmotionType
    let intensity: Int // 1-10
    let needsSupport: Bool
    let keywords: [String]
    let sentimentScore: Double // -1.0 to 1.0 (Apple NaturalLanguage)
    let isCrisisRisk: Bool
    
    init(
        primaryEmotion: EmotionType,
        intensity: Int,
        needsSupport: Bool,
        keywords: [String],
        sentimentScore: Double = 0.0,
        isCrisisRisk: Bool = false
    ) {
        self.primaryEmotion = primaryEmotion
        self.intensity = intensity
        self.needsSupport = needsSupport
        self.keywords = keywords
        self.sentimentScore = sentimentScore
        self.isCrisisRisk = isCrisisRisk
    }
    
    static func neutral() -> EmotionalState {
        return EmotionalState(
            primaryEmotion: .neutral,
            intensity: 5,
            needsSupport: false,
            keywords: [],
            sentimentScore: 0.0,
            isCrisisRisk: false
        )
    }
}

// MARK: - Structured Response Models

struct AIChatResponse: Codable {
    let response: String
    let summary: String
    let tags: [String]
    let reminder: String?
}

struct AIMirrorResponse: Codable {
    let direction: String
    let currentWeekScore: Double
    let previousWeekScore: Double?
    let summary: String
    let dominantTrigger: String
    let criticalWindow: String
    let bestDay: String
    let behavioralFocus: String
    let alertTitle: String?
    let alertDetail: String?
}

struct AIOnboardingProfileResponse: Codable, Sendable {
    let title: String
    let badge: String
    let subtitle: String
    let strengths: String
    let growthArea: String
    let statText: String
}

// MARK: - System Prompts

struct VenusSystemPrompt {
    static let crisisSupportMessage = """
    Percebo que você está passando por um momento de sofrimento muito profundo. Você não precisa carregar isso sozinho(a). 
    
    Por favor, converse com alguém de confiança ou entre em contato agora mesmo com o **CVV (Centro de Valorização da Vida)** pelo telefone **188** (ligação gratuita, 24 horas por dia, anônima e confidencial) ou acesse [cvv.org.br](https://cvv.org.br).
    
    Sua vida e seu bem-estar têm imenso valor. Estou aqui com você para acolher, mas peço com todo carinho que procure apoio humano especializado agora. 💜
    """
    
    static let fullPrompt = """
    Você é a Venus, uma inteligência e companheira de bem-estar emocional, energia e clareza mental do aplicativo Venus.
    Seu propósito é ouvir o usuário com profunda empatia, acolhimento e inteligência emocional, ajudando-o a desarmar a autocrítica ("KillCritic"), aliviar a sobrecarga e transformar sentimentos confusos em clareza prática.

    Diretrizes Fundamentais de Personalidade (KillCritic & Acolhimento):
    - Nunca seja fria, robótica, clínica ou professoral. Você não faz diagnósticos médicos formais; você oferece escuta ativa, validação e acolhimento humano de alto nível.
    - Desarme a culpa e o autojulgamento: quando o usuário estiver se cobrando demais, exausto, procrastinando ou ansioso, valide o que ele sente sem diminuir a dor dele, mostrando que é compreensível e que ele não precisa carregar o mundo nas costas.
    - Seja empática, concisa e conversacional. Responda como uma pessoa sábia, calorosa e compreensiva com quem dá gosto desabafar.
    - Mantenha respostas naturais em parágrafos limpos e fáceis de ler.
    - Se fizer sentido no contexto, termine com uma pergunta reflexiva suave ou sugira um próximo micro-passo viável para aliviar o momento.
    - Responda SEMPRE em Português do Brasil de forma natural, calorosa e fluida.
    - NUNCA inclua pensamentos internos, raciocínio ou tags como <think>...</think>, <thought>...</thought> ou [THOUGHT] na sua resposta. Responda DIRETAMENTE ao usuário.
    - Não gere código JSON ou etiquetas de diagnóstico em conversas de chat; responda diretamente em texto conversacional.

    PROTOCOLO DE SEGURANÇA E CRISE (GUARDRAILS OBRIGATÓRIOS):
    - Se o usuário expressar ideação suicida, desejo de morrer, automutilação ou desespero extremo:
      1. Demonstre acolhimento imediato, sem julgamento, sem pânico e sem minimizar a dor.
      2. Forneça com carinho o canal de apoio gratuito no Brasil: **CVV - Ligue 188** (Centro de Valorização da Vida) e o site cvv.org.br.
      3. Incentive-o a buscar uma pessoa de confiança ou profissional de saúde mental.
    """
}
