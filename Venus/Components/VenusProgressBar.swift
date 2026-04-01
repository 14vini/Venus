//
//  VenusProgressBar.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    var tint: Color = VenusTheme.primary

    @Environment(\.colorScheme) private var colorScheme

    private var safeTotalSteps: Int { max(totalSteps, 1) }
    private var safeCurrentStep: Int { min(max(currentStep, 1), safeTotalSteps) }

    private var progress: Double {
        Double(safeCurrentStep) / Double(safeTotalSteps)
    }

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.10)
    }
    private var fillColor: Color {
        tint
    }
    private var textColor: Color {
        colorScheme == .dark ? VenusTheme.textSecondary : VenusTheme.text
    }
    private var seenColor: Color {
        tint.opacity(colorScheme == .dark ? 0.42 : 0.30)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<safeTotalSteps, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(segmentColor(for: index))
                        .frame(height: 4)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: safeCurrentStep)

            HStack {
                Text("Passo \(safeCurrentStep) de \(safeTotalSteps)")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundColor(textColor.opacity(0.7))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(.caption2, design: .rounded).weight(.black))
                    .foregroundColor(fillColor)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progresso do onboarding")
        .accessibilityValue("Passo \(safeCurrentStep) de \(safeTotalSteps)")
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .glassEffect(.clear.interactive())
    }

    private func segmentColor(for index: Int) -> Color {
        let currentIndex = safeCurrentStep - 1
        if index < currentIndex { return seenColor }
        if index == currentIndex { return fillColor }
        return trackColor
    }
}

#Preview {
    VStack(spacing: 20) {
        VenusProgressBar(currentStep: 1, totalSteps: 7)
        VenusProgressBar(currentStep: 4, totalSteps: 7)
        VenusProgressBar(currentStep: 7, totalSteps: 7)
    }
    .padding()
    .background(VenusTheme.backgroundGradient)
}
