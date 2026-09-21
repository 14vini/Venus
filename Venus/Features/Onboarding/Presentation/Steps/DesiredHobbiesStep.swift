//
//  DesiredHobbiesStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

@Observable
class DesiredHobbiesStepModel {
    var selectedHobbies: [String: Bool] = [
        "Meditação": false,
        "Ioga Avançada": false,
        "Fotografia Profissional": false,
        "Escrita Criativa": false,
        "Música": false,
        "Culinária Gourmet": false,
        "Desenho": false,
        "Natação": false,
        "Pilates": false,
        "Línguas": false,
        "Artes Marciais": false,
        "Poesia": false,
        "Instrumento Musical": false,
        "Cerâmica": false,
        "Surf": false,
        "Dança de Salsa": false,
        "Stand-up": false,
        "Produção Musical": false,
        "Parkour": false,
        "Costura": false,
        "Terapia Holística": false,
        "Cinematografia": false
    ]
}

struct DesiredHobbiesStep: View {
    @Binding var userProfile: UserProfile
    @State private var model = DesiredHobbiesStepModel()
    
    var selectedCount: Int {
        model.selectedHobbies.filter { $0.value }.count
    }

    private var selectedAccessory: String? {
        guard selectedCount > 0 else { return nil }
        return "\(selectedCount) selecionado\(selectedCount == 1 ? "" : "s")"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "novos hobbies",
                title: "O que você quer aprender?",
                subtitle: "Eu uso isso para sugerir caminhos e práticas que puxam você pra frente.",
                systemImage: "sparkles.rectangle.stack.fill",
                tint: VenusTheme.accentPurple,
                accessory: selectedAccessory
            )

            VenusDesiredHobbiesFlowLayout(
                items: Array(model.selectedHobbies.keys),
                selectedItems: model.selectedHobbies,
                tint: VenusTheme.accentPurple,
                onSelectionChange: { hobby in
                    model.selectedHobbies[hobby]?.toggle()
                }
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .onChange(of: model.selectedHobbies) { _, newValue in
            userProfile.desiredHobbies = newValue.filter { $0.value }.map { $0.key }
        }
        .onAppear {
            for hobby in userProfile.desiredHobbies {
                model.selectedHobbies[hobby] = true
            }
        }
    }
}

#Preview {
    DesiredHobbiesStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
