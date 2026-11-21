//
//  MyDayEmptyStateView.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI

struct MyDayEmptyStateView: View {
    let onPlanWithVenus: () -> Void
    let onManualCreate: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RadialGradient(
                    colors: [
                        VenusTheme.primary.opacity(colorScheme == .dark ? 0.22 : 0.28),
                        VenusTheme.accentPurple.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 80
                )
                .frame(width: 150, height: 150)

                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [VenusTheme.primary, VenusTheme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Sua jornada começa aqui")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Text("Cada passo importa. Monte sua rotina com a Venus ou crie do seu jeito.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 12) {
                Button {
                    onPlanWithVenus()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                        Text("Planejar meu dia com a Venus")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        Capsule(style: .continuous)
                            .fill(colorScheme == .dark ? Color(hex: "3B3442") : Color(hex: "241E2B"))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onManualCreate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Criar rotina na mão")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(VenusTheme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
