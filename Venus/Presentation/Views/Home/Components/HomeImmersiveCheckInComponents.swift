//
//  HomeImmersiveCheckInComponents.swift
//  Venus
//
//  Created by Kaua on 24/03/26.
//

import SwiftUI

struct HomeImmersiveCheckInHeroSection: View {
    let selectedMood: MoodType?
    let hasCheckedInToday: Bool
    let progressLabel: String
    let statusLabel: String
    let isSelectionLocked: Bool
    let onSelectMood: (MoodType) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 10) {
                VenusGlassPill(
                    title: progressLabel,
                    systemImage: "sparkles"
                )

                if let selectedMood {
                    VenusGlassPill(
                        title: selectedMood.rawValue,
                        systemImage: "checkmark.circle.fill",
                        tint: Color(hex: selectedMood.colorHex)
                    )
                } else {
                    VenusGlassPill(
                        title: statusLabel,
                        systemImage: hasCheckedInToday ? "heart.fill" : "circle.dashed",
                        tint: hasCheckedInToday ? VenusTheme.accentGreen : VenusTheme.moodMintStrong
                    )
                }
            }

            VenusMoodMascotOrb(
                mood: selectedMood,
                size: 250
            )
                .padding(.top, 6)

            VStack(spacing: 10) {
                Text("Como você está\nse sentindo agora?")
                    .font(.system(size: 38, weight: .black, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(VenusTheme.text)

                Text(heroSubtitle)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VenusMoodWaveform()

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    HomeFeelingChip(
                        title: mood.rawValue,
                        isSelected: selectedMood == mood,
                        tint: Color(hex: mood.colorHex),
                        action: {
                            guard !isSelectionLocked else { return }
                            onSelectMood(mood)
                        }
                    )
                    .allowsHitTesting(!isSelectionLocked)
                }
            }

            if isSelectionLocked {
                Text("Seu check-in de hoje já está salvo. Toque no pop-up de vidro para ver como liberar mais atualizações.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(hasCheckedInToday
                     ? "Escolha a emoção mais próxima do agora e eu abro uma nova atualização do check-in."
                     : "Escolha o estado mais próximo e eu abro o check-in completo para você.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 620)
    }

    private var heroSubtitle: String {
        if isSelectionLocked {
            return "Seu estado de hoje já foi salvo. Quando quisermos, a gente libera novas atualizações."
        }

        if hasCheckedInToday {
            return "Escolha a opção mais próxima para abrir uma nova atualização do check-in."
        }

        return "Escolha a opção mais próxima e eu abro o check-in completo para você."
    }
}

struct HomeInlineCheckInDetailsSection: View {
    let selectedMood: MoodType
    let progressLabel: String
    @ObservedObject var viewModel: MoodCheckInViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Text("Continue o check-in")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Spacer(minLength: 12)

                VenusGlassPill(
                    title: progressLabel,
                    systemImage: "arrow.down.circle.fill"
                )
            }

            HStack(spacing: 14) {
                Text(selectedMood.emoji)
                    .font(.system(size: 34))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Você escolheu \(selectedMood.rawValue.lowercased()).")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text("Agora completa o contexto para a Home e a tela de reflexões entenderem melhor o seu momento.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(cornerRadius: 28, opacity: 0.78)

            MoodCheckInDetailsCard(
                selectedIntensity: $viewModel.selectedIntensity,
                quickTags: viewModel.quickTags,
                selectedTags: viewModel.selectedTags,
                onToggleTag: viewModel.toggleTag,
                affectedAreas: viewModel.affectedAreas,
                selectedAffectedArea: $viewModel.selectedAffectedArea,
                onSelectAffectedArea: viewModel.selectAffectedArea,
                missingAffectedArea: viewModel.isMissing(.affectedArea),
                energyLevels: viewModel.energyLevels,
                selectedEnergyLevel: $viewModel.selectedEnergyLevel,
                onSelectEnergyLevel: viewModel.selectEnergyLevel,
                missingEnergyLevel: viewModel.isMissing(.energyLevel),
                availableTimes: viewModel.availableTimes,
                selectedAvailableTime: $viewModel.selectedAvailableTime,
                onSelectAvailableTime: viewModel.selectAvailableTime,
                missingAvailableTime: viewModel.isMissing(.availableTime),
                controlLevels: viewModel.controlLevels,
                selectedControlLevel: $viewModel.selectedControlLevel,
                onSelectControlLevel: viewModel.selectControlLevel,
                missingControlLevel: viewModel.isMissing(.controlLevel),
                selectedMentalClarity: $viewModel.selectedMentalClarity,
                sleepQualities: viewModel.sleepQualities,
                selectedSleepQuality: $viewModel.selectedSleepQuality,
                onSelectSleepQuality: viewModel.selectSleepQuality,
                bodySignalOptions: viewModel.bodySignalOptions,
                selectedBodySignals: viewModel.selectedBodySignals,
                onToggleBodySignal: viewModel.toggleBodySignal,
                note: $viewModel.note
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeReflectionsPreviewSection: View {
    let mood: MoodType?
    let intensity: Int?
    let tags: [String]
    let bodySignals: [String]
    let energyLevel: MoodEnergyLevel?
    let affectedArea: MoodAffectedArea?
    let weeklyTrend: WeeklyEmotionalTrend?
    let patternAlert: PatternAlert?
    let weeklyInsights: WeeklyStrategicInsights?
    let action: NextBestAction?
    let isLoadingInsights: Bool
    var onReasonTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reflexões")
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .foregroundColor(VenusTheme.text)

                    Text(isLoadingInsights ? "Analisando seu momento..." : "Leitura do seu dia.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }

                Spacer(minLength: 12)

                VenusGlassPill(
                    title: isLoadingInsights ? "Analisando" : "Prévia",
                    systemImage: isLoadingInsights ? "hourglass" : "sparkles"
                )
            }

            // Lead card — direction of the day
            HomeReflectionLeadCard(
                title: leadTitle,
                detail: leadDetail,
                eyebrow: leadEyebrow,
                pills: leadPills,
                onReasonTap: action != nil ? onReasonTap : nil
            )

            // Metric scroll row
//            HomeReflectionMetricRow(
//                moodValue: moodValue,
//                intensityDetail: intensityDetail,
//                triggerValue: affectedArea?.rawValue ?? dominantTriggerValue,
//                triggerDetail: triggerDetail,
//                windowValue: weeklyInsights?.criticalWindow ?? "Em leitura",
//                windowDetail: actionTimingDetail,
//                actionValue: action?.title ?? "Em preparação",
//                actionDetail: actionDetail
//            )

            // Weekly trend
            HomeReflectionsWeeklyCard(
                title: weeklyTrend?.direction.title ?? "Comparativo semanal",
                detail: weeklyTrend?.summary ?? "Quando houver histórico suficiente, esse bloco mostra se sua semana está melhorando, estável ou pedindo mais cuidado.",
                previousValue: weeklyTrend?.previousWeekScore,
                currentValue: weeklyTrend?.currentWeekScore
            )

            // Priority items as a clean vertical stack
            VStack(alignment: .leading, spacing: 10) {
                Text("O que acompanhar agora")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)

                ForEach(priorityItems) { item in
                    HomeReflectionPriorityRow(item: item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var moodValue: String {
        mood?.rawValue ?? "Sem check-in"
    }

    private var intensityDetail: String {
        guard let intensity else { return "Quando você salvar, a intensidade aparece aqui" }
        return "Intensidade \(intensity)/10"
    }

    private var dominantTriggerValue: String {
        weeklyInsights?.dominantTrigger ?? tags.first ?? "Ainda vamos descobrir"
    }

    private var triggerDetail: String {
        if let patternAlert {
            return patternAlert.detail
        }
        if let focus = weeklyInsights?.behavioralFocus {
            return focus
        }
        return "Os gatilhos e as notas do check-in vão alimentar esse bloco."
    }

    private var controlDetail: String {
        if let worstPattern = weeklyInsights?.worstRecurringPattern {
            return worstPattern
        }
        return "Sono, controle e sinais do corpo entram aqui."
    }

    private var actionTimingDetail: String {
        if let action {
            return "\(action.estimatedMinutes) min para começar com direção."
        }
        return controlDetail
    }

    private var actionDetail: String {
        if let action {
            return action.strategicReason
        }
        if isLoadingInsights {
            return "Estou calculando sua leitura visual do dia."
        }
        return "Vai mostrar a recomendação principal e o motivo."
    }

    private var leadEyebrow: String {
        if isLoadingInsights {
            return "Leitura em andamento"
        }
        if action != nil {
            return "Direção do dia"
        }
        return "Painel executivo"
    }

    private var leadTitle: String {
        if let action {
            return action.title
        }
        if let weeklyInsights {
            return weeklyInsights.behavioralFocus
        }
        return "Complete o check-in para liberar uma direção mais clara para o seu dia."
    }

    private var leadDetail: String {
        if let action {
            return action.strategicReason
        }
        if let alert = patternAlert {
            return alert.detail
        }
        if let weeklyTrend {
            return weeklyTrend.summary
        }
        return "Aqui vamos resumir, em uma única leitura, o que mais importa agora: estado, risco principal, janela de ação e o próximo passo."
    }

    private var leadPills: [String] {
        var pills: [String] = []

        if let mood {
            pills.append(mood.rawValue)
        }
        if let energyLevel {
            pills.append("Energia \(energyLevel.rawValue.lowercased())")
        }
        if let affectedArea {
            pills.append(affectedArea.rawValue)
        } else if let firstTag = tags.first {
            pills.append(firstTag)
        }

        if let window = weeklyInsights?.criticalWindow {
            pills.append(window)
        }

        return Array(pills.prefix(4))
    }

    private var priorityItems: [HomeReflectionPriorityItemData] {
        var items: [HomeReflectionPriorityItemData] = []

        if let patternAlert {
            items.append(
                HomeReflectionPriorityItemData(
                    title: "Observe esse padrão",
                    detail: patternAlert.detail,
                    tint: VenusTheme.primary
                )
            )
        } else {
            items.append(
                HomeReflectionPriorityItemData(
                    title: "O que mais pesa agora",
                    detail: triggerDetail,
                    tint: VenusTheme.accentBlue
                )
            )
        }

        if let window = weeklyInsights?.criticalWindow {
            items.append(
                HomeReflectionPriorityItemData(
                    title: "Proteja essa janela",
                    detail: window,
                    tint: VenusTheme.accentGreen
                )
            )
        }

        if let action {
            items.append(
                HomeReflectionPriorityItemData(
                    title: "Próximo passo",
                    detail: "Reserve \(action.estimatedMinutes) min para \(action.title.lowercased()).",
                    tint: VenusTheme.moodMintStrong
                )
            )
        } else {
            items.append(
                HomeReflectionPriorityItemData(
                    title: "Leitura ainda em preparação",
                    detail: "Assim que você concluir o check-in, esse bloco vira um plano claro do que fazer e do que monitorar.",
                    tint: VenusTheme.textSecondary
                )
            )
        }

        return Array(items.prefix(3))
    }

    private func compactTags(from values: [String], fallback: [String]) -> [String] {
        let normalized = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if normalized.isEmpty {
            return fallback
        }

        return Array(normalized.prefix(3))
    }
}

private struct HomeReflectionLeadCard: View {
    let title: String
    let detail: String
    let eyebrow: String
    let pills: [String]
    var onReasonTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(eyebrow.uppercased())
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(0.6)

                    Text(title)
                        .font(.system(size: 26, weight: .black, design: .serif))
                        .foregroundColor(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(VenusTheme.accentOrange.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(VenusTheme.accentOrange)
                }
            }

            Text(detail)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !pills.isEmpty {
                FlexiblePillRow(items: pills)
            }

            // "Por que isso?" — prominent full-width CTA, only when action exists
            if let onReasonTap {
                Button(action: onReasonTap) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(VenusTheme.accentBlue.opacity(0.14))
                                .frame(width: 34, height: 34)
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(VenusTheme.accentBlue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Entender por que essa ação")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundColor(VenusTheme.text)
                            Text("Abra a leitura estratégica completa")
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .foregroundColor(VenusTheme.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(VenusTheme.accentBlue)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(VenusTheme.accentBlue.opacity(colorScheme == .dark ? 0.12 : 0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(VenusTheme.accentBlue.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.992))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.9) : Color(hex: "C8D8C2").opacity(0.96),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.08), radius: 14, x: 0, y: 10)
    }
}

private struct HomeReflectionsWeeklyCard: View {
    let title: String
    let detail: String
    let previousValue: Double?
    let currentValue: Double?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Comparativo semanal")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
            }

            VStack(spacing: 12) {
                HomeReflectionBarRow(
                    label: "Semana passada",
                    value: normalized(previousValue),
                    tint: VenusTheme.accentBlue
                )
                HomeReflectionBarRow(
                    label: "Esta semana",
                    value: normalized(currentValue),
                    tint: VenusTheme.moodMintStrong
                )
            }

            Text(detail)
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.985))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.92),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.06), radius: 10, x: 0, y: 6)
    }

    private func normalized(_ value: Double?) -> Double {
        guard let value else { return 0.42 }
        return max(0.12, min(value, 1))
    }
}

