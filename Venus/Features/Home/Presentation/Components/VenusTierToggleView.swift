//
//  VenusTierToggleView.swift
//  Venus
//
//  Seletor em cápsula de vidro no canto superior direito: [ Basic | Premium ]
//  Fiel ao design do screenshot com pílula branca deslizante.
//

import SwiftUI

public enum VenusAppTier: String, CaseIterable, Sendable {
    case basic = "Basic"
    case premium = "Premium"
}

public struct VenusTierToggleView: View {
    @Binding public var selectedTier: VenusAppTier
    public var onPremiumTap: (() -> Void)? = nil

    @Namespace private var animationNamespace

    public init(
        selectedTier: Binding<VenusAppTier>,
        onPremiumTap: (() -> Void)? = nil
    ) {
        self._selectedTier = selectedTier
        self.onPremiumTap = onPremiumTap
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(VenusAppTier.allCases, id: \.self) { tier in
                let isSelected = selectedTier == tier

                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selectedTier = tier
                    }
                    if tier == .premium {
                        onPremiumTap?()
                    }
                } label: {
                    Text(tier.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(isSelected ? Color(hex: "111827") : Color.white.opacity(0.72))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .fixedSize(horizontal: true, vertical: false)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
                                    .matchedGeometryEffect(id: "ActiveTierPill", in: animationNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.28))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "1F2E3A").ignoresSafeArea()
        VenusTierToggleView(selectedTier: .constant(.premium))
    }
}
