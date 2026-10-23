//
//  ReadinessBreakdownSheet.swift
//  Venus
//
//  Created by Kaua on 29/09/26.
//

import SwiftUI

public struct ReadinessBreakdownSheet: View {
    @State private var viewModel: ReadinessBreakdownViewModel
    @Namespace private var categoryAnimation
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealColor: Color { Color(hex: "0D9488") }

    public init(
        assessment: ReadinessEnergyAssessment,
        onActionSelected: ((ReadinessActionRecommendation.ActionCategory) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: ReadinessBreakdownViewModel(
            assessment: assessment,
            onActionSelected: onActionSelected
        ))
    }

    public init(viewModel: ReadinessBreakdownViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Open Hero Header Score
                    heroScoreHeader

                    // 2. Action Recommendation Banner (if available)
                    if let rec = viewModel.recommendation {
                        recommendationBanner(rec)
                    }

                    // 3. Animated Segmented Category Bar
                    categorySelectorBar

                    // 4. Dynamic Category Content
                    categoryContent
                        .animation(.easeInOut(duration: 0.22), value: viewModel.selectedCategory)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
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
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
}

// MARK: - Subviews

private extension ReadinessBreakdownSheet {
    var heroScoreHeader: some View {
        HStack(spacing: 18) {
            // Luminous Battery Ring (90px)
            ZStack {
                Circle()
                    .stroke(isDark ? mintColor.opacity(0.16) : tealColor.opacity(0.12), lineWidth: 9)
                    .frame(width: 88, height: 88)

                Circle()
                    .trim(from: 0, to: viewModel.animatedRingProgress)
                    .stroke(
                        LinearGradient(
                            colors: [isDark ? Color(hex: "1BE3B0") : tealColor, isDark ? mintColor : Color(hex: "0F766E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 88, height: 88)
                    .shadow(color: (isDark ? mintColor : tealColor).opacity(viewModel.isPulsingAura ? 0.38 : 0.12), radius: 8)

                VStack(spacing: 0) {
                    Text("\(viewModel.animatedScoreInt)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(isDark ? mintColor : tealColor)
                        .contentTransition(.numericText())
                    
                    Text("%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.textTertiary)
                }
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.stateTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Text(viewModel.stateSubtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    func recommendationBanner(_ rec: ReadinessActionRecommendation) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Circle()
                .fill(VenusTheme.primary.opacity(0.16))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: rec.iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(VenusTheme.primary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(rec.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Text(rec.subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                viewModel.handleActionRecommendationTap {
                    dismiss()
                }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(VenusTheme.primary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDark ? Color(hex: "17191E") : Color(hex: "E4E4E4"))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(VenusTheme.primary.opacity(0.28), lineWidth: 1)
                )
        )
    }

    var categorySelectorBar: some View {
        HStack(spacing: 4) {
            ForEach(BreakdownCategory.allCases) { cat in
                let isSelected = viewModel.selectedCategory == cat
                
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        viewModel.selectCategory(cat)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 11, weight: .bold))
                        
                        Text(cat.rawValue)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(isSelected ? (isDark ? Color.black : Color.white) : VenusTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(isDark ? mintColor : tealColor)
                                .matchedGeometryEffect(id: "CATEGORY_TAB", in: categoryAnimation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(isDark ? Color(hex: "14161B") : Color(hex: "DFE2E6"))
        )
    }

    @ViewBuilder
    var categoryContent: some View {
        switch viewModel.selectedCategory {
        case .overview:
            overviewCategoryContent
        case .heart:
            heartCategoryContent
        case .sleep:
            sleepCategoryContent
        case .body:
            bodyCategoryContent
        }
    }

    var overviewCategoryContent: some View {
        VStack(spacing: 18) {
            // Concentric Tri-Pillar Balance
            ReadinessPillarBalanceChart(
                focusMetric: viewModel.focusMetric,
                bodyMetric: viewModel.bodyMetric,
                sleepMetric: viewModel.sleepMetric
            )

            // Circadian Energy Flow Section
            if let curve = viewModel.intradayCurve {
                intradayCurveSection(curve)
            }

            // Score Composition Math
            if let bd = viewModel.breakdown {
                scoreCompositionSection(bd)
            }
        }
    }

    var heartCategoryContent: some View {
        VStack(spacing: 18) {
            // HRV Wave Spectrum
            ReadinessHRVSpectrumView(
                currentHRV: viewModel.breakdown?.hrvCurrent,
                baselineAverage: viewModel.breakdown?.hrvBaselineAverage,
                ratio: viewModel.breakdown?.hrvRatio
            )

            // Heart Rate Dip
            ReadinessHeartRateDipView(
                restingHR: viewModel.breakdown?.restingHR,
                sleepingHR: viewModel.breakdown?.sleepingHR,
                hrDipPercentage: viewModel.breakdown?.hrDipPercentage
            )
        }
    }

    var sleepCategoryContent: some View {
        VStack(spacing: 18) {
            // Clean Sleep Architecture Bar Chart
            ReadinessSleepArchitectureView(
                sleepDurationHours: viewModel.breakdown?.sleepDurationHours,
                restorativeSleepHours: viewModel.breakdown?.restorativeSleepHours,
                sleepRespiratoryRate: viewModel.breakdown?.sleepRespiratoryRate
            )

            // Night Dip
            ReadinessHeartRateDipView(
                restingHR: viewModel.breakdown?.restingHR,
                sleepingHR: viewModel.breakdown?.sleepingHR,
                hrDipPercentage: viewModel.breakdown?.hrDipPercentage
            )
        }
    }

    var bodyCategoryContent: some View {
        VStack(spacing: 18) {
            // Physical Strain Gauge
            ReadinessStrainGaugeView(
                yesterdayActiveEnergy: viewModel.breakdown?.yesterdayActiveEnergy,
                yesterdayWorkoutMinutes: viewModel.breakdown?.yesterdayWorkoutDurationMinutes
            )

            // Concentric Tri-Pillar Body focus
            ReadinessPillarBalanceChart(
                focusMetric: viewModel.focusMetric,
                bodyMetric: viewModel.bodyMetric,
                sleepMetric: viewModel.sleepMetric
            )
        }
    }

    func scoreCompositionSection(_ bd: ReadinessBreakdown) -> some View {
        ReadinessScoreCompositionView(
            breakdown: bd,
            totalScore: viewModel.assessment.score
        )
    }

    func intradayCurveSection(_ curve: IntradayEnergyCurve) -> some View {
        IntradayEnergyCurveView(curve: curve, baseScore: viewModel.assessment.score)
    }
}

#Preview {
    ReadinessBreakdownSheet(assessment: .sampleDefault)
        .preferredColorScheme(.dark)
}
