//
//  VenusTextSanitizer.swift
//  Venus
//
//  Remove pensamento interno e JSON cru antes de qualquer texto chegar à UI.
//

import Foundation

/// Última linha de defesa contra raciocínio, tags internas e JSON na interface.
/// Não altera o filtro de streaming da camada de IA — atua só no que é exibido.
enum VenusTextSanitizer {
    static func sanitize(_ text: String) -> String {
        var clean = removeReasoningBlocks(from: text)
        clean = removeFencedBlocks(from: clean)
        clean = removeRawJSON(from: clean)
        clean = removeReasoningKeys(from: clean)
        return replace(pattern: "\\n{3,}", with: "\n\n", in: clean)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Limpeza

    private static func removeReasoningBlocks(from text: String) -> String {
        let patterns = [
            "<think>.*?</think>", "<thinking>.*?</thinking>",
            "<thought>.*?</thought>", "<reasoning>.*?</reasoning>",
            "<analysis>.*?</analysis>", "<internal>.*?</internal>",
            "\\[THOUGHT\\].*?\\[/THOUGHT\\]",
            "\\[REASONING\\].*?\\[/REASONING\\]",
            "\\[ANALYSIS\\].*?\\[/ANALYSIS\\]"
        ]
        var clean = text
        for pattern in patterns { clean = replace(pattern: pattern, with: "", in: clean) }

        for tag in ["<think", "<thinking", "<thought", "<reasoning", "<analysis", "[THOUGHT]", "[REASONING]"] {
            if let range = clean.range(of: tag, options: .caseInsensitive) {
                clean = String(clean[..<range.lowerBound])
            }
        }
        for tag in ["</think>", "</thinking>", "</thought>", "</reasoning>", "</analysis>", "[/THOUGHT]", "[/REASONING]"] {
            clean = clean.replacingOccurrences(of: tag, with: "", options: .caseInsensitive)
        }
        return clean
    }

    private static func removeFencedBlocks(from text: String) -> String {
        var clean = replace(pattern: "```(?:json|jsonc)?[^\\S\\n]*\\n[\\s\\S]*?```", with: "", in: text)
        clean = replace(pattern: "```(?:json|jsonc)?[^\\n]*?```", with: "", in: clean)
        return clean
    }

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
                if escaped { escaped = false }
                else if character == "\\" { escaped = true }
                else if character == "\"" { insideString = false }
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
            pattern: "\"?(?:reasoning|analysis|thought|raciocínio|raciocinio)\"?\\s*:\\s*(?:\"[^\"\\n]*(?:\\\\.[^\"\\n]*)*\"|[^\\n,}]+)",
            with: "",
            in: text
        )
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
