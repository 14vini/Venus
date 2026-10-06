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

        // 3. Sem chave: retorna vazio e o app usa fallbacks locais
        return ""
    }

    static var hasAIKeyConfigured: Bool { !openRouterAPIKey.isEmpty }

    /// Modelo OpenRouter exclusivo
    static let openRouterModel = "inclusionai/ling-3.0-flash-sante:free"

    /// OpenRouter Chat Completions endpoint
    static let openRouterBaseURL = "https://openrouter.ai/api/v1/chat/completions"
}