private struct HomeReflectionBarRow: View {
    let label: String
    let value: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)

                Spacer()

                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(tint)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(VenusTheme.cardBorder.opacity(0.32))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.45), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(24, geometry.size.width * value))
                }
            }
            .frame(height: 8)
        }
    }
}

private struct HomeReflectionPriorityItemData: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let tint: Color
}

private struct HomeReflectionPriorityRow: View {
    let item: HomeReflectionPriorityItemData

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.14))
                    .frame(width: 34, height: 34)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(item.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                Text(item.detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.8) : Color(hex: "CBD9C6").opacity(0.9),
                    lineWidth: 1
                )
        )
    }
}

private struct FlexiblePillRow: View {
    let items: [String]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunkedItems, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Text(item)
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(colorScheme == .dark ? Color(hex: "243828") : Color(hex: "EAF2E7"))
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var chunkedItems: [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []

        for (index, item) in items.enumerated() {
            currentRow.append(item)
            if index.isMultiple(of: 2) == false {
                rows.append(currentRow)
                currentRow = []
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

private struct HomeFeelingChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(isSelected ? VenusTheme.text : VenusTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                            ? (colorScheme == .dark ? Color(hex: "243828") : Color.white.opacity(0.98))
                            : (colorScheme == .dark ? Color(hex: "1A2A1C").opacity(0.9) : Color(hex: "EDF5EA").opacity(0.96))
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                            ? tint.opacity(0.68)
                            : (colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.8) : Color(hex: "BCD2B7").opacity(0.9)),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? tint.opacity(colorScheme == .dark ? 0.28 : 0.2) : Color.black.opacity(colorScheme == .dark ? 0.18 : 0.06),
                    radius: isSelected ? 16 : 8,
                    x: 0,
                    y: isSelected ? 8 : 5
                )
        }
        .buttonStyle(.plain)
    }
}

