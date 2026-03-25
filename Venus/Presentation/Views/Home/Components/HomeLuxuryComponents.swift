//
//  HomeLuxuryComponents.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI
import Charts

private enum HomeLuxuryDeckLayout {
    static let cardAspectRatio: CGFloat = 0.8
    static let maxCardWidth: CGFloat = 540
    static let minCardHeight: CGFloat = 450
    static let maxCardHeight: CGFloat = 520

    static func height(for width: CGFloat) -> CGFloat {
        let referenceWidth = min(max(width, 320), 410)
        return min(max(referenceWidth / cardAspectRatio, minCardHeight), maxCardHeight)
    }
}

private struct HomeLuxuryWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct HomeLuxuryWidthReader: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: HomeLuxuryWidthPreferenceKey.self, value: proxy.size.width)
        }
    }
}

struct HomeLuxuryHeroSection: View {
    let title: String
    let subtitle: String
    let highlights: [HomeHeaderHighlight]
    let streakDays: Int
    let mood: MoodType?
    let intensity: Int?
    let hasCheckedInToday: Bool
    let hasStartedPracticeToday: Bool

    @State private var availableWidth: CGFloat = 0

    private var primaryTint: Color {
        guard let mood else { return VenusTheme.accentOrange }
        return Color(hex: mood.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    private var symbolName: String {
        switch mood {
        case .calm: return "leaf.fill"
        case .happy: return "sun.max.fill"
        case .energetic: return "bolt.fill"
        case .stressed: return "waveform.path.ecg"
        case .sad: return "cloud.drizzle.fill"
        case .tired: return "moon.zzz.fill"
        case nil: return "sparkles"
        }
    }

    private var usesStackedLayout: Bool {
        if availableWidth == 0 {
            return true
        }
        return availableWidth < 430
    }

    var body: some View {
        HomeLuxuryGlassPanel(tint: primaryTint, cornerRadius: 34, padding: 22) {
            VStack(alignment: .leading, spacing: usesStackedLayout ? 18 : 20) {
                if usesStackedLayout {
                    VStack(alignment: .leading, spacing: 16) {
                        heroTextBlock(titleSize: 32)

                        HStack {
                            Spacer(minLength: 0)

                            HomeLuxuryHalo(
                                symbolName: symbolName,
                                tint: primaryTint,
                                badgeText: intensity.map { "\($0)/10" } ?? "\(streakDays)d",
                                satelliteSymbols: hasStartedPracticeToday
                                    ? ["play.fill", "sparkles"]
                                    : ["heart.fill", "sparkles"]
                            )
                        }
                    }
                } else {
                    HStack(alignment: .top, spacing: 18) {
                        heroTextBlock(titleSize: 38)

                        Spacer(minLength: 8)

                        HomeLuxuryHalo(
                            symbolName: symbolName,
                            tint: primaryTint,
                            badgeText: intensity.map { "\($0)/10" } ?? "\(streakDays)d",
                            satelliteSymbols: hasStartedPracticeToday
                                ? ["play.fill", "sparkles"]
                                : ["heart.fill", "sparkles"]
                        )
                    }
                }

                if usesStackedLayout {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(highlights.prefix(4))) { highlight in
                                HomeLuxuryStatusTile(highlight: highlight)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .scrollClipDisabled()
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(Array(highlights.prefix(4))) { highlight in
                            HomeLuxuryStatusTile(highlight: highlight)
                        }
                    }
                }
            }
        }
        .background(HomeLuxuryWidthReader())
        .onPreferenceChange(HomeLuxuryWidthPreferenceKey.self) { width in
            availableWidth = width
        }
    }

    @ViewBuilder
    private func heroTextBlock(titleSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(hasCheckedInToday ? "VENUS DAILY" : "COMECE AQUI")
                .font(.system(.caption, design: .rounded).weight(.black))
                .foregroundColor(primaryTint)
                .tracking(1.4)

            Text(title)
                .font(.system(size: titleSize, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeLuxurySpotlightDeckSection: View {
    let hasCheckedInToday: Bool
    let statusText: String
    let statusHighlight: HomeHeaderHighlight
    let availabilityHighlight: HomeHeaderHighlight
    let trendHighlight: HomeHeaderHighlight?
    let mood: MoodType?
    let intensity: Int?
    let supportsActionModeSwitch: Bool
    let preferHighImpactAction: Bool
    let isLoadingInsights: Bool
    let action: NextBestAction?
    let badges: [HomeActionBadge]
    let insights: [HomeVisualInsight]
    let actionWhySummary: String?
    let errorMessage: String?
    let primaryActionTitle: String
    let showsReasonCTA: Bool
    let onSelectHighImpact: (Bool) -> Void
    let onPrimaryAction: () -> Void
    let onReasonTap: () -> Void
    let onTapInsight: (HomeVisualInsight) -> Void

    @State private var selection: String = "vibe"
    @State private var availableWidth: CGFloat = 0

    private var featuredInsights: [HomeVisualInsight] {
        Array(insights.prefix(2))
    }

    private var slideIDs: [String] {
        var ids = ["vibe", "action"]
        if actionWhySummary != nil {
            ids.append("why")
        }
        ids.append(contentsOf: featuredInsights.map { "insight-\($0.id)" })
        return ids
    }

    private var deckWidth: CGFloat {
        let width = availableWidth == 0 ? HomeLuxuryDeckLayout.maxCardWidth : availableWidth
        return min(max(width, 320), HomeLuxuryDeckLayout.maxCardWidth)
    }

    private var deckHeight: CGFloat {
        HomeLuxuryDeckLayout.height(for: deckWidth)
    }

    private var sectionTitle: String {
        hasCheckedInToday ? "Seu foco agora" : "Comece por aqui"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(sectionTitle)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Spacer()

                HStack(spacing: 10) {
                    pagerButton(systemImage: "chevron.left", disabled: currentIndex == 0) {
                        guard currentIndex > 0 else { return }
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            selection = slideIDs[currentIndex - 1]
                        }
                    }

                    Text(pageLabel)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.textSecondary)

                    pagerButton(systemImage: "chevron.right", disabled: currentIndex >= slideIDs.count - 1) {
                        guard currentIndex < slideIDs.count - 1 else { return }
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            selection = slideIDs[currentIndex + 1]
                        }
                    }
                }
            }

            TabView(selection: $selection) {
                HomeLuxuryVibeCard(
                    hasCheckedInToday: hasCheckedInToday,
                    statusText: statusText,
                    statusHighlight: statusHighlight,
                    availabilityHighlight: availabilityHighlight,
                    trendHighlight: trendHighlight,
                    mood: mood,
                    intensity: intensity
                )
                .tag("vibe")

                HomeLuxuryActionCard(
                    supportsActionModeSwitch: supportsActionModeSwitch,
                    preferHighImpactAction: preferHighImpactAction,
                    isLoadingInsights: isLoadingInsights,
                    action: action,
                    badges: badges,
                    errorMessage: errorMessage,
                    primaryActionTitle: primaryActionTitle,
                    showsReasonCTA: showsReasonCTA,
                    onSelectHighImpact: onSelectHighImpact,
                    onPrimaryAction: onPrimaryAction,
                    onReasonTap: onReasonTap
                )
                .tag("action")

                if let actionWhySummary {
                    HomeLuxuryWhyCard(
                        summary: actionWhySummary,
                        actionTitle: action?.title,
                        onTap: onReasonTap
                    )
                    .tag("why")
                }

                ForEach(featuredInsights) { insight in
                    HomeLuxuryInsightCard(
                        insight: insight,
                        onTap: { onTapInsight(insight) }
                    )
                    .tag("insight-\(insight.id)")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: deckWidth)
            .frame(height: deckHeight)
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach(slideIDs, id: \.self) { id in
                    Capsule()
                        .fill(id == selection ? AnyShapeStyle(VenusTheme.primaryGradient) : AnyShapeStyle(VenusTheme.cardBorder.opacity(0.72)))
                        .frame(width: id == selection ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: selection)
                }
            }
        }
        .onAppear {
            if !slideIDs.contains(selection) {
                selection = slideIDs.first ?? "vibe"
            }
        }
        .background(HomeLuxuryWidthReader())
        .onPreferenceChange(HomeLuxuryWidthPreferenceKey.self) { width in
            availableWidth = width
        }
    }

