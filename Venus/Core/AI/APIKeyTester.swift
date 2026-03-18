//
//  APIKeyTester.swift
//  Venus
//
//  Testa se a API key do Gemini está válida
//

import Foundation
import GoogleGenerativeAI

class APIKeyTester {
    static func testAPIKey() async {
        print("🔑 Testando API Key do Gemini...")
        print("📋 API Key: \(AppConfig.geminiAPIKey.prefix(10))...")
        print("🤖 Modelo: \(AppConfig.geminiModel)")
        
        let model = GenerativeModel(
            name: AppConfig.geminiModel,
            apiKey: AppConfig.geminiAPIKey
        )
        
        do {
            print("🚀 Enviando requisição para o Gemini...")
            let response = try await model.generateContent("Diga apenas 'OK' se você conseguir me ouvir")
            
            if let text = response.text {
                print("✅ API Key VÁLIDA! Resposta: \(text)")
                print("✨ Gemini está funcionando corretamente!")
            } else {
                print("❌ API Key inválida - sem resposta")
            }
        } catch {
            print("❌ ERRO na API Key: \(error)")
            print("🔍 Detalhes do erro: \(error.localizedDescription)")
            
            // Verificar tipos específicos de erro
            if error.localizedDescription.contains("API_KEY_INVALID") {
                print("🚨 API Key é inválida!")
            } else if error.localizedDescription.contains("quota") {
                print("🚨 Limite de quota excedido!")
            } else if error.localizedDescription.contains("network") {
                print("🚨 Problema de rede!")
            } else if error.localizedDescription.contains("model") {
                print("🚨 Modelo inválido ou não encontrado!")
            } else {
                print("🚨 Erro desconhecido - verifique a conexão e configurações")
            }
        }
    }
}