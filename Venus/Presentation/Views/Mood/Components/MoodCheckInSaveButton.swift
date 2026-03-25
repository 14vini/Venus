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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isReady ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                }

                Text(isSaving ? "Salvando..." : (isReady ? "Salvar check-in" : "Campos faltando"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isReady
                                ? [VenusTheme.moodMintStrong, VenusTheme.accentGreen]
                                : [VenusTheme.validationError.opacity(0.85), VenusTheme.validationError],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: (isReady ? VenusTheme.moodMintStrong : VenusTheme.validationError).opacity(0.28), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityLabel("Salvar check-in")
        .accessibilityHint("Salva seu estado atual e gera uma sugestão")
    }
}
