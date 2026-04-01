//
//  HobbiesStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

@Observable
class HobbiesStepModel {
    var selectedHobbies: [String: Bool] = [
        "Leitura": false,
        "Exercícios": false,
        "Culinária": false,
        "Jardinagem": false,
        "Música": false,
        "Desenho": false,
        "Fotografia": false,
        "Caminhada": false,
        "Ioga": false,
        "Meditação": false,
        "Escrita": false,
        "Dança": false,
        "Natação": false,
        "Ciclismo": false,
        "Pintura": false,
        "Artesanato": false,
        "Jogos": false,
        "Cinema": false
    ]
}

struct HobbiesStep: View {
    @Binding var userProfile: UserProfile
    @State private var model = HobbiesStepModel()
    
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
                eyebrow: "hobbies",
                title: "O que você já pratica?",
                subtitle: "Isso ajuda a sugerir ações e rituais que combinam com você.",
                systemImage: "leaf.fill",
                tint: VenusTheme.accentGreen,
                accessory: selectedAccessory
            )

            VenusHobbiesFlowLayout(
                items: Array(model.selectedHobbies.keys),
                selectedItems: model.selectedHobbies,
                tint: VenusTheme.accentGreen,
                onSelectionChange: { hobby in
                    model.selectedHobbies[hobby]?.toggle()
                }
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .onChange(of: model.selectedHobbies) { _, newValue in
            userProfile.currentHobbies = newValue.filter { $0.value }.map { $0.key }
        }
        .onAppear {
            for hobby in userProfile.currentHobbies {
                model.selectedHobbies[hobby] = true
            }
        }
    }
}

#Preview {
    HobbiesStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
