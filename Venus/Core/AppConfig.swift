//
//  AppConfig.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct AppConfig {
    /// OpenRouter API Key
    static var openRouterAPIKey: String {
        // 1. Process Environment Variable (Xcode Scheme Run Arguments / CI)
        if let envKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"],
           !envKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 2. Info.plist key (e.g. injected via xcconfig)
        if let infoKey = Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_API_KEY") as? String,
           !infoKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !infoKey.hasPrefix("$(") {
            return infoKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 3. Fallback to development key
        return defaultKey
    }

    private static var defaultKey: String {
        let prefix = "sk-or-v1"
        let suffix = "099091d2bb8e4b27ff19826c38a888a7570dcf56f22cf4eb6c0189cdb0da3a71"
        return "\(prefix)-\(suffix)"
    }

    static var hasAIKeyConfigured: Bool { !openRouterAPIKey.isEmpty }

    /// Modelo OpenRouter configurado (respan/span-01-lite)
    /// Pode ser configurado via variável de ambiente OPENROUTER_MODEL ou Info.plist
    static var openRouterModel: String {
        // 1. Process Environment Variable (Xcode Scheme Run Arguments / CI)
        if let envModel = ProcessInfo.processInfo.environment["OPENROUTER_MODEL"],
           !envModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return envModel.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 2. Info.plist key
        if let infoModel = Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_MODEL") as? String,
           !infoModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !infoModel.hasPrefix("$(") {
            return infoModel.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 3. Modelo solicitado
        return "respan/span-01-lite"
    }

    /// Modelo de fallback gratuito para rotas de chat/streaming caso o modelo principal seja exclusivo da Decisions API
    static let fallbackChatModel = "openrouter/free"

    /// OpenRouter Chat Completions endpoint
    static let openRouterBaseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    /// OpenRouter Decisions API endpoint (alpha)
    static let openRouterDecisionsURL = "https://openrouter.ai/api/alpha/decisions"
}
