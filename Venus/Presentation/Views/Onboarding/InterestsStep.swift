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
    @State private var searchText: String = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var selectedCount: Int {
        model.selectedInterests.filter { $0.value }.count
    }

    private var selectedAccessory: String? {
        guard selectedCount > 0 else { return nil }
        return "\(selectedCount) selecionado\(selectedCount == 1 ? "" : "s")"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "interesses",
                title: "O que te dá energia?",
                subtitle: "Escolha alguns temas para eu calibrar o seu tom e as sugestões.",
                systemImage: "sparkles",
                tint: VenusTheme.accentBlue,
                accessory: selectedAccessory
            )

            searchField

            VenusInterestsFlowLayout(
                items: filteredItems,
                selectedItems: model.selectedInterests,
                tint: VenusTheme.accentBlue,
                onSelectionChange: { interest in
                    model.selectedInterests[interest]?.toggle()
                }
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
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

    private var filteredItems: [String] {
        let allItems = Array(model.selectedInterests.keys)
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allItems }
        return allItems.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(VenusTheme.textSecondary)

            TextField("Buscar interesses", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(VenusTheme.text)
                .tint(VenusTheme.accentBlue)

            if !searchText.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(VenusTheme.textSecondary.opacity(0.8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpar busca")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.62 : 0.94)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.22),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .blendMode(.overlay)
                )
        )
        .accessibilityLabel("Buscar interesses")
    }
}

#Preview {
    InterestsStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
