//
//  OpenRouterService.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

final class OpenRouterService: VenusAIServiceProtocol, @unchecked Sendable {
    private let apiKey: String
    private let model: String
    private let baseURL: String
    private let session: URLSession
    
    init(
        apiKey: String = AppConfig.openRouterAPIKey,
        model: String = AppConfig.openRouterModel,
        baseURL: String = AppConfig.openRouterBaseURL,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - Core API Communication
    
    private func sendChatCompletion(
        messages: [OpenRouterMessage],
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw VenusAIError.missingAPIKey
        }
        
        guard let url = URL(string: baseURL) else {
            throw VenusAIError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://venus.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Venus Emotional Wellness", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 30
        
        let requestBody = OpenRouterChatRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            max_tokens: maxTokens,
            stream: false
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VenusAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                throw VenusAIError.apiError(statusCode: httpResponse.statusCode, message: message)
            }
            throw VenusAIError.apiError(statusCode: httpResponse.statusCode, message: "OpenRouter request failed with HTTP \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let chatResponse = try decoder.decode(OpenRouterChatResponse.self, from: data)
        
        guard let choices = chatResponse.choices,
              let firstChoice = choices.first,
              let content = firstChoice.message.content else {
            throw VenusAIError.noResponse
        }
        
        return content
    }
    
    // MARK: - Streaming API Communication
    
    func generateStreamResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard !self.apiKey.isEmpty else {
                    continuation.finish(throwing: VenusAIError.missingAPIKey)
                    return
                }
                
                guard let url = URL(string: self.baseURL) else {
                    continuation.finish(throwing: VenusAIError.networkError)
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("https://venus.app", forHTTPHeaderField: "HTTP-Referer")
                request.setValue("Venus Emotional Wellness", forHTTPHeaderField: "X-Title")
                request.timeoutInterval = 60
                
                let systemPrompt = self.buildSystemPrompt(profile: userProfile, moods: checkInHistory)
                var apiMessages: [OpenRouterMessage] = [
                    OpenRouterMessage(role: "system", content: systemPrompt)
                ]
                
                let recentHistory = conversationHistory.suffix(10)
                for message in recentHistory {
                    let role = message.isFromUser ? "user" : "assistant"
                    apiMessages.append(OpenRouterMessage(role: role, content: message.content))
                }
                
                apiMessages.append(OpenRouterMessage(role: "user", content: userMessage))
                
                let requestBody = OpenRouterChatRequest(
                    model: self.model,
                    messages: apiMessages,
                    temperature: 0.7,
                    max_tokens: 1000,
                    stream: true
                )
                
                do {
                    let encoder = JSONEncoder()
                    request.httpBody = try encoder.encode(requestBody)
                    
                    let (asyncBytes, response) = try await self.session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        let fallback = self.generateFallbackResponse(userMessage: userMessage, history: conversationHistory)
                        continuation.yield(fallback)
                        continuation.finish()
                        return
                    }
                    
                    var streamFilter = ThinkingStreamFilter()
                    
                    for try await line in asyncBytes.lines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard trimmed.hasPrefix("data: ") else { continue }
                        let dataContent = String(trimmed.dropFirst(6))
                        
                        if dataContent == "[DONE]" {
                            break
                        }
                        
                        guard let data = dataContent.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(OpenRouterStreamResponse.self, from: data),
                              let choices = chunk.choices,
                              let delta = choices.first?.delta,
                              let content = delta.content else {
                            continue
                        }
                        
                        let safeText = streamFilter.process(chunk: content)
                        if !safeText.isEmpty {
                            continuation.yield(safeText)
                        }
                    }
                    
                    let remaining = streamFilter.flush()
                    if !remaining.isEmpty {
                        continuation.yield(remaining)
                    }
                    
                    continuation.finish()
                } catch {
                    let fallback = self.generateFallbackResponse(userMessage: userMessage, history: conversationHistory)
                    continuation.yield(fallback)
                    continuation.finish()
                }
            }
        }
    }
    
    // MARK: - VenusAIServiceProtocol Implementation
    
    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood]
    ) async throws -> String {
        let systemPrompt = buildSystemPrompt(profile: userProfile, moods: checkInHistory)
        var messages: [OpenRouterMessage] = [
            OpenRouterMessage(role: "system", content: systemPrompt)
        ]
        
        let recentHistory = conversationHistory.suffix(10)
        for message in recentHistory {
            let role = message.isFromUser ? "user" : "assistant"
            messages.append(OpenRouterMessage(role: role, content: message.content))
        }
        
        messages.append(OpenRouterMessage(role: "user", content: userMessage))
        
        do {
            let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 800)
            return cleanResponseText(response)
        } catch {
            return generateFallbackResponse(userMessage: userMessage, history: conversationHistory)
        }
    }
    
    // MARK: - Prompt Building
    
    private func buildSystemPrompt(profile: UserProfile?, moods: [Mood]) -> String {
        var prompt = """
        Você é a Venus, uma companheira inteligente de bem-estar emocional e autoconhecimento.
        
        SUA IDENTIDADE:
        - Seja calorosa, empática, acolhedora e profundamente compreensiva.
        - Fale em português do Brasil de forma natural, humana e fluida.
        - NUNCA use jargões técnicos, médicos ou diagnósticos clínicos.
        - Responda de forma concisa e direta (2 a 4 parágrafos no máximo), sem rodeios.
        - Valide os sentimentos do usuário antes de propor qualquer reflexão ou ação.
        - Faça perguntas suaves que ajudem o usuário a explorar o que está sentindo.
        - Se detectar risco de automutilação ou crise severa, oriente gentilmente a buscar apoio profissional e o CVV (188).
        - NUNCA inclua pensamentos internos ou tags como <thought> ou <thinking> na resposta.
        """
        
        if let profile = profile {
            prompt += "\n\nSOBRE O USUÁRIO:\n"
            prompt += "- Nome: \(profile.name)\n"
            if !profile.primaryGoal.isEmpty {
                prompt += "- Objetivo: \(profile.primaryGoal)\n"
            }
            if !profile.coachingTone.isEmpty {
                prompt += "- Tom preferido: \(profile.coachingTone)\n"
            }
            if !profile.interests.isEmpty {
                prompt += "- Interesses: \(profile.interests.joined(separator: ", "))\n"
            }
            if !profile.improvementAreas.isEmpty {
                prompt += "- Áreas de atenção: \(profile.improvementAreas.joined(separator: ", "))\n"
            }
        }
        
        if !moods.isEmpty {
            let recentMoods = moods.suffix(5)
            prompt += "\nHUMOR RECENTE DO USUÁRIO:\n"
            for mood in recentMoods {
                prompt += "- \(mood.type.rawValue) (\(mood.type.emoji))"
                if let intensity = mood.intensity {
                    prompt += " - Intensidade: \(intensity)/10"
                }
                if let energy = mood.energyLevel {
                    prompt += " - Energia: \(energy.rawValue)"
                }
                if let note = mood.note, !note.isEmpty {
                    prompt += " - Nota: \"\(note)\""
                }
                prompt += "\n"
            }
        }
        
        return prompt
    }
    
    // MARK: - Mirror / Strategic Insights
    
    func generateMirrorResume(
        checkInHistory: [Mood],
        userProfile: UserProfile?
    ) async throws -> String {
        let combinedContext = buildCombinedContextString(profile: userProfile, moods: checkInHistory)
        
        let prompt = """
        Você é a Venus, uma inteligência de apoio e clareza mental.
        Gere uma síntese empática e estratégica da jornada emocional recente do usuário.
        
        \(combinedContext)
        
        Diretrizes:
        - Máximo de 3 parágrafos curtos.
        - Tom acolhedor e focado em clareza prática.
        - Responda em português do Brasil sem incluir pensamentos internos.
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Você é a Venus, assistente empático de bem-estar. Responda em português."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.5, maxTokens: 600)
        return cleanResponse(response)
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
        var context = buildCombinedContextString(profile: userProfile, moods: checkInHistory)
        context += "\n" + buildChatContext(sessions: chatSessions)
        
        let prompt = """
        Você é a Venus, um motor de análise comportamental e emocional.
        Analise o histórico recente e gere insights estruturados em JSON:
        
        \(context)
        
        Responda APENAS com o objeto JSON estruturado:
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
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Responda exclusivamente com o objeto JSON válido, sem texto antes ou depois. Todos os textos em português."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.3, maxTokens: 1000)
        let cleanJsonString = cleanJsonText(response)
        
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
    
    // MARK: - Emotional State Analysis
    
    func analyzeEmotionalState(message: String) async throws -> EmotionalState {
        let localAnalysis = AppleNaturalLanguageService.shared.analyze(text: message)
        if localAnalysis.isCrisisRisk {
            return localAnalysis
        }
        
        let prompt = """
        Classifique o estado emocional desta mensagem e retorne EXCLUSIVAMENTE um objeto JSON:
        
        Mensagem: "\(message)"
        
        Formato de resposta:
        {
            "primary_emotion": "happy|sad|anxious|angry|neutral|excited|frustrated|lonely|stressed|grateful",
            "intensity": 1-10,
            "needs_support": true/false,
            "keywords": ["palavra1", "palavra2"]
        }
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "You are an emotion classification model. Output only raw JSON. Never include thinking tags."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        do {
            let response = try await sendChatCompletion(messages: messages, temperature: 0.2, maxTokens: 400)
            return try parseEmotionalState(from: cleanJsonText(response), fallbackScore: localAnalysis.sentimentScore)
        } catch {
            return localAnalysis
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
        
        Com base no humor e perfil do usuário, sugira UMA atividade específica e personalizada.
        Responda em formato curto em português.
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Você é a Venus, assistente empático de bem-estar. Responda em português sem tags de raciocínio."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 400)
        return cleanResponse(response)
    }
    
    func generateGreeting(userName: String, mood: MoodType?) async throws -> String {
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "você" : userName
        var prompt = "Crie uma saudação acolhedora e personalizada para \(name) no app Venus, um companheiro de bem-estar."
        if let mood = mood {
            prompt += " O usuário registrou humor recente como '\(mood.rawValue)' hoje."
        }
        prompt += " A saudação deve ser carinhosa, inspiradora e curta (máximo 2 frases) em português do Brasil sem incluir pensamentos internos."
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Você é a Venus, assistente empático de bem-estar. Responda em português."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        do {
            let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 200)
            return cleanResponse(response)
        } catch {
            let timeGreeting = "Olá, \(name)!"
            if let mood = mood {
                return "\(timeGreeting) Vi que você está se sentindo \(mood.rawValue). Estou aqui ao seu lado para trazer leveza ao seu dia. ✨"
            } else {
                return "\(timeGreeting) Que bom ter você aqui. Como está sua energia para o dia de hoje? 🌸"
            }
        }
    }
    
    // MARK: - Onboarding Profile Generation
    
    func generateOnboardingProfile(userProfile: UserProfile) async throws -> AIOnboardingProfileResponse {
        let profileContext = buildProfileContext(profile: userProfile)
        
        let prompt = """
        Você é a Venus, a inteligência emocional do app Venus.
        O usuário acabou de completar o onboarding de calibração inicial.
        
        Dados do usuário:
        \(profileContext)
        
        Gere um diagnóstico de perfil de prontidão inicial exclusivo, empático e profundo em formato JSON:
        {
            "title": "Título marcante do arquétipo emocional",
            "badge": "PERFIL DE PRONTIDÃO",
            "subtitle": "Frase personalizada de 1 a 2 linhas conectando o nome do usuário com a busca dele",
            "strengths": "3 principais pontos fortes emocionais/comportamentais identificados (separados por vírgula)",
            "growthArea": "Foco prático de alívio e calibração da Venus para os próximos dias",
            "statText": "Estatística motivacional de validação social"
        }
        
        Responda APENAS com o JSON válido, sem tags de raciocínio.
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Responda apenas com JSON válido em português."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        do {
            let response = try await sendChatCompletion(messages: messages, temperature: 0.4, maxTokens: 600)
            let cleanJson = cleanJsonText(response)
            if let data = cleanJson.data(using: .utf8) {
                return try JSONDecoder().decode(AIOnboardingProfileResponse.self, from: data)
            }
        } catch {
            print("⚠️ Falha ao gerar perfil de onboarding via IA: \(error)")
        }
        
        let name = userProfile.name.isEmpty ? "Você" : userProfile.name
        return AIOnboardingProfileResponse(
            title: "O Guardião do Equilíbrio",
            badge: "PERFIL DE PRONTIDÃO",
            subtitle: "\(name), você mantém um ritmo constante e busca clareza diária.",
            strengths: "Empatia, consistência e admirável equilíbrio sob pressão.",
            growthArea: "Identificar quando desacelerar a tempo e preservar sua bateria.",
            statText: "94% relatam sensação imediata de clareza e controle do seu ritmo com a Venus."
        )
    }

    // MARK: - Biometrics & Readiness AI Methods

    func analyzeChatReadinessImpact(messages: [ChatMessage]) async -> ChatReadinessImpact? {
        let userMessages = messages.filter { $0.isFromUser }
        guard userMessages.count >= 1 else { return nil }

        let recentMessages = messages.suffix(8)
        var conversationText = ""
        for msg in recentMessages {
            let sender = msg.isFromUser ? "Usuário" : "Venus"
            let clean = ThinkingStreamFilter.clean(msg.content)
            conversationText += "[\(sender)]: \(clean)\n"
        }

        let prompt = """
        Você é o motor de avaliação de prontidão emocional da Venus.
        Avalie se a conversa recente indica um impacto RELEVANTE na energia, ansiedade ou prontidão diária do usuário.
        
        Conversa:
        \(conversationText)
        
        Diretrizes:
        - Se o usuário desabafou sobre pânico, crise aguda de ansiedade, exaustão extrema ou insônia grave: scoreDelta negativo (entre -1.0 e -2.0).
        - Se o usuário relatou alívio, clareza, descompressão profunda ou ânimo: scoreDelta positivo (entre +0.5 e +1.2).
        - Se for uma conversa neutra ou casual sem mudança emocional significativa: retorne scoreDelta = 0.0.
        - Título do estado (customStateTitle): 1 a 3 palavras poéticas e humanas (ex: "Modo Respiro", "Mente Leve", "Pausa Necessária", "Pico Criativo"). NUNCA use termos médicos.
        - Subtítulo (customStateSubtitle): 1 frase curta e acolhedora (máximo 8 palavras).
        
        Responda EXCLUSIVAMENTE com o objeto JSON válido:
        {
            "hasSignificantImpact": true,
            "scoreDelta": 0.0,
            "isFocusImpacted": false,
            "isBodyImpacted": false,
            "isSleepImpacted": false,
            "customStateTitle": "Título curto ou null",
            "customStateSubtitle": "Frase curta ou null",
            "detectedInsight": "Resumo em 4 palavras do impacto"
        }
        """

        let apiMessages = [
            OpenRouterMessage(role: "system", content: "You are an emotion & readiness analyzer. Output only valid JSON."),
            OpenRouterMessage(role: "user", content: prompt)
        ]

        do {
            let response = try await sendChatCompletion(messages: apiMessages, temperature: 0.2, maxTokens: 400)
            let cleanJson = cleanJsonText(response)
            guard let data = cleanJson.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            let hasImpact = json["hasSignificantImpact"] as? Bool ?? false
            let delta = json["scoreDelta"] as? Double ?? 0.0

            guard hasImpact || abs(delta) >= 0.4 else { return nil }

            let focus = json["isFocusImpacted"] as? Bool
            let body = json["isBodyImpacted"] as? Bool
            let sleep = json["isSleepImpacted"] as? Bool
            let title = json["customStateTitle"] as? String
            let subtitle = json["customStateSubtitle"] as? String
            let insight = json["detectedInsight"] as? String

            return ChatReadinessImpact(
                scoreDelta: delta,
                isFocusImpacted: focus,
                isBodyImpacted: body,
                isSleepImpacted: sleep,
                customStateTitle: title,
                customStateSubtitle: subtitle,
                detectedInsight: insight,
                timestamp: Date()
            )
        } catch {
            let fullText = userMessages.map { $0.content.lowercased() }.joined(separator: " ")
            if fullText.contains("pânico") || fullText.contains("crise") || fullText.contains("ansiedade muito forte") {
                return ChatReadinessImpact(
                    scoreDelta: -1.5,
                    isFocusImpacted: true,
                    isBodyImpacted: true,
                    customStateTitle: "Modo Respiro",
                    customStateSubtitle: "Acolha seu corpo e faça uma pausa.",
                    detectedInsight: "Tensão aguda relatada",
                    timestamp: Date()
                )
            } else if fullText.contains("muito melhor") || fullText.contains("aliviado") || fullText.contains("clareou") {
                return ChatReadinessImpact(
                    scoreDelta: +0.8,
                    isFocusImpacted: false,
                    customStateTitle: "Mente Serena",
                    customStateSubtitle: "Clareza conquistada após reflexão.",
                    detectedInsight: "Alívio e clareza",
                    timestamp: Date()
                )
            }
            return nil
        }
    }

    func generateReadinessMicroCopy(
        score: Double,
        primaryState: String,
        userContext: String?
    ) async -> (stateTitle: String, stateSubtitle: String) {
        let prompt = """
        Você é a Venus, companheira de bem-estar emocional.
        Gere uma micro-fala para o gráfico de Prontidão (Readiness) do usuário com score \(String(format: "%.1f", score))/10.
        Estado atual: \(primaryState).
        Contexto do usuário: \(userContext ?? "Geral").
        
        REGRAS RIGOROSAS:
        1. Título: EXATAMENTE 1 a 3 palavras poéticas, humanas e encorajadoras (ex: "Go For It", "Ritmo Fluido", "Modo Respiro", "Poupe Bateria", "Pico Criativo", "Mente Serena").
        2. Subtítulo: EXATAMENTE 1 frase curta de 6 a 9 palavras no máximo (ex: "Bateria restaurada para criar.", "Dia de desacelerar e respirar.", "Foco afiado para a sua manhã.").
        3. ZERO TERMOS TÉCNICOS: NUNCA mencione HRV, batimentos, porcentagens, relógio, notas numéricas ou dados biométricos.
        
        Responda APENAS em JSON:
        {
            "stateTitle": "Título curto",
            "stateSubtitle": "Frase curta"
        }
        """

        let messages = [
            OpenRouterMessage(role: "system", content: "You are a concise UX writer for an emotional wellbeing app. Output only valid JSON in Portuguese."),
            OpenRouterMessage(role: "user", content: prompt)
        ]

        do {
            let response = try await sendChatCompletion(messages: messages, temperature: 0.4, maxTokens: 250)
            let cleanJson = cleanJsonText(response)
            if let data = cleanJson.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = json["stateTitle"] as? String,
               let sub = json["stateSubtitle"] as? String,
               !title.isEmpty, !sub.isEmpty {
                return (title.trimmingCharacters(in: .whitespacesAndNewlines), sub.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } catch {
            print("Micro-copy fallback used: \(error)")
        }

        if score >= 8.5 {
            return ("Go For It", "Bateria alta para focar e criar.")
        } else if score >= 7.0 {
            return ("Ritmo Fluido", "Mente serena e clareza para o dia.")
        } else if score >= 5.0 {
            return ("Ritmo Leve", "Equilibre tarefas e faça pausas.")
        } else if score >= 3.5 {
            return ("Poupe Bateria", "Desacelere e priorize o essencial.")
        } else {
            return ("Modo Respiro", "Acolha seu corpo e descanse.")
        }
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
        if !profile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            context += "- Relato Inicial do Usuário (Onboarding): \"\(profile.contextNote)\"\n"
        }
        return context
    }
    
    private func buildCheckInHistoryContext(moods: [Mood]) -> String {
        guard !moods.isEmpty else { return "Nenhum check-in registrado ainda.\n" }

        var context = "Histórico de Check-ins Emocionais (mais recentes primeiro, máx 10, notas truncadas por privacidade):\n"
        let sortedMoods = moods.sorted(by: { $0.timestamp > $1.timestamp })
        
        for mood in sortedMoods.prefix(10) {
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
                let safe = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
                context += ", Notas: \"\(safe)\""
            }
            context += "\n"
        }
        
        return context
    }
    
    private func buildChatContext(sessions: [ChatSession]) -> String {
        guard !sessions.isEmpty else { return "Nenhuma conversa de chat registrada ainda.\n" }
        
        var context = "Conversas de Chat Recentes (máx 2 sessões x 6 msgs, truncadas):\n"
        let sortedSessions = sessions.sorted(by: { $0.lastMessageAt > $1.lastMessageAt })
        for session in sortedSessions.prefix(2) {
            context += "- Sessão do dia \(formatDate(session.createdAt)):\n"
            for message in session.messages.suffix(6) {
                let sender = message.isFromUser ? "Usuário" : "Venus"
                let raw = ThinkingStreamFilter.clean(message.content)
                let content = String(raw.prefix(300))
                context += "  [\(sender)]: \(content)\n"
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
        let withoutThinking = ThinkingStreamFilter.clean(text)
        var clean = withoutThinking.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let jsonBlockStart = clean.range(of: "```json") {
            let afterStart = clean[jsonBlockStart.upperBound...]
            if let endRange = afterStart.range(of: "```") {
                return String(afterStart[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        if let blockStart = clean.range(of: "```") {
            let afterStart = clean[blockStart.upperBound...]
            if let endRange = afterStart.range(of: "```") {
                return String(afterStart[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        if let firstBrace = clean.firstIndex(of: "{"),
           let lastBrace = clean.lastIndex(of: "}"),
           firstBrace <= lastBrace {
            return String(clean[firstBrace...lastBrace]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return clean
    }
    
    private func cleanResponse(_ response: String) -> String {
        let withoutThinking = ThinkingStreamFilter.clean(response)
        return withoutThinking
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
    }
    
    private func parseEmotionalState(from jsonString: String, fallbackScore: Double = 0.0) throws -> EmotionalState {
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
            keywords: keywords,
            sentimentScore: fallbackScore,
            isCrisisRisk: false
        )
    }
    
    private func cleanResponseText(_ text: String) -> String {
        var clean = ThinkingStreamFilter.clean(text)
        
        if clean.contains("\"response\":"),
           let data = cleanJsonText(clean).data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let responseVal = json["response"] as? String {
            clean = ThinkingStreamFilter.clean(responseVal)
        }
        
        if clean.hasPrefix("```") {
            if let firstLineEnd = clean.firstIndex(of: "\n") {
                clean = String(clean[firstLineEnd...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if clean.hasSuffix("```") {
                clean = String(clean.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func generateFallbackResponse(userMessage: String, history: [ChatMessage]) -> String {
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("ansiedade") || lowercased.contains("ansioso") || lowercased.contains("nervoso") {
            return "Entendo perfeitamente o quanto a ansiedade pode pesar. Respire fundo e não se cobre por se sentir assim. Que tal fazermos uma pausa de um minuto para você soltar os ombros e respirar com calma? Estou aqui com você. 🌸"
        } else if lowercased.contains("triste") || lowercased.contains("tristeza") || lowercased.contains("chateado") {
            return "Sinto muito que você esteja passando por isso. O que você está sentindo é totalmente válido e você não precisa carregar tudo sozinho. Se quiser colocar em palavras o que está no seu peito, estou te ouvindo. 💙"
        } else if lowercased.contains("estresse") || lowercased.contains("estressado") || lowercased.contains("sobrecarregado") || lowercased.contains("pressão") {
            return "A sobrecarga nos dá a sensação de que precisamos dar conta de tudo ao mesmo tempo. Que tal escolher apenas uma coisa importante para hoje e deixar o resto para depois sem culpa? Uma pausa agora vai te ajudar a respirar. ✨"
        } else if lowercased.contains("obrigado") || lowercased.contains("obrigada") || lowercased.contains("valeu") {
            return "Fico muito feliz em estar aqui ao seu lado! Lembre-se de ser gentil consigo mesmo ao longo do dia. 💜"
        } else if lowercased.contains("oi") || lowercased.contains("olá") || lowercased.contains("bom dia") || lowercased.contains("boa tarde") || lowercased.contains("boa noite") {
            return "Olá! Que bom que você veio conversar. Como está a sua mente e a sua energia hoje? 💫"
        } else {
            let responses = [
                "Obrigada por compartilhar isso comigo. Às vezes, colocar para fora o que estamos sentindo é o primeiro passo para a mente clarear. Como posso te apoiar melhor agora? 🌱",
                "Estou te ouvindo com carinho. É totalmente compreensível você se sentir assim. Quer aprofundar no que mais está pesando no seu dia? 💙",
                "Entendo. Lembre-se que você não precisa resolver todos os nós de uma vez. Qual seria um micro-passo leve para agora? ✨"
            ]
            return responses.randomElement() ?? "Estou aqui para te ouvir. Como posso te ajudar a trazer mais leveza para o seu momento? 💜"
        }
    }
}

// Backward compatibility typealiases
typealias VenusAIService = OpenRouterService
typealias GeminiService = OpenRouterService
typealias GeminiServiceImpl = OpenRouterService
