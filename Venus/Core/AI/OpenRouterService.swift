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
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
                        var errorBody = ""
                        for try await line in asyncBytes.lines {
                            errorBody += line
                        }
                        print("❌ OpenRouter HTTP Error (\(statusCode)): \(errorBody)")
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
                } catch {
                    continuation.finish(throwing: error)
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
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 800)
        return cleanResponseText(response)
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
        
        let response = try await sendChatCompletion(messages: messages, temperature: 0.7, maxTokens: 200)
        return cleanResponse(response)
    }
    
    // MARK: - Dynamic Interactive Onboarding Question Generation
    
    func generateNextOnboardingQuestion(
        userName: String,
        conversationHistory: [(question: String, answer: String)],
        questionIndex: Int
    ) async throws -> AIOnboardingQuestionResponse {
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "amigo" : userName
        
        var historyText = ""
        for (q, a) in conversationHistory {
            let cleanQ = sanitizeOnboardingText(q)
            let cleanA = sanitizeOnboardingText(a)
            historyText += "Pergunta anterior: \(cleanQ)\nResposta do usuário: \(cleanA)\n\n"
        }
        
        let prompt = """
        Você é a Venus, uma inteligência pessoal de prontidão, energia, foco, rotina, sono e clareza mental do aplicativo Venus.
        Seu objetivo neste onboarding é conduzir uma conversa reflexiva e profunda com o usuário para entender como ele realmente funciona no dia a dia.
        
        O usuário se chama \(name).
        
        Histórico da conversa até agora:
        \(historyText)
        
        REGRAS DE FORMATAÇÃO E ESTILO RIGOROSAS:
        1. NUNCA use travessões (—, -, –), traços ou hífens no início ou meio das frases.
        2. NUNCA use emojis de nenhum tipo (sem emoticons, sem símbolos gráficos, sem estrelas, etc.).
        3. Fale de forma humana, empática, inteligente e fluida em português do Brasil com pontuação padrão.
        4. O app não é apenas sobre ansiedade: explore ritmo biológico, energia, sobrecarga mental, foco, sono e metas práticas.
        
        AVALIAÇÃO DE PROFUNDIDADE:
        - Avalie se as respostas do usuário já deram clareza suficiente sobre:
          a) Ritmo de energia diário e picos de foco
          b) Fricções, sobrecarga mental ou dispersão
          c) Recuperação noturna e sono
          d) O que ele mais quer transformar na rotina
        - Se você já tiver informações ricas sobre esses pontos essenciais, defina "hasEnoughContext": true.
        - Se ainda faltar entender como ele opera ou se a resposta foi curta, defina "hasEnoughContext": false e formule a próxima pergunta reflexiva que aprofunde no ponto que falta.
        
        Sua missão:
        1. "empathyReaction": Reagir em 1 frase curta (máximo 14 palavras) validando com sagacidade o que ele disse (sem travessão, sem emojis).
        2. "nextQuestion": Formular 1 pergunta aberta, inteligente e reflexiva (máximo 18 palavras) para aprofundar no funcionamento dele (sem travessão, sem emojis).
        3. "hasEnoughContext": true ou false.
        4. "suggestedTone": "Gentil", "Direto", "Prático" ou "Motivacional".
        
        Responda EXCLUSIVAMENTE em JSON válido:
        {
            "empathyReaction": "Frase curta de acolhimento e reconhecimento inteligente",
            "nextQuestion": "Pergunta reflexiva para o usuário se auto-observar",
            "hasEnoughContext": false,
            "suggestedTone": "Prático"
        }
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Responda apenas com JSON válido em português. Sem travessões e sem emojis."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        do {
            let response = try await sendChatCompletion(messages: messages, temperature: 0.4, maxTokens: 2500)
            let cleanJson = cleanJsonText(response)
            if let data = cleanJson.data(using: .utf8) {
                let decoded = try JSONDecoder().decode(AIOnboardingQuestionResponse.self, from: data)
                let cleanReaction = sanitizeOnboardingText(decoded.empathyReaction)
                let cleanQuestion = sanitizeOnboardingText(decoded.nextQuestion)
                let sanitizedResponse = AIOnboardingQuestionResponse(
                    empathyReaction: cleanReaction,
                    nextQuestion: cleanQuestion,
                    suggestedTone: decoded.suggestedTone,
                    hasEnoughContext: decoded.hasEnoughContext
                )
                print("✨ Pergunta de Onboarding gerada com sucesso pela IA: \(cleanQuestion)")
                return sanitizedResponse
            }
        } catch {
            print("⚠️ Falha ao gerar pergunta dinâmica de onboarding via IA: \(error)")
        }
        
        // Intelligent Reflective Fallbacks based on question index (sem travessão, sem emojis)
        if questionIndex == 1 {
            return AIOnboardingQuestionResponse(
                empathyReaction: "Entender seu ritmo ajuda muito a mapear seus picos e quedas de energia.",
                nextQuestion: "Em que momentos do dia sua mente funciona melhor e o que costuma dispersar seu foco?",
                suggestedTone: "Prático",
                hasEnoughContext: false
            )
        } else if questionIndex == 2 {
            return AIOnboardingQuestionResponse(
                empathyReaction: "Ter clareza sobre suas noites é a chave para calibrar sua recuperação.",
                nextQuestion: "Quando chega a noite, o que você sente que mais impede sua mente de desligar de verdade?",
                suggestedTone: "Gentil",
                hasEnoughContext: false
            )
        } else {
            return AIOnboardingQuestionResponse(
                empathyReaction: "Isso nos dá clareza total sobre o seu funcionamento e necessidades.",
                nextQuestion: "Se você pudesse alinhar uma única coisa na sua rotina para viver no seu melhor ritmo, qual seria?",
                suggestedTone: "Motivacional",
                hasEnoughContext: true
            )
        }
    }
    
    private func sanitizeOnboardingText(_ text: String) -> String {
        var clean = text
        // Remove dashes/hyphens used as bullets or dashes
        clean = clean.replacingOccurrences(of: "—", with: "")
        clean = clean.replacingOccurrences(of: "–", with: "")
        clean = clean.replacingOccurrences(of: "- ", with: "")
        clean = clean.replacingOccurrences(of: " -", with: "")
        
        // Filter out all emojis (Unicode scalars for emoji Presentation, Symbols, Pictographs)
        let filteredScalars = clean.unicodeScalars.filter { scalar in
            if scalar.properties.isEmoji && scalar.properties.isEmojiPresentation { return false }
            if scalar.properties.isEmoji && scalar.value > 0x2380 { return false }
            if scalar.value >= 0x1F600 && scalar.value <= 0x1F64F { return false } // Emoticons
            if scalar.value >= 0x1F300 && scalar.value <= 0x1F5FF { return false } // Misc Symbols and Pictographs
            if scalar.value >= 0x1F680 && scalar.value <= 0x1F6FF { return false } // Transport and Map
            if scalar.value >= 0x1F700 && scalar.value <= 0x1F77F { return false } // Alchemical Symbols
            if scalar.value >= 0x1F780 && scalar.value <= 0x1F7FF { return false } // Geometric Shapes
            if scalar.value >= 0x1F800 && scalar.value <= 0x1F8FF { return false } // Supplemental Arrows
            if scalar.value >= 0x1F900 && scalar.value <= 0x1F9FF { return false } // Supplemental Symbols
            if scalar.value >= 0x1FA00 && scalar.value <= 0x1FA6F { return false } // Chess Symbols
            if scalar.value >= 0x1FA70 && scalar.value <= 0x1FAFF { return false } // Symbols and Pictographs Extended-A
            if scalar.value >= 0x2600 && scalar.value <= 0x26FF { return false } // Misc symbols
            if scalar.value >= 0x2700 && scalar.value <= 0x27BF { return false } // Dingbats
            return true
        }
        
        clean = String(String.UnicodeScalarView(filteredScalars))
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Onboarding Profile Generation
    
    func generateOnboardingProfile(userProfile: UserProfile) async throws -> AIOnboardingProfileResponse {
        let profileContext = buildProfileContext(profile: userProfile)
        
        let prompt = """
        Você é a Venus, a companheira de acolhimento e inteligência emocional do app Venus.
        O usuário acabou de completar a apresentação inicial dele.
        
        Dados do usuário:
        \(profileContext)
        
        Gere uma mensagem de boas-vindas calorosa, empática e acolhedora em formato JSON:
        {
            "title": "Frase carinhosa de boas-vindas com o nome do usuário",
            "badge": "SEU ESPAÇO ESTÁ PRONTO",
            "subtitle": "Frase personalizada de 1 a 2 linhas conectando o momento atual do usuário com o apoio que você vai oferecer",
            "strengths": "2 a 3 pontos fortes e qualidades que você percebeu nele (separados por vírgula)",
            "growthArea": "Como a Venus vai apoiar o bem-estar e o ritmo dele nos próximos dias",
            "statText": "Uma frase curta, confortante e acolhedora lembrando que ele não precisa dar conta de tudo sozinho"
        }
        
        Responda APENAS com o JSON válido, sem tags de raciocínio.
        """
        
        let messages = [
            OpenRouterMessage(role: "system", content: "Responda apenas com JSON válido em português."),
            OpenRouterMessage(role: "user", content: prompt)
        ]
        
        do {
            let response = try await sendChatCompletion(messages: messages, temperature: 0.5, maxTokens: 1500)
            let cleanJson = cleanJsonText(response)
            if let data = cleanJson.data(using: .utf8) {
                return try JSONDecoder().decode(AIOnboardingProfileResponse.self, from: data)
            }
        } catch {
            print("⚠️ Falha ao gerar perfil de onboarding via IA: \(error)")
        }
        
        let name = userProfile.name.isEmpty ? "Você" : userProfile.name
        return AIOnboardingProfileResponse(
            title: "Seja bem-vindo(a), \(name) 🤍",
            badge: "SEU ESPAÇO ESTÁ PRONTO",
            subtitle: "\(name), estou muito feliz em ter você aqui. Este é seu espaço seguro para respirar e encontrar leveza.",
            strengths: "Sensibilidade, dedicação e busca sincera por equilíbrio.",
            growthArea: "Te ajudar a desacelerar no fim do dia e lembrar você de não se cobrar tanto.",
            statText: "Você não precisa dar conta de tudo sozinho(a). Vamos cuidar de um dia de cada vez."
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
        if !profile.gender.isEmpty {
            context += "- Identidade / Gênero: \(profile.gender)\n"
            if profile.gender == "Feminino" {
                context += "- Pronomes: Femininos (ela/dela, bem-vinda, acolhida)\n"
            } else if profile.gender == "Masculino" {
                context += "- Pronomes: Masculinos (ele/dele, bem-vindo, acolhido)\n"
            } else {
                context += "- Pronomes: Neutros e Inclusivos (você, seu espaço, sem flexão binária de gênero)\n"
            }
        }
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
        let clean = withoutThinking.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
}

// Backward compatibility typealiases
typealias VenusAIService = OpenRouterService
typealias GeminiService = OpenRouterService
typealias GeminiServiceImpl = OpenRouterService
