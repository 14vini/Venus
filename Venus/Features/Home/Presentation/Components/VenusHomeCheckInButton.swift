//
//  VenusHomeCheckInButton.swift
//  Venus
//
//  CTA da Home em Liquid Glass: um círculo com "+" igual ao botão de nova busca
//  da tab bar do iOS. Sem pill larga — o rótulo, quando necessário, fica abaixo.
//

import SwiftUI

/// Botão circular de check-in. Acessibilidade mantém o rótulo completo
/// "Fazer check-in de hoje"; visualmente só o "+" e um rótulo curto.
struct VenusHomeCheckInButton: View {
    let hasCheckedInToday: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    // Destaque suave atrás do vidro, sem criar um blob de fundo.
                    Circle()
                        .fill(
                            VenusHomeJourneyPalette.lilac.opacity(colorScheme == .dark ? 0.14 : 0.20)
                        )
                        .blur(radius: 14)
                        .frame(width: 78, height: 78)

                    Circle()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.42))
                        .glassEffect(.regular.interactive(), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white.opacity(colorScheme == .dark ? 0.14 : 0.62),
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .foregroundStyle(VenusTheme.accentPurple)
                        .accessibilityHidden(true)
                }
                .frame(width: 72, height: 72)
                .contentShape(Circle())

                Text(hasCheckedInToday ? "Novo momento" : "Check-in")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: hasCheckedInToday)
            }
        }
        .buttonStyle(VenusHomePressableButtonStyle())
        .accessibilityLabel("Fazer check-in de hoje")
        .accessibilityHint(hasCheckedInToday ? "Registra um novo momento." : "Registra o momento de hoje.")
    }
}

#Preview {
    VStack(spacing: 40) {
        VenusHomeCheckInButton(hasCheckedInToday: false) {}
        VenusHomeCheckInButton(hasCheckedInToday: true) {}
    }
    .padding()
    .background(VenusHomeJourneyBackground())
}
