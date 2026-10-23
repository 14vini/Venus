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
    
    private func executeChatCompletion(
        modelToUse: String,
        messages: [OpenRouterMessage],
        temperature: Double,
        maxTokens: Int
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
            model: modelToUse,
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

    private func sendChatCompletion(
        messages: [OpenRouterMessage],
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> String {
        do {
            return try await executeChatCompletion(
                modelToUse: model,
                messages: messages,
                temperature: temperature,
                maxTokens: maxTokens
            )
        } catch {
            // Se o modelo primário (ex: respan/span-01-lite da Decisions API) não aceitar /chat/completions,
            // aciona automaticamente o fallback gratuito para manter a experiência do usuário fluida
            if model != AppConfig.fallbackChatModel {
                print("⚠️ [OpenRouter] Falha com modelo '\(model)' (\(error.localizedDescription)). Tentando fallback para '\(AppConfig.fallbackChatModel)'...")
                return try await executeChatCompletion(
                    modelToUse: AppConfig.fallbackChatModel,
                    messages: messages,
                    temperature: temperature,
                    maxTokens: maxTokens
                )
            }
            throw error
        }
    }
    
    // MARK: - Streaming API Communication
    
    func generateStreamResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood]
    ) -> AsyncThrowingStream<String, Error> {
        let lens: SelfKnowledgeLens
        if userProfile?.coachingTone.lowercased().contains("socrático") == true || userProfile?.coachingTone.lowercased().contains("socratico") == true {
            lens = .socratic
        } else {
            lens = .compassionate
        }
        return generateStreamResponse(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            checkInHistory: checkInHistory,
            readiness: nil,
            activeLens: lens
        )
    }

    func generateStreamResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood],
        readiness: ReadinessEnergyAssessment?,
        activeLens: SelfKnowledgeLens
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
                
                let diagnosis = SelfKnowledgeEngine.shared.diagnose(
                    userMessage: userMessage,
                    readiness: readiness,
                    recentMoods: checkInHistory,
                    userProfile: userProfile,
                    currentLens: activeLens
                )

                let systemPrompt = self.buildSystemPrompt(
                    profile: userProfile,
                    moods: checkInHistory,
                    readiness: readiness,
                    activeLens: activeLens,
                    currentDiagnosis: diagnosis
                )

                var apiMessages: [OpenRouterMessage] = [
                    OpenRouterMessage(role: "system", content: systemPrompt)
                ]
                
                let recentHistory = conversationHistory.suffix(10)
                for message in recentHistory {
                    let role = message.isFromUser ? "user" : "assistant"
                    apiMessages.append(OpenRouterMessage(role: role, content: message.content))
                }
                
                apiMessages.append(OpenRouterMessage(role: "user", content: userMessage))
                
                await self.streamWithFallback(
                    url: url,
                    apiMessages: apiMessages,
                    preferredModel: self.model,
                    continuation: continuation
                )
            }
        }
    }

    private func streamWithFallback(
        url: URL,
        apiMessages: [OpenRouterMessage],
        preferredModel: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        let modelsToTry = preferredModel == AppConfig.fallbackChatModel
            ? [preferredModel]
            : [preferredModel, AppConfig.fallbackChatModel]

        for (index, currentModel) in modelsToTry.enumerated() {
            let isLastAttempt = index == modelsToTry.count - 1
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("https://venus.app", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Venus Emotional Wellness", forHTTPHeaderField: "X-Title")
            request.timeoutInterval = 60
            
            let requestBody = OpenRouterChatRequest(
                model: currentModel,
                messages: apiMessages,
                temperature: 0.7,
                max_tokens: 1000,
                stream: true
            )
            
            do {
                let encoder = JSONEncoder()
                request.httpBody = try encoder.encode(requestBody)
                
                let (asyncBytes, response) = try await session.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
                    var errorBody = ""
                    for try await line in asyncBytes.lines {
                        errorBody += line
                    }
                    print("⚠️ OpenRouter HTTP \(statusCode) com '\(currentModel)': \(errorBody)")
                    
                    if !isLastAttempt {
                        print("🔄 Fazendo fallback automático para '\(AppConfig.fallbackChatModel)'...")
                        continue
                    }
                    
                    let detailMessage: String
                    if let data = errorBody.data(using: .utf8),
                       let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorObj = errorJson["error"] as? [String: Any],
                       let message = errorObj["message"] as? String {
                        detailMessage = message
                    } else {
                        detailMessage = errorBody.isEmpty ? "HTTP \(statusCode)" : errorBody
                    }
                    continuation.finish(throwing: VenusAIError.apiError(statusCode: statusCode, message: detailMessage))
                    return
                }
                
                let streamFilter = ThinkingStreamFilter()
                
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
                return
            } catch {
                if !isLastAttempt {
                    print("⚠️ Erro no stream com '\(currentModel)': \(error.localizedDescription). Tentando fallback...")
                    continue
                }
                continuation.finish(throwing: error)
                return
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
        try await generateResponse(
            userMessage: userMessage,
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            checkInHistory: checkInHistory,
            readiness: nil,
            activeLens: .socratic
        )
    }

    func generateResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        userProfile: UserProfile?,
        checkInHistory: [Mood],
        readiness: ReadinessEnergyAssessment?,
        activeLens: SelfKnowledgeLens
    ) async throws -> String {
        let diagnosis = SelfKnowledgeEngine.shared.diagnose(
            userMessage: userMessage,
            readiness: readiness,
            recentMoods: checkInHistory,
            userProfile: userProfile,
            currentLens: activeLens
        )
        let systemPrompt = buildSystemPrompt(
            profile: userProfile,
            moods: checkInHistory,
            readiness: readiness,
            activeLens: activeLens,
            currentDiagnosis: diagnosis
        )
        var messages: [OpenRouterMessage] = [
            OpenRouterMessage(role: "system", content: systemPrompt)
        ]
        
        let recentHistory = conversationHistory.suffix(10)
        for message in recentHistory {
            let role = message.isFromUser ? "user" : "assistant"
            messages.append(OpenRouterMessage(role: role, content: message.content))
        }
        
        messages.append(OpenRouterMessage(role: "user", content: userMessage))
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 800)
        return cleanResponseText(response)
    }
    
    // MARK: - Prompt Building
    
    private func buildSystemPrompt(
        profile: UserProfile?,
        moods: [Mood],
        readiness: ReadinessEnergyAssessment? = nil,
        activeLens: SelfKnowledgeLens = .socratic,
        currentDiagnosis: SelfKnowledgeDiagnosis? = nil
    ) -> String {
        var prompt = """
        Você é a Venus, uma inteligência refinada de bem-estar emocional, prontidão e autoconhecimento ("KillCritic").
        
        SUA IDENTIDADE:
        - Seja calorosa, empática, profunda e lúcida, mas SEM bajulação, sem passar a mão na cabeça e sem clichês de autoajuda.
        - Fale em português do Brasil de forma natural, humana e fluida.
        - NUNCA use jargões técnicos, médicos ou diagnósticos clínicos formais.
        - Responda de forma concisa e direta (2 a 4 parágrafos no máximo), sem rodeios.
        - Se detectar risco de automutilação ou crise severa, oriente gentilmente a buscar apoio profissional e o CVV (188).
        - NUNCA inclua pensamentos internos ou tags como <thought> ou <thinking> na resposta.
        """
        
        if let profile = profile {
            prompt += "\n\nSOBRE O USUÁRIO:\n"
            prompt += "- Nome: \(profile.name)\n"
            if !profile.gender.isEmpty {
                prompt += "- Identidade / Gênero: \(profile.gender)\n"
                if profile.gender == "Feminino" {
                    prompt += "- Diretriz de linguagem: Use pronomes femininos (ela/dela, bem-vinda, acolhida).\n"
                } else if profile.gender == "Masculino" {
                    prompt += "- Diretriz de linguagem: Use pronomes masculinos (ele/dele, bem-vindo, acolhido).\n"
                } else {
                    prompt += "- Diretriz de linguagem: Use ESTRITAMENTE pronomes neutros e linguagem inclusiva sem flexão binária de gênero (você, seu espaço, acolhimento).\n"
                }
            }
            if !profile.primaryGoal.isEmpty {
                prompt += "- Objetivo: \(profile.primaryGoal)\n"
            }
            if !profile.coachingTone.isEmpty {
                prompt += "- Tom preferido: \(profile.coachingTone)\n"
            }
            if !profile.coreValues.isEmpty {
                prompt += "- Valores Inegociáveis Centrais: \(profile.coreValues.joined(separator: ", "))\n"
            }
            if !profile.interests.isEmpty {
                prompt += "- Interesses: \(profile.interests.joined(separator: ", "))\n"
            }
            if !profile.improvementAreas.isEmpty {
                prompt += "- Áreas de atenção: \(profile.improvementAreas.joined(separator: ", "))\n"
            }
            if !profile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                prompt += "- Como o usuário funciona no dia a dia (Onboarding): \"\(profile.contextNote)\"\n"
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

        // Injeção do Motor de Autoconhecimento (Radar de Contradições, Interrogatório Socrático, Sombra, Valores, etc.)
        let diagnosis = currentDiagnosis ?? SelfKnowledgeDiagnosis(activeLens: activeLens)
        prompt += SelfKnowledgeEngine.shared.buildPromptEnrichment(
            diagnosis: diagnosis,
            lens: activeLens,
            readiness: readiness,
            profile: profile
        )
        
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
            patternAlert = PatternAlert(
                title: alertTitle,
                detail: alertDetail
            )
        }
        
        return (weeklyTrend, weeklyInsights, patternAlert)
    }
    
    func generateSuggestion(mood: MoodType, userContext: UserProfile) async throws -> String {
        let prompt = """
        O usuário registrou o humor: \(mood.rawValue) (\(mood.emoji)).
        Nome: \(userContext.name)
        Tom preferido: \(userContext.coachingTone.isEmpty ? "não informado" : userContext.coachingTone)
        Gere uma micro-sugestão acolhedora e prática em 1 ou 2 frases curtas.
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Você é a Venus, uma amiga empática. Responda em português."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 150)
        return cleanResponse(response)
    }
    
    func generateGreeting(userName: String, mood: MoodType?) async throws -> String {
        let name = userName.isEmpty ? "você" : userName
        let moodContext = mood != nil ? "O humor recente é \(mood!.rawValue)." : ""
        let prompt = "Gere uma saudação acolhedora e breve para \(name). \(moodContext) Responda em uma única frase calorosa."
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Você é a Venus. Seja breve e acolhedora."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 100)
        return cleanResponse(response)
    }
    
    func generateNextOnboardingQuestion(
        userName: String,
        userProfile: UserProfile?,
        conversationHistory: [(question: String, answer: String)],
        questionIndex: Int
    ) async throws -> AIOnboardingQuestionResponse {
        var context = "Nome: \(userName)\n"
        for (q, a) in conversationHistory {
            context += "Pergunta: \(q)\nResposta do usuário: \(a)\n"
        }
        
        let prompt = """
        Você é a Venus conduzindo o onboarding acolhedor.
        Histórico:
        \(context)
        
        Pergunta índice \(questionIndex)/4.
        Responda APENAS em JSON no formato:
        {
            "empathyReaction": "Frase empática curta validando a resposta anterior...",
            "nextQuestion": "Próxima pergunta profunda e acolhedora...",
            "suggestedTone": "Acolhedor",
            "hasEnoughContext": false
        }
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Responda exclusivamente com JSON válido."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 400)
        let clean = cleanJsonText(response)
        
        guard let data = clean.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(AIOnboardingQuestionResponse.self, from: data) else {
            return AIOnboardingQuestionResponse(
                empathyReaction: "Entendo perfeitamente.",
                nextQuestion: "O que mais você gostaria de compartilhar sobre sua rotina?",
                suggestedTone: "Acolhedor",
                hasEnoughContext: false
            )
        }
        
        return decoded
    }
    
    func generateOnboardingProfile(userProfile: UserProfile) async throws -> AIOnboardingProfileResponse {
        let context = buildCombinedContextString(profile: userProfile, moods: [])
        let prompt = """
        Gere o perfil de autoconhecimento final do onboarding da Venus em JSON:
        \(context)
        
        Formato:
        {
            "title": "Arquiteto da Própria Paz",
            "badge": "Estrategista de Energia",
            "subtitle": "Você busca clareza profunda e equilíbrio sustentável.",
            "strengths": "Capacidade de auto-observação e disciplina",
            "growthArea": "Permitir-se pausas sem culpa",
            "statText": "92% de alinhamento com foco intencional"
        }
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Responda exclusivamente com JSON válido."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 400)
        let clean = cleanJsonText(response)
        
        guard let data = clean.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(AIOnboardingProfileResponse.self, from: data) else {
            return AIOnboardingProfileResponse(
                title: "Explorador da Consciência",
                badge: "Em Busca de Clareza",
                subtitle: "Sua jornada de autoconhecimento está apenas começando.",
                strengths: "Curiosidade e abertura interna",
                growthArea: "Construção de pausas conscientes",
                statText: "Pronto para calibrar seu ritmo"
            )
        }
        
        return decoded
    }
    
    func analyzeEmotionalState(message: String) async throws -> EmotionalState {
        // Usa o serviço offline de Apple Natural Language para ultra-baixa latência e privacidade
        return AppleNaturalLanguageService.shared.analyze(text: message)
    }
    
    func generateWellnessSuggestion(emotionalState: EmotionalState) -> String {
        switch emotionalState.primaryEmotion {
        case .anxious:
            return "Que tal fazer uma respiração em 4 tempos para desacelerar o ritmo cardíaco?"
        case .sad:
            return "Dê a si mesmo(a) permissão para apenas descansar e desacelerar hoje."
        case .stressed:
            return "Faça uma pausa de 5 minutos longe de qualquer tela. Beba um copo d'água com calma."
        case .angry:
            return "Solte os ombros, destranque a mandíbula e respire fundo pelo nariz."
        case .frustrated:
            return "Divida o que está te travando em um único passo minúsculo de 2 minutos."
        case .lonely:
            return "Estou aqui com você. Às vezes o silêncio compartilhado já é um começo."
        case .grateful, .happy, .excited:
            return "Guarde essa sensação boa na memória como um âncora de clareza para os dias difíceis."
        default:
            return "Respire fundo e observe como seu corpo está apoiado agora."
        }
    }
    
    // MARK: - Biometrics & Readiness AI Methods
    
    func analyzeChatReadinessImpact(messages: [ChatMessage]) async -> ChatReadinessImpact? {
        let userTexts = messages.filter { $0.isFromUser }.suffix(3).map { $0.content }.joined(separator: " | ")
        guard !userTexts.isEmpty else { return nil }
        
        let prompt = """
        Analise o impacto emocional e cognitivo dessas falas recentes do usuário: "\(userTexts)"
        Responda APENAS em JSON:
        {
            "scoreDelta": -0.8,
            "isFocusImpacted": true,
            "isBodyImpacted": false,
            "isSleepImpacted": true,
            "customStateTitle": "Sobrecarga Mental",
            "customStateSubtitle": "Tensão acumulada",
            "detectedInsight": "Ansiedade sobre prazos"
        }
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "You are an emotion & readiness analyzer. Output only valid JSON."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        guard let response = try? await sendChatCompletion(messages: messages, temperature: 0.3, maxTokens: 300) else {
            return nil
        }
        
        let clean = cleanJsonText(response)
        guard let data = clean.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let scoreDelta = json["scoreDelta"] as? Double else {
            return nil
        }
        
        return ChatReadinessImpact(
            scoreDelta: scoreDelta,
            isFocusImpacted: json["isFocusImpacted"] as? Bool,
            isBodyImpacted: json["isBodyImpacted"] as? Bool,
            isSleepImpacted: json["isSleepImpacted"] as? Bool,
            customStateTitle: json["customStateTitle"] as? String,
            customStateSubtitle: json["customStateSubtitle"] as? String,
            detectedInsight: json["detectedInsight"] as? String,
            timestamp: Date()
        )
    }
    
    func generateReadinessMicroCopy(
        score: Double,
        primaryState: String,
        userContext: String?
    ) async -> (stateTitle: String, stateSubtitle: String) {
        let prompt = """
        Gere uma micro-fala para o gráfico de Prontidão (Readiness) do usuário com score \(String(format: "%.1f", score))/10.
        Estado primário: \(primaryState)
        Responda em formato: TÍTULO | SUBTÍTULO (máximo 4 palavras cada).
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Seja breve e direto."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        guard let response = try? await sendChatCompletion(messages: messages, temperature: 0.5, maxTokens: 60) else {
            return ("Prontidão Estável", "Ritmo equilibrado")
        }
        
        let parts = response.components(separatedBy: "|")
        if parts.count >= 2 {
            return (parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                    parts[1].trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return (response.trimmingCharacters(in: .whitespacesAndNewlines), "Energia equilibrada")
    }
    
    // MARK: - Private Context Helpers
    
    private func buildCombinedContextString(profile: UserProfile?, moods: [Mood]) -> String {
        var context = ""
        if let p = profile {
            context += "Usuário: \(p.name)\nObjetivo: \(p.primaryGoal)\n"
            if !p.coreValues.isEmpty {
                context += "Valores Centrais: \(p.coreValues.joined(separator: ", "))\n"
            }
        }
        if !moods.isEmpty {
            context += "Humores recentes: " + moods.suffix(5).map { "\($0.type.rawValue)" }.joined(separator: ", ") + "\n"
        }
        return context
    }
    
    private func buildChatContext(sessions: [ChatSession]) -> String {
        let insights = sessions.flatMap { $0.userInsights }.suffix(5)
        guard !insights.isEmpty else { return "" }
        return "Insights de conversas recentes: " + insights.joined(separator: "; ")
    }
    
    private func cleanResponse(_ response: String) -> String {
        response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func cleanResponseText(_ response: String) -> String {
        ThinkingStreamFilter.clean(response).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func cleanJsonText(_ response: String) -> String {
        var clean = response.trimmingCharacters(in: .whitespacesAndNewlines)
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
}
