//
//  VenusHobbiesStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

@Observable
class VenusHobbiesStepModel {
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

struct VenusHobbiesStep: View {
    @Binding var userProfile: UserProfile
    @State private var model = VenusHobbiesStepModel()
    
    var selectedCount: Int {
        model.selectedHobbies.filter { $0.value }.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack{
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hobbies Atuais")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(VenusTheme.text)
                    
                    if selectedCount > 0 {
                        Text("Você pratica \(selectedCount) hobby\(selectedCount != 1 ? "s" : ""). Que legal!")
                            .font(.headline)
                            .foregroundColor(VenusTheme.darkGreen)
                            .fontWeight(.semibold)
                    } else {
                        Text("Quais hobbies você já pratica?")
                            .font(.headline)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            VenusHobbiesFlowLayout(
                items: Array(model.selectedHobbies.keys),
                selectedItems: model.selectedHobbies,
                onSelectionChange: { hobby in
                    model.selectedHobbies[hobby]?.toggle()
                }
            )
            .padding(.horizontal, 24)

        }
        .padding(.top, 24)
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
    VenusHobbiesStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
