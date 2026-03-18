//
//  EmotionalAreaStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct EmotionalAreaStep: View {
    @Binding var userProfile: UserProfile
    @State private var selectedAreas: Set<String> = []
    
    private let emotionalAreas = [
        "Estresse", "Tristeza", "Solidão", "Culpa", "Raiva",
        "Insegurança", "Falta de Propósito", "Overwhelm"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            HStack{
                VStack(alignment: .leading, spacing: 8) {
                    Text("Áreas Emocionais")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(VenusTheme.text)
                    
                    if selectedAreas.count > 0 {
                        Text("Vamos cuidar de \(selectedAreas.count) área\(selectedAreas.count != 1 ? "s" : "") emocional\(selectedAreas.count != 1 ? "is" : "").")
                            .font(.headline)
                            .foregroundColor(VenusTheme.darkGreen)
                            .fontWeight(.semibold)
                    } else {
                        Text("Quais emoções mais afetam seu dia a dia?")
                            .font(.headline)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(emotionalAreas, id: \.self) { area in
                    
                        Button(action: {
                            if selectedAreas.contains(area) {
                                selectedAreas.remove(area)
                            } else {
                                selectedAreas.insert(area)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 12) {
                                        Image(systemName: iconForArea(area))
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedAreas.contains(area) ? .white : VenusTheme.darkGreen)
                                        
                                        Text(area)
                                            .font(.headline)
                                            .foregroundColor(selectedAreas.contains(area) ? .white : VenusTheme.text)
                                    }
                                    
                                    Text(descriptionForArea(area))
                                        .font(.caption)
                                        .foregroundColor(selectedAreas.contains(area) ? .white.opacity(0.8) : VenusTheme.textSecondary)
                                }
                                .padding(8)
                                
                                Spacer()
                                
                                if selectedAreas.contains(area) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(12)
                            .background(
                                selectedAreas.contains(area) ? VenusTheme.darkGreen : Color.white
                            )
                            .cornerRadius(20)
                            .contentShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(area)
                        .accessibilityAddTraits(selectedAreas.contains(area) ? [.isButton, .isSelected] : .isButton)
                    
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
        .onChange(of: selectedAreas) { _, newValue in
            userProfile.emotionalAreas = Array(newValue)
        }
        .onAppear {
            selectedAreas = Set(userProfile.emotionalAreas)
        }
    }
    
    private func iconForArea(_ area: String) -> String {
        let icons: [String: String] = [
            "Estresse": "exclamationmark.circle.fill",
            "Tristeza": "cloud.rain.fill",
            "Solidão": "person.slash.fill",
            "Culpa": "xmark.circle.fill",
            "Raiva": "flame.fill",
            "Insegurança": "questionmark.circle.fill",
            "Falta de Propósito": "magnifyingglass",
            "Overwhelm": "tornado"
        ]
        return icons[area] ?? "heart.fill"
    }
    
    private func descriptionForArea(_ area: String) -> String {
        let descriptions: [String: String] = [
            "Estresse": "Pressão e tensão do dia a dia",
            "Tristeza": "Sentimentos melancólicos e baixos",
            "Solidão": "Falta de conexão com outros",
            "Culpa": "Arrependimento e autocrítica",
            "Raiva": "Irritação e frustração",
            "Insegurança": "Dúvida sobre si mesmo",
            "Falta de Propósito": "Sensação de falta de direção",
            "Overwhelm": "Sensação de estar sobrecarregado"
        ]
        return descriptions[area] ?? ""
    }
}

#Preview {
    EmotionalAreaStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
