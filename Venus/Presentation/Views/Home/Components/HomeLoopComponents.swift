//
//  HomeLoopComponents.swift
//  Venus
//

import SwiftUI

struct CheckInQuotaCard: View {
    let allowance: CheckInAllowance
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Check-ins de hoje")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                Spacer()
                Text(planLabel)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(planColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(planColor.opacity(0.14)))
            }

            Text(usageLabel)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)

            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: allowance.canCheckIn ? "plus.circle.fill" : "sparkles")
                        .font(.system(size: 16, weight: .bold))
                    Text(actionLabel)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(buttonGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(buttonBorder, lineWidth: allowance.canCheckIn ? 0.8 : 1.2)
                    )
                    .shadow(
                        color: allowance.canCheckIn
                            ? Color.black.opacity(0)
                            : Color(hex: "F2B53B").opacity(0.34),
                        radius: allowance.canCheckIn ? 0 : 10,
                        y: allowance.canCheckIn ? 0 : 4
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .opacity(allowance.canCheckIn ? 1 : 0.9)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 30)
    }

    private var planLabel: String {
        allowance.plan == .pro ? "VENUS PRO" : "FREE"
    }

    private var planColor: Color {
        allowance.plan == .pro ? Color(hex: "FFB020") : Color(hex: "FF3D00")
    }

    private var usageLabel: String {
        if allowance.isUnlimited {
            return "\(allowance.usedToday) check-in\(allowance.usedToday == 1 ? "" : "s") hoje (ilimitado)."
        }
        return "\(allowance.usedToday)/\(allowance.dailyLimit ?? 3) usados hoje."
    }

    private var actionLabel: String {
        if allowance.canCheckIn {
            return allowance.usedToday == 0 ? "Fazer check-in" : "Refazer check-in"
        }
        return "Desbloquear Venus Pro ilimitado"
    }

    private var buttonGradient: LinearGradient {
        if allowance.canCheckIn {
            return LinearGradient(
                colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [Color(hex: "DCA53A"), Color(hex: "F2C35A"), Color(hex: "C98A23")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var buttonBorder: Color {
        allowance.canCheckIn ? Color.white.opacity(0.12) : Color.white.opacity(0.42)
    }
}

struct DailyLoopCard: View {
    let completedSteps: Int
    let totalSteps: Int
    let hasCheckedIn: Bool
    let hasInsight: Bool
    let hasActionStarted: Bool
    let isLoadingInsights: Bool
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Status do Fluxo")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Spacer()

                Text("\(completedSteps)/\(totalSteps)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(VenusTheme.cardSurfaceStrong))
                    .overlay(Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1))
            }

            LoopStepRow(
                title: "Check-in emocional",
                subtitle: hasCheckedIn ? "Concluído" : "Pendente",
                icon: "face.smiling.inverse",
                isDone: hasCheckedIn
            )
            LoopStepRow(
                title: "Insight estrategico",
                subtitle: isLoadingInsights ? "Analisando..." : (hasInsight ? "Pronto" : "Aguardando check-in"),
                icon: "sparkles.rectangle.stack",
                isDone: hasInsight
            )
            LoopStepRow(
                title: "Executar micro-acao",
                subtitle: hasActionStarted ? "Iniciada hoje" : "Ainda nao iniciada",
                icon: "figure.mind.and.body",
                isDone: hasActionStarted
            )

            Button(action: action) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
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
            .disabled(isLoadingInsights)
            .opacity(isLoadingInsights ? 0.75 : 1)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 32)
    }
}

private struct LoopStepRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    isDone ? Color(hex: "FF5F15") : VenusTheme.textSecondary,
                    isDone ? Color(hex: "FF3D00") : VenusTheme.textSecondary.opacity(0.8)
                )
                .frame(width: 40, height: 40)
                .background(Circle().fill(isDone ? Color(hex: "FFE6DA") : VenusTheme.cardSurfaceStrong))
                .overlay(Circle().stroke(VenusTheme.cardBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            Spacer()

            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isDone ? Color(hex: "FF3D00") : VenusTheme.textSecondary.opacity(0.7))
        }
    }
}