private struct HomeReflectionCardData: Identifiable {
    let id = UUID()
    let eyebrow: String
    let title: String
    let detail: String
    let tags: [String]
}

private struct HomeReflectionsDeck: View {
    let cards: [HomeReflectionCardData]

    var body: some View {
        ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                HomeReflectionDeckCard(card: card)
                    .rotationEffect(rotation(for: index))
                    .scaleEffect(scale(for: index))
                    .offset(y: yOffset(for: index))
                    .zIndex(Double(cards.count - index))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 312)
        .padding(.vertical, 6)
    }

    private func yOffset(for index: Int) -> CGFloat {
        CGFloat((cards.count - index - 1) * 12)
    }

    private func scale(for index: Int) -> CGFloat {
        1 - CGFloat(cards.count - index - 1) * 0.025
    }

    private func rotation(for index: Int) -> Angle {
        switch index {
        case 0: return .degrees(-2.5)
        case 1: return .degrees(2)
        default: return .degrees(-1)
        }
    }
}

private struct HomeReflectionDeckCard: View {
    let card: HomeReflectionCardData

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(card.eyebrow.uppercased())
                .font(.system(.caption2, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.textSecondary)

            Text(card.title)
                .font(.system(size: 24, weight: .black, design: .serif))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.detail)
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                ForEach(card.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(colorScheme == .dark ? Color(hex: "243828") : Color(hex: "E6F1E2"))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 228)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.995))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C5D8BF").opacity(0.95),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.09), radius: 14, x: 0, y: 10)
        .padding(.horizontal, 10)
    }
}

