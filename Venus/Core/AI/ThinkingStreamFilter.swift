//
//  ThinkingStreamFilter.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import Foundation

/// Real-time stream filter that suppresses model reasoning/thought tags (<think>, <thought>, etc.)
/// and only emits the actual conversational response to the user.
final class ThinkingStreamFilter {
    private var isInsideThinking: Bool = false
    private var buffer: String = ""
    
    private let openTags = [
        "<think>", "<thought>", "<reasoning>",
        "[THOUGHT]", "[REASONING]", "<internal>"
    ]
    
    private let closeTags = [
        "</think>", "</thought>", "</reasoning>",
        "[/THOUGHT]", "[/REASONING]", "</internal>"
    ]
    
    /// Processes an incoming streaming chunk and returns only clean user-visible tokens
    func process(chunk: String) -> String {
        buffer += chunk
        var result = ""
        
        while !buffer.isEmpty {
            if isInsideThinking {
                // Look for any closing tag
                var earliestCloseRange: Range<String.Index>? = nil
                
                for tag in closeTags {
                    if let range = buffer.range(of: tag, options: .caseInsensitive) {
                        if earliestCloseRange == nil || range.lowerBound < earliestCloseRange!.lowerBound {
                            earliestCloseRange = range
                        }
                    }
                }
                
                if let closeRange = earliestCloseRange {
                    // Discard everything up to the end of the closing tag
                    buffer = String(buffer[closeRange.upperBound...])
                    isInsideThinking = false
                    
                    // Trim leading whitespace/newlines immediately following the closing tag
                    while let first = buffer.first, first.isWhitespace || first.isNewline {
                        buffer.removeFirst()
                    }
                } else {
                    // Still inside thinking tag, no full closing tag found.
                    // Keep only enough characters at the end that could be the start of a closing tag.
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
                // Not inside thinking. Look for an opening tag
                var earliestOpenRange: Range<String.Index>? = nil
                
                for tag in openTags {
                    if let range = buffer.range(of: tag, options: .caseInsensitive) {
                        if earliestOpenRange == nil || range.lowerBound < earliestOpenRange!.lowerBound {
                            earliestOpenRange = range
                        }
                    }
                }
                
                if let openRange = earliestOpenRange {
                    // Emit everything before the open tag
                    let textBefore = String(buffer[..<openRange.lowerBound])
                    result += textBefore
                    
                    // Move buffer past the open tag and mark thinking active
                    buffer = String(buffer[openRange.upperBound...])
                    isInsideThinking = true
                } else {
                    // Check if the end of buffer could be a partial prefix of an open tag
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
        
        return result
    }
    
    /// Flushes any remaining clean text when the stream terminates
    func flush() -> String {
        guard !isInsideThinking else {
            buffer = ""
            return ""
        }
        let remaining = buffer
        buffer = ""
        return remaining
    }
    
    /// Static utility to strip all thinking tags and reasoning blocks from full text
    static func clean(_ text: String) -> String {
        var clean = text
        
        let thinkingRegexes = [
            "(?s)<think>.*?</think>",
            "(?s)<thought>.*?</thought>",
            "(?s)<reasoning>.*?</reasoning>",
            "(?s)<internal>.*?</internal>",
            "(?s)\\[THOUGHT\\].*?\\[/THOUGHT\\]",
            "(?s)\\[REASONING\\].*?\\[/REASONING\\]"
        ]
        
        for pattern in thinkingRegexes {
            clean = clean.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        let orphanTags = [
            "<think>", "</think>", "<thought>", "</thought>",
            "<reasoning>", "</reasoning>", "<internal>", "</internal>",
            "[THOUGHT]", "[/THOUGHT]", "[REASONING]", "[/REASONING]"
        ]
        
        for tag in orphanTags {
            clean = clean.replacingOccurrences(of: tag, with: "")
        }
        
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
