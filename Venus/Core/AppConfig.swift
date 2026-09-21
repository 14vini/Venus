//
//  AppConfig.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct AppConfig {
    /// Google Gemini API Key
    /// NOTE: In production, move this to .xcconfig or environment variables
    static let geminiAPIKey = ""
//    "AIzaSyBCADUucwcooQm2619s17bXtvwgT4WqYe4"
    
    /// Gemini Model to use
    static let geminiModel = "gemini-3.5-flash"
}
