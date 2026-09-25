//
//  EmotionalGalaxyView.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import SwiftUI
import UIKit

struct EmotionalGalaxyView: View {
    let userName: String
    let weekMoods: [Mood]
    let weeklyTrend: WeeklyEmotionalTrend?
    let readinessAssessment: ReadinessEnergyAssessment
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: GalaxyTimeRange = .week
    @State private var selectedStar: GalaxyStar? = nil
    @State private var showVenusWrap: Bool = false
    @State private var allHistoricalMoods: [Mood] = []
    @State private var isLoadingMoods: Bool = false
    
    private let moodRepository = DependencyContainer.shared.makeMoodRepository()
    
    enum GalaxyTimeRange: String, CaseIterable, Identifiable {
        case week = "7 Dias"
        case fortnight = "14 Dias"
        case month = "30 Dias"
        
        var id: String { rawValue }
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "07060D").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Time Range Selector
                    HStack(spacing: 8) {
                        ForEach(GalaxyTimeRange.allCases) { range in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedTimeRange = range
                                    selectedStar = nil
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text(range.rawValue)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTimeRange == range ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Group {
                                            if selectedTimeRange == range {
                                                Capsule().fill(VenusTheme.primary)
                                            } else {
                                                Capsule().fill(Color.white.opacity(0.08))
                                            }
                                        }
                                    )
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    
                    // Main Constellation Sky Canvas
                    ZStack {
                        ConstellationCanvas(
                            stars: stars,
                            selectedStar: $selectedStar,
                            isAnimated: true,
                            showDetailsSheet: true
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(VenusTheme.primary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    // Bottom Controls & Story Launch Button
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Constelação de \(userName)")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(.white)
                                
                                Text("\(stars.count) estrelas mapeadas no período")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            // Launch Story Wrapped Button
                            Button {
                                showVenusWrap = true
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Venus Wrap ✨")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [VenusTheme.primary, VenusTheme.accentPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                                .shadow(color: VenusTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Galáxia de Memórias")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(hex: "07060D"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .fullScreenCover(isPresented: $showVenusWrap) {
                VenusWrapStoryView(
                    userName: userName,
                    weekMoods: displayedMoods,
                    weeklyTrend: weeklyTrend,
                    readinessAssessment: readinessAssessment,
                    onDismiss: { showVenusWrap = false }
                )
            }
            .task {
                await loadAllMoods()
            }
        }
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
