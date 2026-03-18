//
//  MoodCheckInHeaderHero.swift
//  Venus
//

import SwiftUI

struct MoodCheckInHeader: View {
    let ritualProgressLabel: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(VenusTheme.text)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(VenusTheme.cardSurface))
                    .overlay(Circle().stroke(VenusTheme.cardBorder, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar check-in")
            .accessibilityHint("Fecha esta tela sem salvar")

            Spacer()

            Text(ritualProgressLabel)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(VenusTheme.cardSurfaceStrong))
                .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
}

struct MoodCheckInHeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Como está seu\nmomento agora?")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .foregroundColor(VenusTheme.text)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("Escolha seu estado emocional, ajuste intensidade e marque o que mais influenciou seu dia.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 34)
    }
}
