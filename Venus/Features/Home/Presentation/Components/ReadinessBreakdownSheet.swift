//
//  ReadinessBreakdownSheet.swift
//  Venus
//
//  Created by Kaua on 29/09/26.
//

import SwiftUI

public struct ReadinessBreakdownSheet: View {
    let assessment: ReadinessEnergyAssessment
    var onActionSelected: ((ReadinessActionRecommendation.ActionCategory) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var breakdown: ReadinessBreakdown? { assessment.breakdown }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealColor: Color { Color(hex: "0D9488") }

    public init(
        assessment: ReadinessEnergyAssessment,
        onActionSelected: ((ReadinessActionRecommendation.ActionCategory) -> Void)? = nil
    ) {
        self.assessment = assessment
        self.onActionSelected = onActionSelected
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Header Score Card
                    headerScoreCard

                    // Action Recommendation
                    if let rec = breakdown?.recommendation {
                        recommendationCard(rec)
                    }

                    // Three Pillars Section
                    pillarsSection

                    // Biometric Deep Dive
                    biometricsSection

                    // Subjective & Mental Context Section
                    subjectiveSection

                    // Circadian Energy Flow Section
                    if let curve = breakdown?.intradayCurve {
                        intradayCurveSection(curve)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(VenusTheme.background.ignoresSafeArea())
            .navigationTitle("Detalhamento da Bateria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(VenusTheme.primary)
                }
            }
        }
    }
}

// MARK: - Subviews

private extension ReadinessBreakdownSheet {
    var headerScoreCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(isDark ? mintColor.opacity(0.2) : tealColor.opacity(0.15), lineWidth: 6)
                        .frame(width: 68, height: 68)