    private var currentIndex: Int {
        slideIDs.firstIndex(of: selection) ?? 0
    }

    private func pagerButton(systemImage: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(disabled ? VenusTheme.textSecondary.opacity(0.4) : VenusTheme.text)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(disabled ? 0.06 : 0.12))
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var pageLabel: String {
        let current = max((slideIDs.firstIndex(of: selection) ?? 0) + 1, 1)
        return "\(current)/\(max(slideIDs.count, 1))"
    }
}

struct HomeLuxuryVariationShelfSection: View {
    let alternativeActions: [NextBestAction]
    let suggestions: [ExploreActionSuggestion]
    let onSelectAlternative: (NextBestAction) -> Void

    private var hasContent: Bool {
        !alternativeActions.isEmpty || !suggestions.isEmpty
    }

    private var featuredAlternatives: [NextBestAction] {
        Array(alternativeActions.prefix(3))
    }

    private var featuredSuggestions: [ExploreActionSuggestion] {
        Array(suggestions.prefix(featuredAlternatives.isEmpty ? 4 : 2))
    }

    private var suggestionColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trocar a vibe")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)

                    Text("Escolha outra rota sem perder a energia que faz sentido para hoje.")
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                }

                if !featuredAlternatives.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(featuredAlternatives) { action in
                            Button {
                                onSelectAlternative(action)
                            } label: {
                                HomeLuxuryAlternativeActionCard(action: action)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !featuredSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(featuredAlternatives.isEmpty ? "Inspirações rápidas" : "Ou misture com isso")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.textSecondary)

                        LazyVGrid(columns: suggestionColumns, spacing: 12) {
                            ForEach(featuredSuggestions) { suggestion in
                                HomeLuxurySuggestionCard(suggestion: suggestion)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct HomeLuxuryGlassPanel<Content: View>: View {
    let tint: Color
    let cornerRadius: CGFloat
    let padding: CGFloat
    let fillsAvailableSpace: Bool
    let content: Content

    init(
        tint: Color,
        cornerRadius: CGFloat = 30,
        padding: CGFloat = 20,
        fillsAvailableSpace: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.fillsAvailableSpace = fillsAvailableSpace
        self.content = content()
    }

    var body: some View {
        content
            .frame(
                maxWidth: fillsAvailableSpace ? .infinity : nil,
                maxHeight: fillsAvailableSpace ? .infinity : nil,
                alignment: .topLeading
            )
            .padding(padding)
            .frame(
                maxWidth: fillsAvailableSpace ? .infinity : nil,
                maxHeight: fillsAvailableSpace ? .infinity : nil,
                alignment: .topLeading
            )
//            .background(
//                ZStack {
//                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                        .fill(Color.white.opacity(0.1))
//
//                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                        .fill(
//                            LinearGradient(
//                                colors: [
//                                    tint.opacity(0.12),
//                                    Color.white.opacity(0.02),
//                                    Color.clear
//                                ],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//
//                    Circle()
//                        .fill(tint.opacity(0.14))
//                        .blur(radius: 56)
//                        .frame(width: 180, height: 180)
//                        .offset(x: 74, y: -76)
//                }
//            )
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct HomeLuxuryHalo: View {
    let symbolName: String
    let tint: Color
    let badgeText: String
    let satelliteSymbols: [String]
    var isAnimated: Bool = true

    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.94),
                            tint.opacity(0.72),
                            Color.white.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .frame(width: 104, height: 104)
                .scaleEffect(isAnimated ? (animate ? 1.04 : 0.97) : 1)

            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: 126, height: 126)
                .scaleEffect(isAnimated ? (animate ? 1.04 : 0.96) : 1)
                .opacity(isAnimated ? (animate ? 0.7 : 0.38) : 0.46)

            Image(systemName: symbolName)
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.white)
                .scaleEffect(isAnimated ? (animate ? 1.03 : 0.96) : 1)

            ForEach(Array(satelliteSymbols.prefix(2).enumerated()), id: \.offset) { index, symbol in
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: index == 0 ? 30 : 24, height: index == 0 ? 30 : 24)
                    .overlay(
                        Image(systemName: symbol)
                            .font(.system(size: index == 0 ? 12 : 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(
                        x: index == 0 ? (isAnimated ? (animate ? -48 : -38) : -42) : (isAnimated ? (animate ? 46 : 34) : 38),
                        y: index == 0 ? (isAnimated ? (animate ? -38 : -28) : -32) : (isAnimated ? (animate ? 26 : 18) : 22)
                    )
            }

            Text(badgeText)
                .font(.system(.caption2, design: .rounded).weight(.black))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.18)))
                .offset(y: 70)
        }
        .frame(width: 132, height: 142)
        .onAppear {
            guard isAnimated, !animate else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
        .onChange(of: isAnimated) { _, newValue in
            if !newValue {
                animate = false
            } else if !animate {
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
        }
    }
}

private struct HomeLuxuryStatusTile: View {
    let highlight: HomeHeaderHighlight

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(highlight.tint.opacity(0.14))
                    .frame(width: 30, height: 30)

                Image(systemName: highlight.systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(highlight.tint)
            }

            Text(highlight.title)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct HomeLuxuryInfoTile: View {
    let label: String
    let highlight: HomeHeaderHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: highlight.systemImage)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(highlight.tint)

                Text(label)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            Text(highlight.title)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct HomeLuxuryStatusBadge: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .bold))

            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.black))
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct HomeLuxuryInfoCallout: View {
    let title: String
    let text: String
    let systemImage: String
    let tint: Color
    var lineLimit: Int? = 2

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.14))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(tint)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(.caption2, design: .rounded).weight(.black))
                    .foregroundColor(tint)
                    .tracking(0.4)

                Text(text)
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.text)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct HomeLuxurySignalPanel<Content: View>: View {
    let tint: Color
    let content: Content

    init(
        tint: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(tint.opacity(0.14), lineWidth: 1)
            )
    }
}

