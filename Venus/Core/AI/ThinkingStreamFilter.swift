//
//  ThinkingStreamFilter.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import Foundation

/// Impede que raciocínio, JSON e marcadores internos do modelo cheguem à interface.
///
/// - `clean` / `sanitizeUserVisible`: para textos completos (inclusive o acumulado
///   de streaming feito pela camada de apresentação).
/// - `process` / `flush`: para chunks de streaming; além de remover pensamentos,
///   retém um eventual prefixo JSON até decidir se é texto ou objeto estruturado.
/// - `cleanStructuredJSON`: para rotas que **precisam** do JSON (nunca remove o
///   objeto, apenas campos de raciocínio e valores inseguros).
final class ThinkingStreamFilter {
    private var isInsideThinking: Bool = false
    private var buffer: String = ""
    private var jsonProbe: String = ""
    private var isPlainTextConfirmed: Bool = false
    
    private static let reasoningOpenTags = [
        "<think>", "<thinking>", "<thought>", "<reasoning>", "<analysis>",
        "<internal_reasoning>", "<chain_of_thought>", "<cot>", "<pensamento>",
        "<raciocínio>", "<raciocinio>", "<internal>",
        "[THOUGHT]", "[REASONING]", "[ANALYSIS]", "[PENSAMENTO]",
        "[RACIOCÍNIO]", "[RACIOCINIO]"
    ]
    
    private static let reasoningCloseTags = [
        "</think>", "</thinking>", "</thought>", "</reasoning>", "</analysis>",
        "</internal_reasoning>", "</chain_of_thought>", "</cot>", "</pensamento>",
        "</raciocínio>", "</raciocinio>", "</internal>",
        "[/THOUGHT]", "[/REASONING]", "[/ANALYSIS]", "[/PENSAMENTO]",
        "[/RACIOCÍNIO]", "[/RACIOCINIO]"
    ]
    
    /// Chaves que nunca devem aparecer em uma resposta estruturada exibida na UI.
    private static let internalJSONKeys: Set<String> = [
        "reasoning", "reasoning_content", "reasoningcontent", "analysis", "thought",
        "thinking", "internal", "internal_reasoning", "chain_of_thought",
        "chainofthought", "cot", "raciocinio", "raciocínio", "pensamento",
        "_thinking", "thought_process", "thoughtprocess"
    ]
    
    /// Ordem de preferência ao extrair texto humano de um JSON inesperado no chat.
    private static let preferredTextKeys: Set<String> = [
        "response", "message", "text", "content", "answer", "reply",
        "resposta", "conteudo", "conteúdo", "summary", "nextquestion",
        "empathyreaction", "description"
    ]
    
    private let openTags = ThinkingStreamFilter.reasoningOpenTags
    private let closeTags = ThinkingStreamFilter.reasoningCloseTags
    
    // MARK: - Streaming
    