                    Circle()
                        .trim(from: 0, to: assessment.percentage)
                        .stroke(
                            LinearGradient(
                                colors: [isDark ? Color(hex: "1BE3B0") : tealColor, isDark ? mintColor : Color(hex: "0F766E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 68, height: 68)

                    Text("\(assessment.percentage100)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(isDark ? mintColor : tealColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(assessment.level.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)

                        Text(assessment.level.emoji)
                            .font(.system(size: 16))
                    }

                    Text(assessment.stateSubtitle.isEmpty ? "Prontidão equilibrada para o seu ritmo." : assessment.stateSubtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
        .padding(18)
        .neumorphicCard(cornerRadius: 24, style: .raised, depth: 8)
    }

    func recommendationCard(_ rec: ReadinessActionRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: rec.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(VenusTheme.primary)

                Text("Sugestão de Ação")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.primary)
                    .textCase(.uppercase)
            }

            Text(rec.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(VenusTheme.text)

            Text(rec.subtitle)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                dismiss()
                onActionSelected?(rec.category)
            } label: {
                HStack {
                    Text(rec.actionButtonTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(VenusTheme.primaryGradient)
                )
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorphicCard(cornerRadius: 24, style: .bordered, depth: 8)
    }

    var pillarsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pilares Principais")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                pillarMiniCard(metric: assessment.focusMetric, icon: "scope")
                pillarMiniCard(metric: assessment.bodyMetric, icon: "atom")
                pillarMiniCard(metric: assessment.sleepMetric, icon: "bed.double.fill")
            }
        }
    }

    func pillarMiniCard(metric: ReadinessPillarMetric, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isDark ? mintColor : tealColor)

                Spacer()

                Image(systemName: metric.isCompleted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(metric.isCompleted ? (isDark ? mintColor : tealColor) : VenusTheme.accentOrange)
            }

            Text(metric.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(VenusTheme.text)

            Text(metric.detail ?? (metric.isCompleted ? "Estável" : "Atenção"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        .neumorphicCard(cornerRadius: 20, style: .raised, depth: 6)
    }

    var biometricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Sinais Fisiológicos & HealthKit")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .textCase(.uppercase)

                Spacer()

                if assessment.biometricsUsed {
                    Text("Conectado")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(isDark ? mintColor : tealColor)
                } else {
                    Text("Modo Subjetivo")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textTertiary)
                }
            }

            VStack(spacing: 10) {
                // HRV
                metricRow(
                    icon: "heart.fill",
                    title: "Variabilidade Cardíaca (HRV)",
                    value: breakdown?.hrvCurrent != nil ? "\(Int(breakdown!.hrvCurrent!)) ms" : "Sem dados",
                    subtitle: hrvSubtitleText
                )

                // Sleep
                metricRow(
                    icon: "bed.double.fill",
                    title: "Sono & Repouso",
                    value: breakdown?.sleepDurationHours != nil ? String(format: "%.1fh", breakdown!.sleepDurationHours!) : "Sem dados",
                    subtitle: sleepSubtitleText
                )

                // RHR & Dip
                metricRow(
                    icon: "waveform.path.ecg",
                    title: "FC Repouso & Queda Noturna",
                    value: breakdown?.restingHR != nil ? "\(Int(breakdown!.restingHR!)) bpm" : "Sem dados",
                    subtitle: rhrSubtitleText
                )

                // Yesterday strain
                metricRow(
                    icon: "flame.fill",
                    title: "Carga Física de Ontem",
                    value: breakdown?.yesterdayActiveEnergy != nil ? "\(Int(breakdown!.yesterdayActiveEnergy!)) kcal" : "Sem treinos",
                    subtitle: strainSubtitleText
                )
            }
            .padding(16)
            .neumorphicCard(cornerRadius: 24, style: .raised, depth: 8)
        }
    }

    var subjectiveSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mente & Contexto Emocional")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 10) {
                metricRow(
                    icon: "face.smiling.fill",
                    title: "Check-in do Dia",
                    value: String(format: "%.1f / 10", breakdown?.subjectiveScore ?? 7.5),
                    subtitle: "Sinal subjetivo ponderado a partir do seu ritual diário."
                )

                if let delta = breakdown?.chatDelta, abs(delta) > 0.1 {
                    metricRow(
                        icon: "sparkles",
                        title: "Impacto das Conversas",
                        value: String(format: "%+.1f pts", delta),
                        subtitle: "Decaimento suave de meia-vida aplicado sobre reflexões recentes."
                    )
                }
            }
            .padding(16)
            .neumorphicCard(cornerRadius: 24, style: .raised, depth: 8)
        }
    }

    func intradayCurveSection(_ curve: IntradayEnergyCurve) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previsão Circadiana do Dia")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .textCase(.uppercase)

            IntradayEnergyCurveView(curve: curve, baseScore: assessment.score)
        }
    }

    func metricRow(icon: String, title: String, value: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isDark ? mintColor : tealColor)
                .frame(width: 32, height: 32)
                .neumorphicCircle(style: .sunken, depth: 3)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(VenusTheme.text)

                    Spacer()

                    Text(value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isDark ? mintColor : tealColor)
                }

                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .neumorphicCard(cornerRadius: 16, style: .sunken, depth: 4)
    }

    var hrvSubtitleText: String {
        guard let ratio = breakdown?.hrvRatio, let base = breakdown?.hrvBaselineAverage else {
            return "Aguardando 3+ dias de uso do relógio para estabelecer sua média basal."
        }
        let pct = Int((ratio - 1.0) * 100)
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(pct)% em relação à sua média móvel de 7 dias (\(Int(base)) ms)."
    }

    var sleepSubtitleText: String {
        guard let deepREM = breakdown?.restorativeSleepHours else {
            return "Calculado a partir de duração total e proporção de sono profundo/REM."
        }
        return String(format: "Inclui %.1fh de sono reparador (Profundo + REM).", deepREM)
    }

    var rhrSubtitleText: String {
        if let dip = breakdown?.hrDipPercentage {
            return String(format: "Queda noturna de %.1f%% na frequência cardíaca durante o sono.", dip)
        }
        return "Batimentos cardíacos em repouso ao longo das últimas 24h."
    }

    var strainSubtitleText: String {
        if let mins = breakdown?.yesterdayWorkoutDurationMinutes, mins > 0 {
            return String(format: "%.0f minutos de treino registrados ontem.", mins)
        }
        return "Gasto de energia ativa capturado pelo Apple Watch."
    }
}

#Preview {
    ReadinessBreakdownSheet(assessment: .sampleDefault)
        .preferredColorScheme(.dark)
}