private struct HomeLuxuryVibeCard: View {
    let hasCheckedInToday: Bool
    let statusText: String
    let statusHighlight: HomeHeaderHighlight
    let availabilityHighlight: HomeHeaderHighlight
    let trendHighlight: HomeHeaderHighlight?
    let mood: MoodType?
    let intensity: Int?

    private var primaryTint: Color {
        guard let mood else { return VenusTheme.accentBlue }
        return Color(hex: mood.colorHex.replacingOccurrences(of: "#", with: ""))
    }

    private var moodTitle: String {
        guard let mood else { return "Sua leitura entra aqui" }
        return mood.rawValue
    }

    private var moodSubtitle: String {
        if hasCheckedInToday {
            return statusText
        }
        return "Abra seu check-in no botão flutuante e desbloqueie esse painel."
    }

    var body: some View {
        HomeLuxuryGlassPanel(
            tint: primaryTint,
            cornerRadius: 32,
            padding: 22,
            fillsAvailableSpace: true
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seu clima")
                            .font(.system(.caption, design: .rounded).weight(.black))
                            .foregroundColor(primaryTint)
                            .tracking(1.3)

                        Text(hasCheckedInToday ? "Leitura atualizada com o seu check-in." : "Esse painel ganha vida assim que você registra como está.")
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    HomeLuxuryStatusBadge(
                        title: hasCheckedInToday ? "Atualizado" : "Pendente",
                        systemImage: hasCheckedInToday ? "checkmark.circle.fill" : "circle.dashed",
                        tint: hasCheckedInToday ? VenusTheme.accentGreen : primaryTint
                    )
                }

                HStack(alignment: .center, spacing: 18) {
                    HomeLuxuryMoodRing(
                        mood: mood,
                        intensity: intensity,
                        tint: primaryTint
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(moodTitle)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(moodSubtitle)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    HomeLuxuryInfoTile(label: "Status", highlight: statusHighlight)
                    HomeLuxuryInfoTile(label: "Acesso", highlight: availabilityHighlight)
                }

                HomeLuxuryInfoCallout(
                    title: trendHighlight == nil ? "Leitura em construção" : "Tendência",
                    text: trendHighlight?.title ?? "Com mais check-ins ao longo da semana, esse painel começa a mostrar a direção do seu ritmo.",
                    systemImage: trendHighlight?.systemImage ?? "chart.line.uptrend.xyaxis",
                    tint: trendHighlight?.tint ?? primaryTint,
                    lineLimit: 3
                )

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct HomeLuxuryMoodRing: View {
    let mood: MoodType?
    let intensity: Int?
    let tint: Color

    private var progress: Double {
        guard let intensity else { return 0.18 }
        return max(0.08, min(Double(intensity) / 10.0, 1))
    }

    private var iconName: String {
        switch mood {
        case .calm: return "leaf.fill"
        case .happy: return "sun.max.fill"
        case .energetic: return "bolt.fill"
        case .stressed: return "waveform.path.ecg"
        case .sad: return "cloud.drizzle.fill"
        case .tired: return "moon.zzz.fill"
        case nil: return "heart.text.square.fill"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.12), lineWidth: 10)
                .frame(width: 104, height: 104)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [tint.opacity(0.5), tint], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 104, height: 104)

            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(tint)

                Text(intensity.map { "\($0)/10" } ?? "sem")
                    .font(.system(.caption, design: .rounded).weight(.black))
                    .foregroundColor(VenusTheme.textSecondary)
            }
        }
    }
}

