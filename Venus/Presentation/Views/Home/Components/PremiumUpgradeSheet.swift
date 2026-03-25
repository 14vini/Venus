//
//  PremiumUpgradeSheet.swift
//  Venus
//

import SwiftUI

struct PremiumUpgradeSheet: View {
    let freeDailyLimit: Int
    let onDismiss: () -> Void
    let onSeePlans: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {

            // Brilho decorativo roxo — adapta opacidade ao tema
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.6, green: 0.3, blue: 1.0)
                                .opacity(colorScheme == .dark ? 0.28 : 0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: 100, y: -140)
                .blur(radius: 10)

            VStack(alignment: .leading, spacing: 0) {

                // ── Ícone ──────────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.65, green: 0.35, blue: 1.0),
                                    Color(red: 0.45, green: 0.15, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: Color(red: 0.6, green: 0.3, blue: 1.0)
                                .opacity(colorScheme == .dark ? 0.5 : 0.3),
                            radius: 16,
                            y: 6
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 32)
                .padding(.bottom, 18)

                // ── Badge — mesmo padrão de HomeHeroCard ──────────
                VenusProBadge()
                    .padding(.bottom, 14)

                // ── Título ────────────────────────────────────────
                Text("Limite diário atingido")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.08, green: 0.06, blue: 0.14))
                    .padding(.bottom, 10)

                // ── Descrição ─────────────────────────────────────
                Text("No plano Free voce pode fazer ate **\(freeDailyLimit) check-ins** por dia. Com Venus Pro, seus check-ins sao ilimitados e voce libera previsao emocional com impacto da micro-acao.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(
                        colorScheme == .dark
                            ? Color.white.opacity(0.55)
                            : Color(red: 0.3, green: 0.25, blue: 0.40).opacity(0.85)
                    )
                    .padding(.bottom, 30)

                // ── Botões ────────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Button(action: onSeePlans) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Ver Venus Pro")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.65, green: 0.35, blue: 1.0),
                                        Color(red: 0.45, green: 0.15, blue: 0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                    ),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                            )
                            .shadow(
                                color: Color(red: 0.55, green: 0.25, blue: 0.95)
                                    .opacity(colorScheme == .dark ? 0.50 : 0.25),
                                radius: 12,
                                y: 5
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ver planos do Venus Pro")
                    .accessibilityHint("Abre os detalhes do plano premium")

                    Button(action: onDismiss) {
                        Text("Agora não")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.38)
                                    : Color(red: 0.3, green: 0.25, blue: 0.40).opacity(0.50)
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fechar aviso de premium")
                }
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 28)
            .venusProGlassCardStyle(cornerRadius: 34)
            .padding(.horizontal, 18)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }
}