    /// Processa um chunk e devolve apenas texto seguro para a interface.
    /// O primeiro token seguro é liberado imediatamente; só um prefixo
    /// suspeito de JSON é retido até que se decida se é objeto ou prosa.
    func process(chunk: String) -> String {
        buffer += chunk
        var result = ""
        
        while !buffer.isEmpty {
            if isInsideThinking {
                var earliestCloseRange: Range<String.Index>? = nil
                
                for tag in closeTags {
                    if let range = buffer.range(of: tag, options: .caseInsensitive) {
                        if earliestCloseRange == nil || range.lowerBound < earliestCloseRange!.lowerBound {
                            earliestCloseRange = range
                        }
                    }
                }
                
                if let closeRange = earliestCloseRange {
                    buffer = String(buffer[closeRange.upperBound...])
                    isInsideThinking = false
                    
                    while let first = buffer.first, first.isWhitespace || first.isNewline {
                        buffer.removeFirst()
                    }
                } else {
                    let maxCloseTagLen = closeTags.map(\.count).max() ?? 12
                    let keepLen = min(buffer.count, maxCloseTagLen - 1)
                    let safeToDiscardCount = buffer.count - keepLen
                    if safeToDiscardCount > 0 {
                        let discardEndIndex = buffer.index(buffer.startIndex, offsetBy: safeToDiscardCount)
                        buffer = String(buffer[discardEndIndex...])
                    }
                    break
                }
            } else {
                var earliestOpenRange: Range<String.Index>? = nil
                
                for tag in openTags {
                    if let range = buffer.range(of: tag, options: .caseInsensitive) {
                        if earliestOpenRange == nil || range.lowerBound < earliestOpenRange!.lowerBound {
                            earliestOpenRange = range
                        }
                    }
                }
                
                if let openRange = earliestOpenRange {
                    result += String(buffer[..<openRange.lowerBound])
                    buffer = String(buffer[openRange.upperBound...])
                    isInsideThinking = true
                } else {
                    var potentialPrefixLen = 0
                    for tag in openTags {
                        for len in 1..<tag.count {
                            let prefix = String(tag.prefix(len))
                            if buffer.hasSuffix(prefix) {
                                potentialPrefixLen = max(potentialPrefixLen, len)
                            }
                        }
                    }
                    
                    if potentialPrefixLen > 0 {
                        let safeLen = buffer.count - potentialPrefixLen
                        let safeEndIndex = buffer.index(buffer.startIndex, offsetBy: safeLen)
                        result += String(buffer[..<safeEndIndex])
                        buffer = String(buffer[safeEndIndex...])
                        break
                    } else {
                        result += buffer
                        buffer = ""
                    }
                }
            }
        }
        
        return gateStructuredOutput(Self.sanitizeStreamingChunk(result))
    }
    
    /// Libera o texto limpo restante quando o stream termina.
    func flush() -> String {
        var output = ""
        if !isInsideThinking {
            output += Self.sanitizeStreamingChunk(buffer)
        }
        buffer = ""
        
        if !jsonProbe.isEmpty {
            output += Self.userText(fromJSONObjectPrefix: jsonProbe)
                ?? Self.sanitizeStreamingChunk(jsonProbe)
            jsonProbe = ""
        }
        
        return Self.sanitizeUserVisible(output)
    }
    
    // MARK: - Portão de JSON no streaming
    
    private func gateStructuredOutput(_ sanitized: String) -> String {
        guard !sanitized.isEmpty else { return "" }
        if isPlainTextConfirmed { return sanitized }
        
        jsonProbe += sanitized
        let trimmed = jsonProbe.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        let looksStructured = trimmed.hasPrefix("{") || trimmed.hasPrefix("[") || trimmed.hasPrefix("```")
        if !looksStructured {
            return releaseProbe()
        }
        
        if let humanText = Self.userText(fromJSONObjectPrefix: jsonProbe) {
            isPlainTextConfirmed = true
            jsonProbe = ""
            return humanText
        }
        
        return ""
    }
    
    private func releaseProbe() -> String {
        isPlainTextConfirmed = true
        let released = jsonProbe
        jsonProbe = ""
        return Self.sanitizeStreamingChunk(released)
    }
    