private struct HomeLuxuryMiniPill: View {
    let highlight: HomeHeaderHighlight
    var fullWidth: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: highlight.systemImage)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(highlight.tint)

            Text(highlight.title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct HomeLuxuryActionCard: View {
    let supportsActionModeSwitch: Bool
    let preferHighImpactAction: Bool
    let isLoadingInsights: Bool
    let action: NextBestAction?
    let badges: [HomeActionBadge]
    let errorMessage: String?
    let primaryActionTitle: String
    let showsReasonCTA: Bool
    let onSelectHighImpact: (Bool) -> Void
    let onPrimaryAction: () -> Void
    let onReasonTap: () -> Void

    private var actionTint: Color {
        guard let action else { return VenusTheme.accentOrange }
        switch action.kind.category {
        case .execution: return VenusTheme.accentOrange
        case .planning: return VenusTheme.accentBlue
        case .communication: return VenusTheme.accentPink
        case .movement: return VenusTheme.accentGreen
        case .recovery: return VenusTheme.accentPurple
        }
    }

    var body: some View {
        HomeLuxuryGlassPanel(
            tint: actionTint,
            cornerRadius: 32,
            padding: 22,
            fillsAvailableSpace: true
        ) {
            if isLoadingInsights {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Próximo passo")
                        .font(.system(.caption, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.accentBlue)
                        .tracking(1.3)

                    Spacer()

                    HStack(spacing: 14) {
                        ProgressView()
                            .tint(VenusTheme.accentBlue)
                            .scaleEffect(1.3)
                        Text("Estou lapidando a melhor rota para agora.")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if let action {
                VStack(alignment: .leading, spacing: 18) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 12) {
                            actionHeader(for: action)

                            Spacer(minLength: 0)

                            if supportsActionModeSwitch {
                                HomeLuxuryModeSwitch(
                                    preferHighImpact: preferHighImpactAction,
                                    onSelect: onSelectHighImpact
                                )
                                .frame(maxWidth: 178)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            actionHeader(for: action)

                            if supportsActionModeSwitch {
                                HomeLuxuryModeSwitch(
                                    preferHighImpact: preferHighImpactAction,
                                    onSelect: onSelectHighImpact
                                )
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(action.title)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(action.detail)
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HomeLuxuryInfoCallout(
                        title: "Por que agora",
                        text: action.strategicReason,
                        systemImage: "sparkles.rectangle.stack.fill",
                        tint: actionTint,
                        lineLimit: 2
                    )

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            HomeLuxuryActionFact(
                                title: "Duração",
                                value: "\(action.estimatedMinutes) min",
                                systemImage: "timer",
                                tint: actionTint
                            )

                            ForEach(Array(badges.prefix(2))) { badge in
                                HomeLuxuryActionFact(
                                    title: "",
                                    value: badge.title,
                                    systemImage: badge.systemImage,
                                    tint: badge.tint
                                )
                            }
                        }

                        VStack(spacing: 10) {
                            HomeLuxuryActionFact(
                                title: "Duração",
                                value: "\(action.estimatedMinutes) min",
                                systemImage: "timer",
                                tint: actionTint
                            )

                            ForEach(Array(badges.prefix(2))) { badge in
                                HomeLuxuryActionFact(
                                    title: "",
                                    value: badge.title,
                                    systemImage: badge.systemImage,
                                    tint: badge.tint
                                )
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 10) {
                        Button(action: onPrimaryAction) {
                            HStack(spacing: 8) {
                                Text(primaryActionTitle)
                                    .font(.system(.subheadline, design: .rounded).weight(.black))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .black))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(VenusTheme.primaryGradient)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        if showsReasonCTA {
                            Button(action: onReasonTap) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles.rectangle.stack.fill")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Entender o porquê")
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                }
                                .foregroundColor(VenusTheme.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if let errorMessage {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Próximo passo")
                        .font(.system(.caption, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.accentPink)
                        .tracking(1.3)

                    Text("A leitura falhou agora")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .lineLimit(2)

                    Text(errorMessage)
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Button(action: onPrimaryAction) {
                        Text("Tentar novamente")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(VenusTheme.primaryGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Próximo passo")
                        .font(.system(.caption, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.accentBlue)
                        .tracking(1.3)

                    Text("Seu próximo passo nasce do check-in")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .lineLimit(2)

                    Text("Quando você registrar como está, eu transformo isso em uma ação direta.")
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    HomeLuxuryDeckBadge(
                        title: "check-in",
                        systemImage: "heart.text.square.fill",
                        tint: VenusTheme.accentBlue,
                        large: true
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    @ViewBuilder
    private func actionHeader(for action: NextBestAction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Próximo passo")
                .font(.system(.caption, design: .rounded).weight(.black))
                .foregroundColor(actionTint)
                .tracking(1.3)

            HomeLuxuryDeckBadge(
                title: "\(action.estimatedMinutes) min",
                systemImage: action.kind.iconName,
                tint: actionTint
            )
        }
    }
}

private struct HomeLuxuryDeckBadge: View {
    let title: String
    let systemImage: String
    let tint: Color
    var large: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.96), tint.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: large ? 52 : 42, height: large ? 52 : 42)

                Image(systemName: systemImage)
                    .font(.system(size: large ? 18 : 14, weight: .black))
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.system(large ? .subheadline : .caption, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.text)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}

private struct HomeLuxuryModeSwitch: View {
    let preferHighImpact: Bool
    let onSelect: (Bool) -> Void

    var body: some View {
        HStack(spacing: 0) {
            option(
                title: "Rápido",
                systemImage: "hare.fill",
                isSelected: !preferHighImpact
            ) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    onSelect(false)
                }
            }

            option(
                title: "Completo",
                systemImage: "sparkles",
                isSelected: preferHighImpact
            ) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    onSelect(true)
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func option(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
            }
            .foregroundColor(isSelected ? VenusTheme.text : VenusTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.14) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HomeLuxuryActionFact: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tint)

                if !title.isEmpty {
                    Text(title)
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }

            Text(value)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct HomeLuxuryWhyCard: View {
    let summary: String
    let actionTitle: String?
    let onTap: () -> Void

    var body: some View {
        HomeLuxuryGlassPanel(
            tint: VenusTheme.accentBlue,
            cornerRadius: 32,
            padding: 22,
            fillsAvailableSpace: true
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entender o porquê")
                            .font(.system(.caption, design: .rounded).weight(.black))
                            .foregroundColor(VenusTheme.accentBlue)
                            .tracking(1.3)

                        Text("A leitura estratégica por trás da recomendação de agora.")
                            .font(.system(.footnote, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    HomeLuxuryStatusBadge(
                        title: "Leitura",
                        systemImage: "sparkles.rectangle.stack.fill",
                        tint: VenusTheme.accentBlue
                    )
                }

                Text(actionTitle ?? "Essa recomendação")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                Text(summary)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                HomeLuxuryInfoCallout(
                    title: "O que entrou na análise",
                    text: "Sinais do check-in, contexto do seu momento e chance real de isso te ajudar hoje.",
                    systemImage: "scope",
                    tint: VenusTheme.accentBlue,
                    lineLimit: 2
                )

                Spacer()

                Button(action: onTap) {
                    HStack(spacing: 8) {
                        Text("Abrir leitura completa")
                            .font(.system(.subheadline, design: .rounded).weight(.black))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(VenusTheme.primaryGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct HomeLuxuryTinyReasonPill: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(VenusTheme.accentBlue)

            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.black))
                .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct HomeLuxuryInsightCard: View {
    let insight: HomeVisualInsight
    let onTap: () -> Void

    private var tint: Color {
        insight.kind == .forecastLocked ? VenusTheme.accentPurple : insight.tint
    }

    var body: some View {
        HomeLuxuryGlassPanel(
            tint: tint,
            cornerRadius: 32,
            padding: 22,
            fillsAvailableSpace: true
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(0.14))
                            .frame(width: 42, height: 42)

                        Image(systemName: insight.systemImage)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(tint)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(insight.label)
                            .font(.system(.caption, design: .rounded).weight(.black))
                            .foregroundColor(tint)
                            .tracking(1.3)

                        Text(insight.title)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if insight.kind == .forecastLocked {
                        VenusProBadge(compact: true)
                    } else if let badge = insight.badgeText {
                        Text(badge)
                            .font(.system(.caption2, design: .rounded).weight(.black))
                            .foregroundColor(tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(tint.opacity(0.1)))
                    }
                }
                Text(insight.detail)
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let progress = insight.progress {
                    HomeLuxurySignalPanel(tint: tint) {
                        HomeLuxuryProgressTrack(value: progress, tint: tint)
                    }
                } else if let values = insight.sparklineValues {
                    HomeLuxurySignalPanel(tint: tint) {
                        HomeLuxurySparkline(values: values, tint: tint)
                    }
                }

                Spacer(minLength: 0)

                HStack {
                    Spacer()

                    Button(action: onTap) {
                        HStack(spacing: 8) {
                            Text("Abrir insight")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .black))
                        }
                        .foregroundColor(VenusTheme.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct HomeLuxuryProgressTrack: View {
    let value: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Força atual")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
                Spacer()
                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(.caption2, design: .rounded).weight(.black))
                    .foregroundColor(tint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.5), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(18, geo.size.width * max(0.04, min(value, 1))))
                }
            }
            .frame(height: 8)
        }
    }
}

private struct HomeLuxurySparkline: View {
    let values: [Double]
    let tint: Color

    private struct Point: Identifiable {
        let id: Int
        let value: Double
    }

    private var points: [Point] {
        values.enumerated().map { Point(id: $0.offset, value: $0.element) }
    }

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Index", point.id),
                y: .value("Value", point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(tint.opacity(0.14))

            LineMark(
                x: .value("Index", point.id),
                y: .value("Value", point.value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .foregroundStyle(tint)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 44)
    }
}

private struct HomeLuxuryAlternativeActionCard: View {
    let action: NextBestAction

    private var tint: Color {
        switch action.kind.category {
        case .execution: return VenusTheme.accentOrange
        case .planning: return VenusTheme.accentBlue
        case .communication: return VenusTheme.accentPink
        case .movement: return VenusTheme.accentGreen
        case .recovery: return VenusTheme.accentPurple
        }
    }

    var body: some View {
        HomeLuxuryGlassPanel(tint: tint, cornerRadius: 28, padding: 18) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 46, height: 46)

                    Image(systemName: action.kind.iconName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(action.title)
                        .font(.system(.headline, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        HomeLuxuryCompactTag(
                            title: "\(action.estimatedMinutes) min",
                            systemImage: "timer",
                            tint: tint
                        )
                        HomeLuxuryCompactTag(
                            title: "Troca pronta",
                            systemImage: "arrow.triangle.2.circlepath",
                            tint: VenusTheme.accentBlue
                        )
                    }
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 8) {
                    Text("mudar")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(tint.opacity(0.1)))

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(tint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct HomeLuxuryCompactTag: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(tint.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct HomeLuxurySuggestionCard: View {
    let suggestion: ExploreActionSuggestion

    private var tint: Color {
        switch suggestion.iconName {
        case let value where value.contains("heart"):
            return VenusTheme.accentPink
        case let value where value.contains("leaf") || value.contains("figure") || value.contains("wind"):
            return VenusTheme.accentGreen
        case let value where value.contains("timer") || value.contains("clock") || value.contains("calendar"):
            return VenusTheme.accentBlue
        case let value where value.contains("moon") || value.contains("sparkles") || value.contains("star"):
            return VenusTheme.accentPurple
        default:
            return VenusTheme.accentOrange
        }
    }

    var body: some View {
        HomeLuxuryGlassPanel(tint: tint, cornerRadius: 26, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(tint.opacity(0.14))
                            .frame(width: 42, height: 42)

                        Image(systemName: suggestion.iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(tint)
                    }

                    Spacer()

                    Text("\(suggestion.durationMinutes) min")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(tint)
                }

                Text(suggestion.activityTitle)
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(suggestion.activityCategory)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 154, alignment: .leading)
        }
    }
}
