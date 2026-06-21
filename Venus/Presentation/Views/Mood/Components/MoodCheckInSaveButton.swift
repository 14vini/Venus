//
//  MoodCheckInSaveButton.swift
//  Venus
//
//  Updated by Kaua on 18/03/26.

import SwiftUI

struct MoodCheckInSaveButton: View {
    let isSaving: Bool
    var isReady: Bool = true
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isReady ? "checkmark.seal.fill" : "battery.25")
                        .font(.system(size: 16, weight: .bold))
                }

                Text(isSaving ? "Salvando..." : (isReady ? "Salvar" : "Escolher energia"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundColor(isReady ? Color(UIColor.systemBackground) : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isReady ? Color.primary : VenusTheme.validationError.opacity(0.8))
            )
            .shadow(color: (isReady ? Color.primary : VenusTheme.validationError).opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityLabel("Salvar check-in")
        .accessibilityHint("Salva seu estado atual e gera uma sugestão")
    }
}