    /// Extrai texto humano de um objeto JSON que tenha vazado no lugar da prosa.
    /// Devolve `nil` enquanto o objeto ainda está incompleto.
    static func userText(fromJSONObjectPrefix text: String) -> String? {
        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if candidate.hasPrefix("```") {
            candidate = stripCodeFences(from: candidate).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let start = candidate.firstIndex(where: { $0 == "{" || $0 == "[" }),
              let end = jsonEndIndex(from: start, in: candidate),
              let data = String(candidate[start..<end]).data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
        
        let joined = collectUserTextValues(from: object)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !joined.isEmpty else { return nil }
        return sanitizeUserVisible(joined)
    }
    
    private static func collectUserTextValues(from value: Any) -> [String] {
        switch value {
        case let dictionary as [String: Any]:
            var values: [String] = []
            for key in preferredTextKeys {
                if let string = dictionary[key] as? String, !string.isEmpty {
                    values.append(string)
                }
            }
            if values.isEmpty {
                for (key, nested) in dictionary where !internalJSONKeys.contains(key.lowercased()) {
                    if let string = nested as? String, string.count > 12 {
                        values.append(string)
                    }
                }
            }
            if values.isEmpty {
                for nested in dictionary.values {
                    values.append(contentsOf: collectUserTextValues(from: nested))
                }
            }
            return values
        case let array as [Any]:
            var values: [String] = []
            for item in array {
                values.append(contentsOf: collectUserTextValues(from: item))
            }
            return values
        default:
            return []
        }
    }
    
    // MARK: - API pública de sanitização
    
    /// Remove pensamentos, JSON cru, prefixos internos e chaves antes de exibir um texto.
    static func sanitizeUserVisible(_ text: String) -> String {
        stripUnsafeContent(text).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Mesma limpeza, sem aparar bordas — usada chunk a chunk no streaming.
    static func sanitizeStreamingChunk(_ text: String) -> String {
        stripUnsafeContent(text)
    }
    
    /// Atalho legível para texto que vai para a UI (inclusive acumulado de streaming).
    static func clean(_ text: String) -> String {
        sanitizeUserVisible(text)
    }
    
    /// Usado na resposta bruta da API: distingue "só pensamento" de texto/JSON
    /// entregável. Não remove JSON, pois as rotas estruturadas precisam dele.
    static func hasDeliverableContent(_ text: String) -> Bool {
        let stripped = removeReasoningBlocks(from: stripCodeFences(from: text))
        return !stripped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Rotas estruturadas precisam do JSON: remove só pensamentos, chaves internas
    /// e valores inseguros, devolvendo um objeto válido para o `JSONDecoder`.
    static func cleanStructuredJSON(_ text: String) -> String {
        let reasoningFree = removeReasoningBlocks(from: text)
        let candidate = stripCodeFences(from: reasoningFree).trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let start = candidate.firstIndex(where: { $0 == "{" || $0 == "[" }),
              let end = jsonEndIndex(from: start, in: candidate),
              let data = String(candidate[start..<end]).data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else {
            return candidate
        }
        
        let sanitized = sanitizeJSONValue(object)
        guard JSONSerialization.isValidJSONObject(sanitized),
              let output = try? JSONSerialization.data(withJSONObject: sanitized),
              let json = String(data: output, encoding: .utf8) else {
            return String(candidate[start..<end])
        }
        return json
    }
    
    // MARK: - Limpeza interna
    
    private static func stripUnsafeContent(_ text: String) -> String {
        var clean = removeReasoningBlocks(from: text)
        clean = stripCodeFences(from: clean)
        clean = removeRawJSON(from: clean)
        clean = removeReasoningKeys(from: clean)
        clean = removeInternalPrefixes(from: clean)
        clean = removeJunkLines(from: clean)
        return replace(pattern: "\\n{3,}", with: "\n\n", in: clean)
    }
    
    private static func removeReasoningBlocks(from text: String) -> String {
        let patterns: [String] = [
            "<think>.*?</think>",
            "<thinking>.*?</thinking>",
            "<thought>.*?</thought>",
            "<reasoning>.*?</reasoning>",
            "<analysis>.*?</analysis>",
            "<internal>.*?</internal>",
            "<internal_reasoning>.*?</internal_reasoning>",
            "<chain_of_thought>.*?</chain_of_thought>",
            "<cot>.*?</cot>",
            "<pensamento>.*?</pensamento>",
            "<racioc[ií]nio>.*?</racioc[ií]nio>",
            "\\[THOUGHT\\].*?\\[/THOUGHT\\]",
            "\\[REASONING\\].*?\\[/REASONING\\]",
            "\\[ANALYSIS\\].*?\\[/ANALYSIS\\]",
            "\\[PENSAMENTO\\].*?\\[/PENSAMENTO\\]",
            "\\[RACIOC[iÍ]NIO\\].*?\\[/RACIOC[iÍ]NIO\\]",
            "<\\|[^|]{0,24}\\|>"
        ]
        
        var clean = text
        for pattern in patterns {
            clean = replace(pattern: pattern, with: "", in: clean)
        }
        
        for tag in reasoningOpenTags {
            if let range = clean.range(of: tag, options: .caseInsensitive) {
                clean = String(clean[..<range.lowerBound])
            }
        }
        
        for tag in reasoningOpenTags + reasoningCloseTags {
            clean = clean.replacingOccurrences(of: tag, with: "", options: .caseInsensitive)
        }
        return clean
    }
    
    private static func stripCodeFences(from text: String) -> String {
        var clean = replace(
            pattern: "```(?:json|jsonc|swift|javascript)?[^\\S\\n]*\\r?\\n([\\s\\S]*?)```",
            with: "$1",
            in: text
        )
        clean = replace(pattern: "```[^\\n]*?```", with: "", in: clean)
        return clean
    }
    
    /// Remove objetos/arrays JSON válidos, preservando texto comum com colchetes.
    private static func removeRawJSON(from text: String) -> String {
        var result = ""
        var index = text.startIndex
        
        while index < text.endIndex {
            let character = text[index]
            if character == "{" || character == "[",
               let end = jsonEndIndex(from: index, in: text),
               isJSONPayload(String(text[index..<end])) {
                index = end
                continue
            }
            result.append(character)
            index = text.index(after: index)
        }
        return result
    }
    
    private static func jsonEndIndex(from start: String.Index, in text: String) -> String.Index? {
        var depth = 0
        var insideString = false
        var escaped = false
        var index = start
        
        while index < text.endIndex {
            let character = text[index]
            if insideString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    insideString = false
                }
            } else {
                switch character {
                case "\"": insideString = true
                case "{", "[": depth += 1
                case "}", "]":
                    depth -= 1
                    if depth == 0 { return text.index(after: index) }
                    if depth < 0 { return nil }
                default: break
                }
            }
            index = text.index(after: index)
        }
        return nil
    }
    
    private static func isJSONPayload(_ candidate: String) -> Bool {
        guard let data = candidate.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else { return false }
        return object is [String: Any] || object is [Any]
    }
    
    private static func removeReasoningKeys(from text: String) -> String {
        replace(
            pattern: "\"?(?:reasoning|reasoning_content|analysis|thought|thinking|internal|chain_of_thought|racioc[ií]nio|raciocinio|pensamento)\"?\\s*:\\s*(?:\"[^\"\\n]*(?:\\\\.[^\"\\n]*)*\"|[^\\n,}]+)",
            with: "",
            in: text
        )
    }
    
    /// Remove rótulos de processo no início de linha ("Pergunta:", "Resposta:", etc.).
    private static func removeInternalPrefixes(from text: String) -> String {
        replace(
            pattern: "(?m)^[\\s>*\\-]*(?:pr[oó]xima pergunta|pergunta|resposta final|resposta|racioc[ií]nio|pensamento|an[aá]lise|reasoning|thought|analysis|answer|question|final answer|output|json|t[ií]tulo|subt[ií]tulo|resultado)\\s*:\\s*",
            with: "",
            in: text
        )
    }
    
    private static func sanitizeJSONValue(_ value: Any) -> Any {
        switch value {
        case let dictionary as [String: Any]:
            var result: [String: Any] = [:]
            for (key, nested) in dictionary where !internalJSONKeys.contains(key.lowercased()) {
                result[key] = sanitizeJSONValue(nested)
            }
            return result
        case let array as [Any]:
            var values: [Any] = []
            values.reserveCapacity(array.count)
            for item in array {
                values.append(sanitizeJSONValue(item))
            }
            return values
        case let string as String:
            return sanitizeUserVisible(string)
        default:
            return value
        }
    }
    
    private static func removeJunkLines(from text: String) -> String {
        let junk = CharacterSet(charactersIn: "{}[],\"`")
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        let kept = lines.map(String.init).filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty || trimmed.rangeOfCharacter(from: junk.inverted) != nil
        }
        return kept.joined(separator: "\n")
    }
    
    private static func replace(pattern: String, with replacement: String, in text: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
}
