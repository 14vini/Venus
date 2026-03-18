//
//  MoodCheckInSaveButton.swift
//  Venus
//

import SwiftUI

struct MoodCheckInSaveButton: View {
    let isSaving: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                    Text("Salvar e receber sugestão")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityLabel("Salvar check-in")
        .accessibilityHint("Salva seu estado atual e gera uma sugestão")
    }
}
