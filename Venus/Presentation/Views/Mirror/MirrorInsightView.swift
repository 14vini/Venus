//
//  MirrorInsightView.swift
//  Venus
//

import SwiftUI

struct MirrorInsightView: View {
    let insightText: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.moodMintStrong,
                secondaryAccent: VenusTheme.moodSage,
                tertiaryAccent: VenusTheme.accentGreen,
                isAnimated: true
            )

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(VenusTheme.textSecondary)
                            .padding(14)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 32) {
                    Text("O Espelho")
                        .font(.system(.subheadline, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.moodMintStrong)
                        .tracking(1.5)
                        .textCase(.uppercase)

                    Text(insightText)
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundColor(VenusTheme.text)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
    }
}
