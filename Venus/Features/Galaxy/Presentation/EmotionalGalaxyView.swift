//
//  EmotionalGalaxyView.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//
//  F15 — constelação com atmosfera suave, vidro real e haptics na seleção.
//  F36 — cabeçalho de jornada com arco e pontos, menos texto e transições spring.
//

import SwiftUI
import UIKit

struct EmotionalGalaxyView: View {
    let userName: String
    let weekMoods: [Mood]
    let weeklyTrend: WeeklyEmotionalTrend?
    let readinessAssessment: ReadinessEnergyAssessment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTimeRange: GalaxyTimeRange = .week
    @State private var selectedStar: GalaxyStar? = nil
    @State private var allHistoricalMoods: [Mood] = []
    @State private var isLoadingMoods: Bool = false
    @State private var didAppear: Bool = false

    private let moodRepository = DependencyContainer.shared.makeMoodRepository()

    enum GalaxyTimeRange: String, CaseIterable, Identifiable {
        case week = "7 Dias"
        case fortnight = "14 Dias"
        case month = "30 Dias"

        var id: String { rawValue }
        var index: Int {
            GalaxyTimeRange.allCases.firstIndex(of: self) ?? 0
        }
        var dayCount: Int {
            switch self {
            case .week: return 7
            case .fortnight: return 14
            case .month: return 30
            }
        }
    }

    private var displayedMoods: [Mood] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.dayCount, to: Date()) ?? Date()
        let source = allHistoricalMoods.isEmpty ? weekMoods : allHistoricalMoods
        return source.filter { $0.timestamp >= cutoff }.sorted(by: { $0.timestamp < $1.timestamp })
    }

    private var stars: [GalaxyStar] {
        let list = displayedMoods
        return list.enumerated().map { GalaxyStar(mood: $0.element, index: $0.offset, total: list.count) }
    }

    private var toolbarColor: Color {
        colorScheme == .dark ? Color(hex: "2B2340") : Color(hex: "EDE2F7")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VenusSoftGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        journeyHeader

                        timeRangeSelector

                        constellationPanel

                        summaryCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 14)
                    .animation(.spring(response: 0.55, dampingFraction: 0.85), value: didAppear)
                }
            }
            .navigationTitle("Galáxia de Memórias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(toolbarColor, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(VenusTheme.text)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular, in: Circle())
                    .accessibilityLabel("Fechar galáxia")
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    didAppear = true
                }
            }
            .task {
                await loadAllMoods()
            }
        }
    }

    // MARK: - Cabeçalho da jornada

    private var journeyHeader: some View {
        VenusF36JourneyHeader(
            eyebrow: "Sua jornada emocional",
            title: "Galáxia",
            subtitle: "Cada estrela é um momento que você registrou.",
            dotCount: GalaxyTimeRange.allCases.count,
            currentDot: selectedTimeRange.index + 1,
            dotCaption: selectedTimeRange.rawValue,
            tint: VenusF36Palette.rose
        )
    }

    // MARK: - Seletor de período

    private var timeRangeSelector: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(GalaxyTimeRange.allCases) { range in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            selectedTimeRange = range
                            selectedStar = nil
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 13, design: .rounded).weight(selectedTimeRange == range ? .semibold : .regular))
                            .foregroundStyle(VenusTheme.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        selectedTimeRange == range
                            ? .regular.tint(VenusF36Palette.lilac.opacity(0.22))
                            : .regular,
                        in: Capsule(style: .continuous)
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Constelação

    private var constellationPanel: some View {
        ConstellationCanvas(
            stars: stars,
            selectedStar: $selectedStar,
            isAnimated: true,
            showDetailsSheet: true
        )
        .frame(height: 440)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selectedStar?.id)
    }

    // MARK: - Resumo

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUA CONSTELAÇÃO")
                .font(.system(size: 10, design: .rounded).weight(.semibold))
                .kerning(1.6)
                .foregroundStyle(VenusTheme.textSecondary)

            HStack(alignment: .firstTextBaseline) {
                Text("Constelação de \(userName)")
                    .font(.system(size: 23, design: .rounded).weight(.light))
                    .foregroundStyle(VenusTheme.text)

                Spacer(minLength: 8)

                Text("\(stars.count) estrelas")
                    .font(.system(size: 12, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusF36Palette.rose)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .glassEffect(
                        .regular.tint(VenusF36Palette.rose.opacity(0.16)),
                        in: Capsule(style: .continuous)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func loadAllMoods() async {
        isLoadingMoods = true
        let start = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
        if let moods = try? await moodRepository.getMoods(from: start, to: Date()) {
            self.allHistoricalMoods = moods
        }
        isLoadingMoods = false
    }
}
