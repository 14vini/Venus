//
//  GeminiService.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import GoogleGenerativeAI

final class GeminiService: GeminiServiceProtocol {
    private let generalModel: GenerativeModel
    private let chatModel: GenerativeModel
    
    init(apiKey: String = AppConfig.geminiAPIKey, modelName: String = AppConfig.geminiModel) {
        self.generalModel = GenerativeModel(
            name: modelName,
            apiKey: apiKey
        )
        self.chatModel = GenerativeModel(
            name: modelName,
            apiKey: apiKey,
            systemInstruction: ModelContent(role: "system", parts: [
                ModelContent.Part.text(VenusSystemPrompt.fullPrompt)
            ])
        )
    }
    
    // MARK: - Conversational Chat
    
    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood]
    ) async throws -> String {
        var historyContent = try conversationHistory.suffix(30).map { message in
            try ModelContent(role: message.isFromUser ? "user" : "model", parts: [.text(message.content)])
        }
        
        if let last = historyContent.last, last.role == "user" && conversationHistory.last?.content == userMessage {
            historyContent.removeLast()
        }

        let context = buildCombinedContextString(profile: userProfile, moods: checkInHistory)
        let finalPrompt = context + userMessage
        
        do {
            let chat = chatModel.startChat(history: historyContent)
            let response = try await chat.sendMessage(finalPrompt)
            
            guard let text = response.text else {
                throw VenusAIError.noResponse
            }
            
            return cleanJsonText(text)
        } catch {
            return generateFallbackResponse(userMessage: userMessage, history: conversationHistory)
        }
    }
    
    // MARK: - Mirror & Emotional Insights
    
    func generateMirrorResume(
        checkInHistory: [Mood],
        userProfile: UserProfile?
    ) async throws -> String {
        let profileContext = buildProfileContext(profile: userProfile)
        let checkInContext = buildCheckInHistoryContext(moods: checkInHistory)
        
        let prompt = """
        Você é a Venus, um assistente empático de inteligência emocional. 
        O usuário acabou de abrir o chat a partir da tela de "Espelho" (onde ele analisa seus sentimentos e padrões).
        
        Abaixo estão os dados do perfil do usuário e todo o histórico de check-ins dele (últimos dias/semanas):
        
        \(profileContext)
        
        \(checkInContext)
        
        Com base nessas informações:
        1. Faça um resumo/síntese acolhedor e profundo sobre como o usuário tem se sentido recentemente (conectando os sentimentos dele, as flutuações, gatilhos e notas). Lembre-se de ser empática e agir como um espelho de seus sentimentos confusos.
        2. Faça UMA pergunta instigante e aberta relacionada a esses sentimentos para iniciar a conversa e ajudá-lo a refletir.
        
        Regras importantes:
        - Seja calorosa, natural e use um tom conversacional.
        - Fale diretamente em português.
        - Não use formatações pesadas como Markdown excessivo (evite negritos desnecessários).
        - O texto deve ser conciso (máximo 4-5 linhas de reflexão + a pergunta).
        """
        
        let response = try await generalModel.generateContent(prompt)
        guard let text = response.text else {
            throw VenusAIError.noResponse
        }
        
        return cleanResponse(text)
    }
    
    func generateMirrorInsights(
        checkInHistory: [Mood],
        chatSessions: [ChatSession],
        userProfile: UserProfile?
    ) async throws -> (
        weeklyTrend: WeeklyEmotionalTrend,
        weeklyInsights: WeeklyStrategicInsights,
        patternAlert: PatternAlert?
    ) {
        let profileContext = buildProfileContext(profile: userProfile)
        let checkInContext = buildCheckInHistoryContext(moods: checkInHistory)
        let chatContext = buildChatContext(sessions: chatSessions)
        
        let prompt = """
        Você é a Venus, uma inteligência artificial que atua como espelho emocional e analista de hábitos de bem-estar.
        O usuário quer ver o seu "Espelho" semanal (Mirror).
        Sua tarefa é analisar o perfil do usuário, o histórico de check-ins dele e as conversas de chat recentes para gerar insights emocionais profundos, empáticos e precisos.
        
        Abaixo estão os dados do perfil do usuário:
        \(profileContext)
        
        Abaixo estão os check-ins emocionais registrados pelo usuário nos últimos dias/semanas:
        \(checkInContext)
        
        Abaixo estão as conversas de chat recentes entre o usuário e você (Venus):
        \(chatContext)
        
        Com base em todas essas informações, gere um objeto JSON contendo:
        1. "direction": A tendência emocional da semana ("improving" para melhora, "stable" para estável, "declining" para queda).
        2. "currentWeekScore": Uma pontuação de 0.0 a 1.0 representando o nível de bem-estar médio da semana atual.
        3. "previousWeekScore": Uma pontuação de 0.0 a 1.0 opcional representando o nível da semana anterior.
        4. "summary": Um resumo/síntese bem-escrito, empático, reflexivo e acolhedor (de 3 a 5 linhas) sobre o estado emocional recente do usuário, padrões de humor e interações. Use um tom de "espelho" acolhedor e profundo.
        5. "dominantTrigger": O principal gatilho ou fator associado às oscilações emocionais (ex: "Trabalho sob pressão", "Rotina de sono", "Tempo com família"). Máximo 3 palavras.
        6. "criticalWindow": O período do dia mais sensível para o usuário (ex: "Tarde (14h - 16h)", "Fim de tarde (17h - 19h)", "Início da manhã").
        7. "bestDay": O dia da semana em que o usuário se sentiu mais calmo ou feliz (ex: "Sábado", "Quarta-feira").
        8. "behavioralFocus": Uma recomendação de mudança comportamental prática e focada (ex: "Desconectar telas às 22h", "Caminhada de 15 min pela manhã").
        9. "alertTitle": Opcional. Título de um padrão de alerta identificado (ex: "Ansiedade Acumulada", "Insônia Recorrente").
        10. "alertDetail": Opcional. Detalhe explicativo do alerta.
        
        Responda APENAS com o objeto JSON estruturado da seguinte forma, sem adicionar explicações fora do JSON:
        {
            "direction": "improving|stable|declining",
            "currentWeekScore": 0.75,
            "previousWeekScore": 0.60,
            "summary": "Texto do resumo empático...",
            "dominantTrigger": "Fator principal",
            "criticalWindow": "Janela horária",
            "bestDay": "Dia da semana",
            "behavioralFocus": "Foco comportamental",
            "alertTitle": "Título do alerta ou null",
            "alertDetail": "Detalhe do alerta ou null"
        }
        """
        
        let response = try await generalModel.generateContent(prompt)
        guard let text = response.text else {
            throw VenusAIError.noResponse
        }
        
        let cleanJsonString = cleanJsonText(text)
        guard let jsonData = cleanJsonString.data(using: .utf8) else {
            throw VenusAIError.invalidResponse
        }
        
        let decoded = try JSONDecoder().decode(AIMirrorResponse.self, from: jsonData)
        
        let direction: WeeklyTrendDirection
        switch decoded.direction.lowercased() {
        case "improving": direction = .improving
        case "declining": direction = .declining
        default: direction = .stable
        }
        
        let weeklyTrend = WeeklyEmotionalTrend(
            direction: direction,
            summary: decoded.summary,
            currentWeekScore: decoded.currentWeekScore,
            previousWeekScore: decoded.previousWeekScore
        )
        
        let weeklyInsights = WeeklyStrategicInsights(
            dominantTrigger: decoded.dominantTrigger,
            bestDay: decoded.bestDay,
            criticalWindow: decoded.criticalWindow,
            sleepCounterfactual: nil,
            worstRecurringPattern: decoded.alertTitle ?? "Nenhum padrão crítico detectado",
            behavioralFocus: decoded.behavioralFocus,
            leverageScore: 0.8,
            streakQualityScore: 0.9,
            recoveryProtocol: nil,
            confidence: 0.85
        )
        
        var patternAlert: PatternAlert? = nil
        if let alertTitle = decoded.alertTitle, let alertDetail = decoded.alertDetail, !alertTitle.isEmpty {
            patternAlert = PatternAlert(title: alertTitle, detail: alertDetail)
        }
        
        return (weeklyTrend, weeklyInsights, patternAlert)
    }
    
    func analyzeEmotionalState(message: String) async throws -> EmotionalState {
        let prompt = """
        Analyze the emotional state of this message and respond with ONLY a JSON object:
        
        Message: "\(message)"
        
        Response format:
        {
            "primary_emotion": "happy|sad|anxious|angry|neutral|excited|frustrated|lonely|stressed|grateful",
            "intensity": 1-10,
            "needs_support": true/false,
            "keywords": ["word1", "word2"]
        }
        """
        
        do {
            let response = try await generalModel.generateContent(prompt)
            guard let text = response.text else {
                return EmotionalState.neutral()
            }
            
            return try parseEmotionalState(from: text)
        } catch {
            return analyzeEmotionalStateFallback(message: message)
        }
    }
    
    func generateWellnessSuggestion(emotionalState: EmotionalState) -> String {
        switch emotionalState.primaryEmotion {
        case .anxious:
            return "Que tal tentarmos uma respiração 4-7-8? Inspire por 4, segure por 7, expire por 8. Isso pode ajudar a acalmar a ansiedade. 🌸"
        case .sad:
            return "Às vezes é importante honrar nossos sentimentos. Que tal escrever três coisas pelas quais você é grato hoje? 💙"
        case .stressed:
            return "O estresse pode ser intenso. Tente fazer uma pausa de 5 minutos - respire fundo ou ouça uma música que te acalma. ✨"
        case .lonely:
            return "A solidão é difícil. Lembre-se que você não está sozinho. Que tal ligar para alguém querido ou dar uma caminhada? 🤗"
        case .angry:
            return "A raiva é válida. Que tal tentar contar até 10 devagar ou fazer alguns alongamentos para liberar essa energia? 🔥"
        case .frustrated:
            return "Frustração acontece. Às vezes ajuda dar um passo para trás e ver a situação de outro ângulo. Respire fundo. 💪"
        case .excited:
            return "Que energia maravilhosa! Aproveite esse momento positivo e talvez compartilhe essa alegria com alguém especial. ⭐"
        case .grateful:
            return "Gratidão é transformadora! Que tal anotar esse sentimento em um diário ou fazer algo gentil por você mesmo? 🙏"
        default:
            return "Como você está se sentindo agora? Estou aqui para conversar sobre qualquer coisa que esteja em sua mente. 💜"
        }
    }
    
    func generateSuggestion(mood: MoodType, userContext: UserProfile) async throws -> String {
        let prompt = """
        Você é a Venus, um assistente de bem-estar empático.
        
        Usuário: \(userContext.name)
        Humor atual: \(mood.rawValue) (\(mood.emoji))
        Foco atual: \(userContext.primaryGoal.isEmpty ? "não informado" : userContext.primaryGoal)
        Tom preferido: \(userContext.coachingTone.isEmpty ? "não informado" : userContext.coachingTone)
        Tempo por dia: \(userContext.dailyTimeBudgetMinutes == 0 ? "não informado" : "\(userContext.dailyTimeBudgetMinutes) minutos")
        
        Interesses: \(userContext.interests.joined(separator: ", "))
        Hobbies atuais: \(userContext.currentHobbies.joined(separator: ", "))
        Áreas de melhoria: \(userContext.improvementAreas.joined(separator: ", "))
        
        Com base no humor e perfil do usuário, sugira UMA atividade específica e personalizada que:
        1. Ajude com o humor atual
        2. Se alinhe com os interesses dele
        3. Seja prática e possível de fazer agora
        
        Responda em formato curto, começando direto com a sugestão.
        """
        
        let response = try await generalModel.generateContent(prompt)
        guard let text = response.text else {
            throw VenusAIError.noResponse
        }
        
        return cleanResponse(text)
    }
    
    func generateGreeting(userName: String, mood: MoodType?) async throws -> String {
        var prompt = "Crie uma saudação acolhedora e personalizada para \(userName) no app Venus, um assistente de bem-estar."
        if let mood = mood {
            prompt += " O usuário está se sentindo \(mood.rawValue) hoje."
        }
        prompt += " A saudação deve ser curta (máximo 2 linhas) e calorosa."
        
        let response = try await generalModel.generateContent(prompt)
        guard let text = response.text else {
            throw VenusAIError.noResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Context Helpers
    
    private func buildCombinedContextString(profile: UserProfile?, moods: [Mood]) -> String {
        var context = "--- CONTEXTO DO USUÁRIO ---\n"
        context += buildProfileContext(profile: profile)
        context += "\n"
        context += buildCheckInHistoryContext(moods: moods)
        context += "---------------------------\n\n"
        return context
    }
    
    private func buildProfileContext(profile: UserProfile?) -> String {
        guard let profile = profile else { return "Perfil do usuário não preenchido.\n" }
        
        var context = "Perfil do Usuário:\n"
        context += "- Nome: \(profile.name)\n"
        if !profile.primaryGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            context += "- Objetivo Principal: \(profile.primaryGoal)\n"
        }
        if !profile.coachingTone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            context += "- Tom Desejado da Venus: \(profile.coachingTone)\n"
        }
        if profile.dailyTimeBudgetMinutes > 0 {
            context += "- Disponibilidade Diária: \(profile.dailyTimeBudgetMinutes) minutos\n"
        }
        if !profile.interests.isEmpty {
            context += "- Interesses: \(profile.interests.joined(separator: ", "))\n"
        }
        if !profile.improvementAreas.isEmpty {
            context += "- Áreas de Foco/Melhoria: \(profile.improvementAreas.joined(separator: ", "))\n"
        }
        return context
    }
    
    private func buildCheckInHistoryContext(moods: [Mood]) -> String {
        guard !moods.isEmpty else { return "Nenhum check-in registrado ainda.\n" }
        
        var context = "Histórico de Check-ins Emocionais (mais recentes primeiro):\n"
        let sortedMoods = moods.sorted(by: { $0.timestamp > $1.timestamp })
        
        for mood in sortedMoods.prefix(15) {
            let dateStr = formatDate(mood.timestamp)
            context += "- \(dateStr): Sente-se \(mood.type.rawValue)"
            if let intensity = mood.intensity {
                context += " (Intensidade: \(intensity)/10)"
            }
            if let energy = mood.energyLevel {
                context += ", Energia: \(energy.rawValue)"
            }
            if let control = mood.controlLevel {
                context += ", Controle: \(control.rawValue)"
            }
            if let sleep = mood.sleepQuality {
                context += ", Sono: \(sleep.rawValue)"
            }
            if !mood.triggers.isEmpty {
                context += ", Gatilhos: [\(mood.triggers.joined(separator: ", "))]"
            }
            if let area = mood.affectedArea {
                context += ", Área Afetada: \(area.rawValue)"
            }
            if !mood.bodySignals.isEmpty {
                context += ", Sinais Físicos: [\(mood.bodySignals.joined(separator: ", "))]"
            }
            if let note = mood.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                context += ", Notas: \"\(note)\""
            }
            context += "\n"
        }
        
        return context
    }
    
    private func buildChatContext(sessions: [ChatSession]) -> String {
        guard !sessions.isEmpty else { return "Nenhuma conversa de chat registrada ainda.\n" }
        
        var context = "Conversas de Chat Recentes:\n"
        let sortedSessions = sessions.sorted(by: { $0.lastMessageAt > $1.lastMessageAt })
        for session in sortedSessions.prefix(3) {
            context += "- Sessão do dia \(formatDate(session.createdAt)):\n"
            for message in session.messages.suffix(10) {
                let sender = message.isFromUser ? "Usuário" : "Venus"
                context += "  [\(sender)]: \(message.content)\n"
            }
            context += "\n"
        }
        return context
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func cleanJsonText(_ text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```json") {
            clean = String(clean.dropFirst(7))
        } else if clean.hasPrefix("```") {
            clean = String(clean.dropFirst(3))
        }
        if clean.hasSuffix("```") {
            clean = String(clean.dropLast(3))
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func cleanResponse(_ response: String) -> String {
        return response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
    }
    
    private func parseEmotionalState(from jsonString: String) throws -> EmotionalState {
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return EmotionalState.neutral()
        }
        
        let emotionString = json["primary_emotion"] as? String ?? "neutral"
        let intensity = json["intensity"] as? Int ?? 5
        let needsSupport = json["needs_support"] as? Bool ?? false
        let keywords = json["keywords"] as? [String] ?? []
        let emotion = EmotionType(rawValue: emotionString) ?? .neutral
        
        return EmotionalState(
            primaryEmotion: emotion,
            intensity: intensity,
            needsSupport: needsSupport,
            keywords: keywords
        )
    }
    
    private func analyzeEmotionalStateFallback(message: String) -> EmotionalState {
        let lowercased = message.lowercased()
        let emotionKeywords: [(EmotionType, [String])] = [
            (.anxious, ["ansiedade", "ansioso", "nervoso", "preocupado", "medo"]),
            (.sad, ["triste", "tristeza", "deprimido", "melancolia", "chateado"]),
            (.angry, ["raiva", "irritado", "furioso", "bravo", "ódio"]),
            (.stressed, ["estresse", "estressado", "pressão", "sobrecarregado"]),
            (.lonely, ["sozinho", "solidão", "isolado", "abandonado"]),
            (.excited, ["animado", "empolgado", "feliz", "alegre", "eufórico"]),
            (.grateful, ["grato", "agradecido", "obrigado", "gratidão"])
        ]
        
        for (emotion, keywords) in emotionKeywords {
            if keywords.contains(where: { lowercased.contains($0) }) {
                let intensity = lowercased.contains("muito") || lowercased.contains("extremamente") ? 8 : 6
                return EmotionalState(
                    primaryEmotion: emotion,
                    intensity: intensity,
                    needsSupport: [.anxious, .sad, .angry, .stressed, .lonely].contains(emotion),
                    keywords: keywords.filter { lowercased.contains($0) }
                )
            }
        }
        
        return EmotionalState.neutral()
    }
    
    private func generateFallbackResponse(userMessage: String, history: [ChatMessage]) -> String {
        let lowercased = userMessage.lowercased()
        let recentTopics = history.suffix(4).map { $0.content.lowercased() }.joined(separator: " ")
        
        let responseText: String
        let summaryText: String
        let tags: [String]
        
        if lowercased.contains("ansiedade") || lowercased.contains("ansioso") {
            if recentTopics.contains("respiração") {
                responseText = "Vejo que a ansiedade ainda está presente. Além da respiração, que tal tentarmos uma técnica de grounding? Nomeie 5 coisas que você vê, 4 que você ouve, 3 que você toca. 🌸"
            } else {
                responseText = "Entendo sua ansiedade. Vamos tentar juntos: respire fundo por 4 segundos, segure por 4, e solte por 6. Repita algumas vezes. 🌸"
            }
            summaryText = "Sente-se ansioso. Sugerido técnica de respiração/grounding."
            tags = ["ansiedade", "calma", "respiração"]
        } else if lowercased.contains("triste") || lowercased.contains("tristeza") {
            responseText = "Sua tristeza é válida e importante. Às vezes precisamos sentir para curar. Que tal escrever sobre o que está sentindo ou ouvir uma música que te conforta? 💙"
            summaryText = "Expressou tristeza. Sugerido escrita reflexiva/música."
            tags = ["tristeza", "acolhimento"]
        } else if lowercased.contains("estresse") || lowercased.contains("estressado") {
            responseText = "O estresse pode ser avassalador. Que tal fazer uma pausa de 5 minutos? Levante-se, estique o corpo, ou simplesmente respire conscientemente. ✨"
            summaryText = "Relatou estresse. Sugerido pausa consciente."
            tags = ["estresse", "pausa"]
        } else if lowercased.contains("obrigado") || lowercased.contains("obrigada") {
            responseText = "Fico muito feliz em poder estar aqui com você! Lembre-se: você é mais forte do que imagina. 💜"
            summaryText = "Agradecimento."
            tags = ["gratidão"]
        } else {
            let responses = [
                "Obrigada por compartilhar isso comigo. Como você está se sentindo agora? Que tal fazermos uma respiração consciente juntos? 🌱",
                "Entendo. Às vezes ajuda colocar os pensamentos para fora. Que tal escrever sobre o que está passando pela sua mente? ✍️",
                "Estou aqui para você. Que tal começarmos com três respirações profundas para nos centrarmos? 💙"
            ]
            responseText = responses.randomElement() ?? "Como posso te ajudar hoje? 💜"
            summaryText = "Check-in de humor geral."
            tags = ["mood"]
        }
        
        let tagsJson = tags.map { "\"\($0)\"" }.joined(separator: ", ")
        return """
        {
          "response": "\(responseText)",
          "summary": "\(summaryText)",
          "tags": [\(tagsJson)],
          "reminder": null
        }
        """
    }
}

// Backward compatibility
typealias VenusAIService = GeminiService
typealias GeminiServiceImpl = GeminiService
