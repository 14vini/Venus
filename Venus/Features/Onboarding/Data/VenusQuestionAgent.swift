//
//  VenusQuestionAgent.swift
//  Venus
//
//  Agente leve e reutilizável para as perguntas do onboarding.
//

import Foundation

/// Gera uma única pergunta curta para o fluxo de autoconhecimento.
protocol VenusQuestionGenerating: Sendable {
    func generateQuestion(profileContext: String, answeredSoFar: [String]) async throws -> String
}

/// Agente de perguntas: modelo rápido, timeout curto e cascata gratuita.
/// Nunca devolve raciocínio, JSON ou markdown — apenas a pergunta em português.
final class VenusQuestionAgent: VenusQuestionGenerating, Sendable {
    private let apiKey: String
    private let baseURL: String
    private let session: URLSession
    
    /// Cascata gratuita: do mais leve para o roteador de modelos livres.
    private static let models = [
        "inclusionai/ling-3.2-flash:free",
        "google/gemma-4-31b-it:free",
        "openrouter/free"
    ]
    
    /// Limites curtos: o onboarding não pode prender a pessoa esperando IA.
    private static let perModelTimeout: TimeInterval = 6
    private static let totalTimeout: TimeInterval = 10
    
    private static let fallbackQuestions = [
        "O que tem trazido mais tranquilidade para você ultimamente?",
        "Quando você sente que o dia finalmente desacelera?",
        "O que você gostaria que fosse mais leve na sua rotina?",
        "Há algo que te faz sentir mais presente agora?",
        "Como você costuma cuidar de si quando o dia fica pesado?"
    ]
    
    /// Palavras vazias que não ajudam a detectar repetição de tema.
    private static let stopwords: Set<String> = [
        "de", "da", "do", "dos", "das", "e", "a", "o", "os", "as", "que", "em", "com",
        "para", "por", "um", "uma", "no", "na", "se", "me", "eu", "você", "mais",
        "muito", "como", "sua", "seu", "quando", "algo", "isso", "tem", "faz"
    ]
    
    init(
        apiKey: String = AppConfig.openRouterAPIKey,
        baseURL: String = AppConfig.openRouterBaseURL,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }
    
    func generateQuestion(profileContext: String, answeredSoFar: [String]) async throws -> String {
        guard !apiKey.isEmpty else { throw VenusAIError.missingAPIKey }
        guard let url = URL(string: baseURL) else { throw VenusAIError.networkError }
        
        let messages = [
            OpenRouterMessage(role: "system", content: Self.systemPrompt),
            OpenRouterMessage(role: "user", content: Self.userPrompt(profileContext: profileContext, answeredSoFar: answeredSoFar))
        ]
        
        let deadline = Date().addingTimeInterval(Self.totalTimeout)
        
        for model in Self.models {
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 1 else { break }
            
            do {
                let raw = try await requestQuestion(
                    model: model,
                    url: url,
                    messages: messages,
                    timeout: min(Self.perModelTimeout, remaining)
                )
                if let question = Self.parseQuestion(from: raw, excluding: answeredSoFar) {
                    return question
                }
            } catch {
                print("⚠️ [VenusQuestionAgent] Modelo '\(model)' falhou: \(error.localizedDescription)")
            }
        }
        
        return Self.localFallback(answerCount: answeredSoFar.count, answeredSoFar: answeredSoFar)
    }
    
    // MARK: - Request
    
    private func requestQuestion(
        model: String,
        url: URL,
        messages: [OpenRouterMessage],
        timeout: TimeInterval
    ) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://venus.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Venus Emotional Wellness", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = timeout
        
        let body = OpenRouterChatRequest(
            model: model,
            messages: messages,
            temperature: 0.85,
            max_tokens: 64,
            stream: false
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
        guard statusCode == 200 else {
            throw VenusAIError.apiError(statusCode: statusCode, message: "Falha ao gerar pergunta")
        }
        
        let decoded = try JSONDecoder().decode(OpenRouterChatResponse.self, from: data)
        // O campo `reasoning` é ignorado de propósito: nunca vai para a UI.
        guard let content = decoded.choices?.first?.message.content else {
            throw VenusAIError.noResponse
        }
        return content
    }
    
    // MARK: - Parsing defensivo
    
    private static func parseQuestion(from raw: String, excluding answers: [String]) -> String? {
        if let fromJSON = questionFromJSON(raw),
           let valid = normalize(fromJSON),
           !repeatsTheme(valid, answers) {
            return valid
        }
        let sanitized = VenusTextSanitizer.sanitize(raw)
        for line in sanitized.split(whereSeparator: \.isNewline) {
            if let valid = normalize(String(line)), !repeatsTheme(valid, answers) {
                return valid
            }
        }
        return nil
    }
    
