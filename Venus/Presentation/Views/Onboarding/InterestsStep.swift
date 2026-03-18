//
//  InterestsStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

@Observable
class InterestsStepModel {
    var selectedInterests: [String: Bool] = [
        "Tecnologia": false,
        "Natureza": false,
        "Artes": false,
        "Esportes": false,
        "Culinária": false,
        "Música": false,
        "Leitura": false,
        "Viagens": false,
        "Fotografia": false,
        "Filmes": false,
        "Meditação": false,
        "Educação": false,
        "Dança": false,
        "Jogos": false,
        "Moda": false,
        "Bem-estar": false,
        "Arquitetura": false,
        "História": false,
        "Ciência": false,
        "Filosofia": false,
        "Desenho": false,
        "Escrita": false,
        "Espiritualidade": false,
        "Humor": false
    ]
}

struct InterestsStep: View {
    @Binding var userProfile: UserProfile
    @State private var model = InterestsStepModel()
    
    var selectedCount: Int {
        model.selectedInterests.filter { $0.value }.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seus Interesses")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(VenusTheme.text)
                    
                    if selectedCount > 0 {
                        Text("Você escolheu \(selectedCount) interesse\(selectedCount != 1 ? "s" : ""). Ótimo!")
                            .font(.headline)
                            .foregroundColor(VenusTheme.darkGreen)
                            .fontWeight(.semibold)
                    } else {
                        Text("Selecione o que você gosta")
                            .font(.headline)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            
            
                VenusInterestsFlowLayout(
                    items: Array(model.selectedInterests.keys),
                    selectedItems: model.selectedInterests,
                    onSelectionChange: { interest in
                        model.selectedInterests[interest]?.toggle()
                    }
                )
                .padding(.horizontal, 24)
            

        }
        .padding(.top, 24)
        .padding(.bottom, 12)
        .onChange(of: model.selectedInterests) { _, newValue in
            userProfile.interests = newValue.filter { $0.value }.map { $0.key }
        }
        .onAppear {
            for interest in userProfile.interests {
                model.selectedInterests[interest] = true
            }
        }
    }
}

#Preview {
    InterestsStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
