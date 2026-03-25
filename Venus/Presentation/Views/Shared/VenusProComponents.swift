//
//  VenusProComponents.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI

struct VenusProBadge: View {
    var title: String = "Venus Pro"
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: compact ? 11 : 12, weight: .bold))

            Text(title)
                .font(.system(compact ? .caption2 : .caption, design: .rounded).weight(.black))
                .lineLimit(1)
        }
        .foregroundColor(VenusTheme.accentPurpleDeep)
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 7 : 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(VenusTheme.proGradient.opacity(0.16))
                )
        )
    }
}

private struct VenusProGlassCardStyle: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    VenusTheme.accentPurple.opacity(0.14),
                                    VenusTheme.accentPurpleDeep.opacity(0.07),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
    }
}

extension View {
    func venusProGlassCardStyle(cornerRadius: CGFloat = 28) -> some View {
        modifier(VenusProGlassCardStyle(cornerRadius: cornerRadius))
    }
}
