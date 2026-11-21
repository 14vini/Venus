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

    @Environment(\.colorScheme) private var colorScheme

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
        .glassEffect(
            .regular.tint(VenusTheme.accentPurple.opacity(colorScheme == .dark ? 0.16 : 0.10)),
            in: Capsule(style: .continuous)
        )
    }
}

private struct VenusProGlassCardStyle: ViewModifier {
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .glassEffect(
                .regular.tint(VenusTheme.accentPurple.opacity(colorScheme == .dark ? 0.12 : 0.07)),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

extension View {
    func venusProGlassCardStyle(cornerRadius: CGFloat = 28) -> some View {
        modifier(VenusProGlassCardStyle(cornerRadius: cornerRadius))
    }
}
