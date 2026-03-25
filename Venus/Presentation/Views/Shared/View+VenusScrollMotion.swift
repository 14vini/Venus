//
//  View+VenusScrollMotion.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI

enum VenusScrollMotionStyle {
    case gentle
    case strong

    var scale: CGFloat {
        switch self {
        case .gentle: return 0.985
        case .strong: return 0.97
        }
    }

    var opacity: Double {
        switch self {
        case .gentle: return 0.92
        case .strong: return 0.85
        }
    }

    var yOffset: CGFloat {
        switch self {
        case .gentle: return 6
        case .strong: return 12
        }
    }

}

private struct VenusScrollMotionModifier: ViewModifier {
    let style: VenusScrollMotionStyle

    func body(content: Content) -> some View {
        let opacity = style.opacity
        let scale = style.scale
        let yOffset = style.yOffset

        content.scrollTransition(.animated(.smooth(duration: 0.35))) { view, phase in
            view
                .opacity(phase.isIdentity ? 1 : opacity)
                .scaleEffect(phase.isIdentity ? 1 : scale)
                .offset(y: phase.isIdentity ? 0 : yOffset)
        }
    }
}

extension View {
    func venusScrollMotion(_ style: VenusScrollMotionStyle = .gentle) -> some View {
        modifier(VenusScrollMotionModifier(style: style))
    }
}
