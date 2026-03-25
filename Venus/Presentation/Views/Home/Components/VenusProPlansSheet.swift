//
//  VenusProPlansSheet.swift
//  Venus
//

import SwiftUI

struct VenusProPlansSheet: View {
    let freeDailyLimit: Int
    let onContinueToSupport: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
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
                        endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .offset(x: 90, y: -150)
                .blur(radius: 10)

            VStack(alignment: .leading, spacing: 0) {
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

                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 32)
                .padding(.bottom, 18)

                VenusProBadge()
                    .padding(.bottom, 14)

                Text("Desbloqueie check-ins ilimitados")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.08, green: 0.06, blue: 0.14))
                    .padding(.bottom, 10)

                Text("No plano Free você possui até **\(freeDailyLimit) check-ins** por dia. Com o Venus Pro, voce pode refazer seu check-in quantas vezes quiser e ver previsao emocional de 1, 3 e 7 dias.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(
                        colorScheme == .dark
                            ? Color.white.opacity(0.55)
                            : Color(red: 0.3, green: 0.25, blue: 0.40).opacity(0.85)
                    )
                    .padding(.bottom, 18)

                VStack(alignment: .leading, spacing: 10) {
                    planFeature(text: "Check-ins ilimitados ao longo do dia")
                    planFeature(text: "Insights e micro-ações mais avançados")
                    planFeature(text: "Por que da micro-acao com evidencias")
                    planFeature(text: "Previsao emocional em 1, 3 e 7 dias")
                    planFeature(text: "Fluxo premium com suporte dedicado")
                }
                .padding(.bottom, 24)

                VStack(spacing: 10) {
                    Button(action: onContinueToSupport) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                            Text("Quero desbloquear o Venus Pro")
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
                    .accessibilityLabel("Continuar para suporte do Venus Pro")

                    Button(action: { dismiss() }) {
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
                    .accessibilityLabel("Fechar planos do Venus Pro")
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

    private func planFeature(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.65, green: 0.35, blue: 1.0))

            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    colorScheme == .dark
                        ? Color.white.opacity(0.86)
                        : Color(red: 0.18, green: 0.12, blue: 0.28)
                )
        }
    }
}
