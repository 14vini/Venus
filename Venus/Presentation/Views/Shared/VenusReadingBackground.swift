//
//  VenusReadingBackground.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI

struct VenusReadingBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateAmbient = false

    var accent: Color = VenusTheme.ambientWarm
    var secondaryAccent: Color = VenusTheme.ambientRose
    var tertiaryAccent: Color = VenusTheme.ambientCool
    var isAnimated: Bool = true

    var body: some View {
        ZStack {
            (colorScheme == .dark ? VenusTheme.background : VenusTheme.backgroundSoft)
                .ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(accent.opacity(colorScheme == .dark ? 0.22 : 0.14))
                        .frame(width: 360, height: 360)
                        .blur(radius: 104)
                        .scaleEffect(animateAmbient ? 1.06 : 0.96)
                        .offset(
                            x: -geometry.size.width * 0.24 + (animateAmbient ? 28 : -10),
                            y: -geometry.size.height * 0.18 + (animateAmbient ? 10 : -14)
                        )

                    Circle()
                        .fill(secondaryAccent.opacity(colorScheme == .dark ? 0.16 : 0.1))
                        .frame(width: 320, height: 320)
                        .blur(radius: 108)
                        .scaleEffect(animateAmbient ? 0.94 : 1.04)
                        .offset(
                            x: geometry.size.width * 0.34 + (animateAmbient ? -24 : 14),
                            y: geometry.size.height * 0.26 + (animateAmbient ? 20 : -12)
                        )

                    Circle()
                        .fill(tertiaryAccent.opacity(colorScheme == .dark ? 0.14 : 0.08))
                        .frame(width: 260, height: 260)
                        .blur(radius: 92)
                        .scaleEffect(animateAmbient ? 1.04 : 0.98)
                        .offset(
                            x: geometry.size.width * 0.1 + (animateAmbient ? 12 : -8),
                            y: geometry.size.height * 0.7 + (animateAmbient ? -18 : 10)
                        )

                    LinearGradient(
                        colors: [
                            accent.opacity(colorScheme == .dark ? 0.1 : 0.12),
                            secondaryAccent.opacity(colorScheme == .dark ? 0.07 : 0.1),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    )

                    RadialGradient(
                        colors: [
                            tertiaryAccent.opacity(colorScheme == .dark ? 0.14 : 0.1),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 20,
                        endRadius: 260
                    )
                    .offset(x: geometry.size.width * 0.08, y: geometry.size.height * 0.04)
                }
                .ignoresSafeArea()
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard isAnimated, !animateAmbient else { return }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animateAmbient = true
            }
        }
    }
}
