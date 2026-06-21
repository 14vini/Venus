import SwiftUI

private enum ZenithUIStyle {
    static let sectionSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 28
}

struct ZenithHeroSection: View {
    let userName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ola, \(userName)")
                .font(.system(.headline, design: .rounded, weight: .medium))
                .foregroundStyle(VenusTheme.textSecondary)

            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(VenusTheme.text)

            Text(subtitle)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ZenithEnergyCheckInSection: View {
    let latestCheckIn: EnergyCheckIn?
    let onSelectLevel: (EnergyLevel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ZenithUIStyle.sectionSpacing) {
            sectionHeader(
                eyebrow: "Check-in de energia",
                title: "Escolha o nivel real de hoje"
            )

            VStack(spacing: 12) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    ZenithEnergyLevelButton(
                        level: level,
                        isSelected: latestCheckIn?.energyLevel == level,
                        action: { onSelectLevel(level) }
                    )
                }
            }
        }
    }
}

struct ZenithSentinelInsightSection: View {
    let insight: SentinelInsight
    let trigger: PrimaryTrigger?

    var body: some View {
        VStack(alignment: .leading, spacing: ZenithUIStyle.sectionSpacing) {
            sectionHeader(
                eyebrow: "Sentinela invisivel",
                title: insight.title
            )

            VStack(alignment: .leading, spacing: 14) {
                Text(insight.message)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let trigger {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gatilho ativo")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(VenusTheme.textSecondary)

                        Text(trigger.summary)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(VenusTheme.text)

                        Text(trigger.adjustment.rationale)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }
                }
            }
            .padding(20)
            .background(glassShape(fill: fillColor(for: insight.severity)))
        }
    }

    private func fillColor(for severity: PatternSeverity) -> Color {
        switch severity {
        case .neutral:
            return Color.white.opacity(0.16)
        case .positive:
            return VenusTheme.accentGreen.opacity(0.18)
        case .warning:
            return VenusTheme.accentOrange.opacity(0.16)
        case .critical:
            return VenusTheme.validationError.opacity(0.18)
        }
    }
}

struct ZenithDebugActionsSection: View {
    let onStuckTap: () -> Void
    let onRecoveryTap: () -> Void
    let onWeeklySweepTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ZenithUIStyle.sectionSpacing) {
            sectionHeader(
                eyebrow: "Debug do Sentinela",
                title: "Dispare eventos locais"
            )

            HStack(spacing: 12) {
                debugButton(title: "Travei", systemImage: "pause.circle", tint: VenusTheme.accentOrange, action: onStuckTap)
                debugButton(title: "Recuperei", systemImage: "leaf.circle", tint: VenusTheme.accentGreen, action: onRecoveryTap)
                debugButton(title: "Sweep 7d", systemImage: "waveform.path.ecg", tint: VenusTheme.accentBlue, action: onWeeklySweepTap)
            }
        }
    }

    private func debugButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(VenusTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .padding(16)
            .background(glassShape(fill: Color.white.opacity(0.14)))
        }
        .buttonStyle(.plain)
    }
}

struct ZenithSentinelLogSection: View {
    let events: [PatternLogEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: ZenithUIStyle.sectionSpacing) {
            sectionHeader(
                eyebrow: "Logs invisiveis",
                title: "Eventos recentes"
            )

            VStack(spacing: 0) {
                if events.isEmpty {
                    Text("Nenhum evento registrado ainda. O painel de debug fica visivel nesta fase para validar o motor com calma.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                } else {
                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                        ZenithPatternLogRow(event: event)

                        if index < events.count - 1 {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .background(glassShape(fill: Color.white.opacity(0.14)))
        }
    }
}

struct ZenithEnergyLevelButton: View {
    let level: EnergyLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: level.sfSymbolName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.14))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(VenusTheme.text)

                    Text(level.supportCopy)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? iconColor : VenusTheme.textSecondary.opacity(0.5))
            }
            .padding(18)
            .background(
                glassShape(fill: isSelected ? iconColor.opacity(0.16) : Color.white.opacity(0.14))
            )
        }
        .buttonStyle(.plain)
    }

    private var iconColor: Color {
        switch level {
        case .critical:
            return VenusTheme.validationError
        case .regular:
            return VenusTheme.accentBlue
        case .full:
            return VenusTheme.accentGreen
        }
    }
}

struct ZenithPatternLogRow: View {
    let event: PatternLogEvent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(event.summary)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(event.kind.rawValue)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            }

            Spacer(minLength: 12)

            Text(event.createdAt, style: .time)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(VenusTheme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var dotColor: Color {
        switch event.severity {
        case .neutral:
            return VenusTheme.accentBlue
        case .positive:
            return VenusTheme.accentGreen
        case .warning:
            return VenusTheme.accentOrange
        case .critical:
            return VenusTheme.validationError
        }
    }
}

@ViewBuilder
private func sectionHeader(eyebrow: String, title: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(eyebrow.uppercased())
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(VenusTheme.textSecondary)

        Text(title)
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(VenusTheme.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private func glassShape(fill: Color) -> some View {
    RoundedRectangle(cornerRadius: ZenithUIStyle.cornerRadius, style: .continuous)
        .fill(fill)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: ZenithUIStyle.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ZenithUIStyle.cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
}