// Fixed-height metric cards with distinct icon colors per semantic meaning
private struct HomeReflectionMetricRow: View {
    let moodValue: String
    let intensityDetail: String
    let triggerValue: String
    let triggerDetail: String
    let windowValue: String
    let windowDetail: String
    let actionValue: String
    let actionDetail: String

    private let cardHeight: CGFloat = 148

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ReflectionMetricCard(
                    eyebrow: "Estado",
                    value: moodValue,
                    detail: intensityDetail,
                    icon: "face.smiling.inverse",
                    iconColor: VenusTheme.accentBlue,
                    height: cardHeight
                )
                ReflectionMetricCard(
                    eyebrow: "Gatilho",
                    value: triggerValue,
                    detail: triggerDetail,
                    icon: "exclamationmark.triangle.fill",
                    iconColor: VenusTheme.accentPink,
                    height: cardHeight
                )
                ReflectionMetricCard(
                    eyebrow: "Janela",
                    value: windowValue,
                    detail: windowDetail,
                    icon: "clock.badge.checkmark.fill",
                    iconColor: VenusTheme.accentOrange,
                    height: cardHeight
                )
                ReflectionMetricCard(
                    eyebrow: "Próximo passo",
                    value: actionValue,
                    detail: actionDetail,
                    icon: "arrow.right.circle.fill",
                    iconColor: VenusTheme.accentGreen,
                    height: cardHeight
                )
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }
}

private struct ReflectionMetricCard: View {
    let eyebrow: String
    let value: String
    let detail: String
    let icon: String
    let iconColor: Color
    let height: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
            }
            .padding(.bottom, 10)

            Text(eyebrow)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
                .padding(.bottom, 4)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 6)

            Text(detail)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 158, height: height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1E2E20") : Color.white.opacity(0.985))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.92),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 8, x: 0, y: 4)
    }
}