    private static func questionFromJSON(_ raw: String) -> String? {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}"),
              start < end else { return nil }
        guard let data = String(raw[start...end]).data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        for key in ["question", "pergunta", "nextQuestion", "text"] {
            if let value = json[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }
    
    private static func normalize(_ candidate: String) -> String? {
        var text = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        
        let prefixes = ["pergunta:", "próxima pergunta:", "proxima pergunta:", "question:", "next question:", "resposta:"]
        let lowered = text.lowercased()
        for prefix in prefixes where lowered.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Remove numeração de lista e aspas que o modelo insiste em adicionar.
        if let firstSpace = text.firstIndex(where: { $0 == " " || $0 == "." }),
           text[text.startIndex..<firstSpace].allSatisfy({ $0.isNumber }) {
            text = String(text[firstSpace...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        text = text.trimmingCharacters(in: CharacterSet(charactersIn: "*`>-\"“” "))
        guard !text.isEmpty else { return nil }
        
        let cleaned = text.lowercased()
        guard !cleaned.hasPrefix("```"), !cleaned.hasPrefix("{"), !cleaned.hasPrefix("["),
              !cleaned.contains("reasoning"), !cleaned.contains("analysis") else { return nil }
        
        if !text.hasSuffix("?") {
            guard !text.hasSuffix(".") && !text.hasSuffix("!") else { return nil }
            text += "?"
        }
        guard text.count >= 8, text.split(separator: " ").count >= 3 else { return nil }
        return text
    }
    
    // MARK: - Variedade semântica
    
    /// Evita uma pergunta que repita as palavras-chave do que a pessoa já disse.
    private static func repeatsTheme(_ question: String, _ answers: [String]) -> Bool {
        let questionWords = contentWords(question)
        guard !questionWords.isEmpty else { return false }
        return answers.contains { answer in
            let answerWords = contentWords(answer)
            return questionWords.intersection(answerWords).count >= 3
        }
    }
    
    private static func contentWords(_ text: String) -> Set<String> {
        Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 2 && !stopwords.contains($0) }
        )
    }
    
    private static func localFallback(answerCount: Int, answeredSoFar: [String]) -> String {
        let usedWords = contentWords(answeredSoFar.joined(separator: " "))
        var best = fallbackQuestions[answerCount % fallbackQuestions.count]
        var smallestOverlap = Int.max
        
        for offset in 0..<fallbackQuestions.count {
            let candidate = fallbackQuestions[(answerCount + offset) % fallbackQuestions.count]
            let overlap = contentWords(candidate).intersection(usedWords).count
            if overlap < smallestOverlap {
                smallestOverlap = overlap
                best = candidate
            }
        }
        return best
    }
    
    // MARK: - Prompt
    
    private static let systemPrompt = """
    Você é a Venus, uma companheira calorosa de autoconhecimento do aplicativo Venus.

    SUA ÚNICA TAREFA: devolver APENAS uma pergunta curta, natural e acolhedora, em português do Brasil, terminando com '?'.

    REGRAS:
    - Uma única pergunta, em uma única linha, com cerca de 12 palavras e resposta possível em poucas palavras.
    - Tom humano, curioso e gentil. Nada de tom clínico, médico, terapêutico ou de questionário.
    - Varie o ângulo: escolha um tema novo, sem repetir assuntos ou palavras das respostas anteriores.
    - Escreva somente a pergunta: sem saudação, explicação, aspas, numeração, prefixos, JSON, markdown, tags ou qualquer pensamento/raciocínio interno.
    """
    
    private static func userPrompt(profileContext: String, answeredSoFar: [String]) -> String {
        var prompt = "Contexto conhecido sobre a pessoa:\n\(profileContext.isEmpty ? "não informado" : profileContext)\n"
        
        if answeredSoFar.isEmpty {
            prompt += "\nEla ainda não respondeu nada. Comece com uma pergunta leve e aberta."
        } else {
            prompt += "\nRespostas já dadas (em ordem):\n"
            for (index, answer) in answeredSoFar.enumerated() {
                prompt += "\(index + 1). \(answer)\n"
            }
            let themes = contentWords(answeredSoFar.joined(separator: " "))
                .sorted()
                .prefix(12)
                .joined(separator: ", ")
            prompt += "\nTemas e palavras a evitar: \(themes.isEmpty ? "nenhum" : themes)."
            prompt += "\nEscolha um ângulo diferente e formule um novo passo natural."
        }
        
        prompt += "\n\nDevolva apenas a próxima pergunta, em uma linha."
        return prompt
    }
}
