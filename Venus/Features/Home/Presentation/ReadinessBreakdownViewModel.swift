//
//  ReadinessBreakdownViewModel.swift
//  Venus
//
//  Created by Kaua on 08/10/26.
//

import SwiftUI
import Observation

public enum BreakdownCategory: String, CaseIterable, Identifiable, Sendable {
    case overview = "Geral"
    case heart = "Coração"
    case sleep = "Sono"
    case body = "Corpo"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .overview: return "sparkles"
        case .heart: return "heart.fill"
        case .sleep: return "bed.double.fill"
        case .body: return "flame.fill"
        }
    }
}

@Observable
@MainActor
public final class ReadinessBreakdownViewModel {
    // MARK: - Core State
    public let assessment: ReadinessEnergyAssessment
    public var onActionSelected: ((ReadinessActionRecommendation.ActionCategory) -> Void)? = nil
    public var selectedCategory: BreakdownCategory = .overview

    // MARK: - Interactive Inspection States
    public var selectedPillarId: String? = nil
    public var selectedSleepStage: String? = nil

    // MARK: - Coordinated Animation States (Zero-Jank Staggering)
    public var animatedRingProgress: Double = 0.0
    public var animatedScoreInt: Int = 0
    public var showPillars: Bool = false
    public var showBiometrics: Bool = false
    public var showComposition: Bool = false
    public var showCircadian: Bool = false
    public var isPulsingAura: Bool = false

    // MARK: - Initialization
    public init(
        assessment: ReadinessEnergyAssessment,
        onActionSelected: ((ReadinessActionRecommendation.ActionCategory) -> Void)? = nil
    ) {
        self.assessment = assessment
        self.onActionSelected = onActionSelected
    }

    // MARK: - Computed Properties for UI
    public var breakdown: ReadinessBreakdown? {
        assessment.breakdown
    }

    public var scorePercentage: Double {
        assessment.percentage
    }

    public var targetScore100: Int {
        assessment.percentage100
    }

    public var stateTitle: String {
        assessment.level.title
    }

    public var stateEmoji: String {
        assessment.level.emoji
    }

    public var stateSubtitle: String {
        assessment.stateSubtitle.isEmpty ? "Prontidão equilibrada para o seu ritmo." : assessment.stateSubtitle
    }

    public var recommendation: ReadinessActionRecommendation? {
        breakdown?.recommendation
    }

    public var focusMetric: ReadinessPillarMetric {
        assessment.focusMetric
    }

    public var bodyMetric: ReadinessPillarMetric {
        assessment.bodyMetric
    }

    public var sleepMetric: ReadinessPillarMetric {
        assessment.sleepMetric
    }

    public var biometricsUsed: Bool {
        assessment.biometricsUsed
    }

    public var intradayCurve: IntradayEnergyCurve? {
        breakdown?.intradayCurve ?? .sampleDefault
    }

    // MARK: - Lifecycle & Orchestrated Animations
    public func onAppear() {
        guard animatedRingProgress == 0 else { return }

        // 1. Initial Header ring & score count-up
        withAnimation(.spring(response: 0.85, dampingFraction: 0.82)) {
            animatedRingProgress = scorePercentage
        }

        // Animate counter smoothly
        let target = targetScore100
        let steps = 20
        let interval = 0.7 / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * interval)) { [weak self] in
                guard let self = self else { return }
                self.animatedScoreInt = Int((Double(target) * Double(i) / Double(steps)).rounded())
            }
        }

        // 2. Staggered section reveals for 60fps presentation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            withAnimation(.spring(response: 0.75, dampingFraction: 0.85)) {
                self?.showPillars = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { [weak self] in
            withAnimation(.spring(response: 0.75, dampingFraction: 0.85)) {
                self?.showBiometrics = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
            withAnimation(.spring(response: 0.75, dampingFraction: 0.85)) {
                self?.showComposition = true
                self?.showCircadian = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                self?.isPulsingAura = true
            }
        }
    }

    // MARK: - User Actions
    public func selectCategory(_ category: BreakdownCategory) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            selectedCategory = category
        }
    }

    public func handleActionRecommendationTap(dismiss: () -> Void) {
        guard let rec = recommendation else { return }
        dismiss()
        onActionSelected?(rec.category)
    }
}
