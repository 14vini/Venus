//
//  VenusDesiredHobbiesStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

@Observable
class VenusDesiredHobbiesStepModel {
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

struct VenusDesiredHobbiesStep: View {
    @Binding var userProfile: UserProfile
    @State private var model = VenusDesiredHobbiesStepModel()
    
    var selectedCount: Int {
        model.selectedHobbies.filter { $0.value }.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack{
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hobbies que Deseja")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(VenusTheme.text)
                    
                    if selectedCount > 0 {
                        Text("Quer aprender \(selectedCount) novo\(selectedCount != 1 ? "s" : "") hobby\(selectedCount != 1 ? "s" : ""). Ótimo!")
                            .font(.headline)
                            .foregroundColor(VenusTheme.darkGreen)
                            .fontWeight(.semibold)
                    } else {
                        Text("O que gostaria de aprender?")
                            .font(.headline)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            
            VenusDesiredHobbiesFlowLayout(
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
    VenusDesiredHobbiesStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
