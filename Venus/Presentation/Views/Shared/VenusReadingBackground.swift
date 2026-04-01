//
//  VenusReadingBackground.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import SwiftUI

// MARK: - Day Moment

enum DayMoment {
    case dawn    // 5-8h
    case morning // 8-12h
    case afternoon // 12-18h
    case evening // 18-21h
    case night   // 21-5h

    static var current: DayMoment {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8:  return .dawn
        case 8..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<21: return .evening
        default:     return .night
        }
    }

    // Cores do background ambient
    var accent: Color {
        switch self {
        case .dawn:      return Color(hex: "FFD580") // dourado suave
        case .morning:   return Color(hex: "FFB347") // laranja quente
        case .afternoon: return Color(hex: "58B887") // verde fresco
        case .evening:   return Color(hex: "F58B74") // rosa-salmão
        case .night:     return Color(hex: "8D5CFF") // roxo profundo
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .dawn:      return Color(hex: "FFF0B0")
        case .morning:   return Color(hex: "FFD580")
        case .afternoon: return Color(hex: "9BF66F")
        case .evening:   return Color(hex: "FFB347")
        case .night:     return Color(hex: "5C8DFF")
        }
    }

    var tertiaryAccent: Color {
        switch self {
        case .dawn:      return Color(hex: "B9EEFF")
        case .morning:   return Color(hex: "D6FFB9")
        case .afternoon: return Color(hex: "B9EEFF")
        case .evening:   return Color(hex: "C4D4FF")
        case .night:     return Color(hex: "E0D4FF")
        }
    }

    // Mood padrão do mascot quando não há check-in
    var defaultMascotMood: MoodType? {
        switch self {
        case .dawn:      return .calm
        case .morning:   return .energetic
        case .afternoon: return nil
        case .evening:   return .calm
        case .night:     return .tired
        }
    }

    var greeting: String {
        switch self {
        case .dawn:      return "Bom dia cedo! Como você acordó?"
        case .morning:   return "Bom dia! Como você está começando o dia?"
        case .afternoon: return "Boa tarde! Como está sendo o seu dia?"
        case .evening:   return "Boa noite! Como foi a tarde?"
        case .night:     return "Como foi o seu dia hoje?"
        }
    }
}

struct VenusReadingBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateAmbient = false

    var accent: Color = VenusTheme.ambientWarm
    var secondaryAccent: Color = VenusTheme.ambientRose
    var tertiaryAccent: Color = VenusTheme.ambientCool
    var isAnimated: Bool = true

    // Inicializador com momento do dia
    init(dayMoment: DayMoment, isAnimated: Bool = true) {
        self.accent = dayMoment.accent
        self.secondaryAccent = dayMoment.secondaryAccent
        self.tertiaryAccent = dayMoment.tertiaryAccent
        self.isAnimated = isAnimated
    }

    // Inicializador manual (retrocompatível)
    init(
        accent: Color = VenusTheme.ambientWarm,
        secondaryAccent: Color = VenusTheme.ambientRose,
        tertiaryAccent: Color = VenusTheme.ambientCool,
        isAnimated: Bool = true
    ) {
        self.accent = accent
        self.secondaryAccent = secondaryAccent
        self.tertiaryAccent = tertiaryAccent
        self.isAnimated = isAnimated
    }

    var body: some View {
        ZStack {
            (colorScheme == .dark ? VenusTheme.background : VenusTheme.backgroundSoft)
                .ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(accent.opacity(colorScheme == .dark ? 0.28 : 0.18))
                        .frame(width: 380, height: 380)
                        .blur(radius: 110)
                        .scaleEffect(animateAmbient ? 1.06 : 0.96)
                        .offset(
                            x: -geometry.size.width * 0.24 + (animateAmbient ? 28 : -10),
                            y: -geometry.size.height * 0.18 + (animateAmbient ? 10 : -14)
                        )

                    Circle()
                        .fill(secondaryAccent.opacity(colorScheme == .dark ? 0.20 : 0.13))
                        .frame(width: 340, height: 340)
                        .blur(radius: 116)
                        .scaleEffect(animateAmbient ? 0.94 : 1.04)
                        .offset(
                            x: geometry.size.width * 0.34 + (animateAmbient ? -24 : 14),
                            y: geometry.size.height * 0.26 + (animateAmbient ? 20 : -12)
                        )

                    Circle()
                        .fill(tertiaryAccent.opacity(colorScheme == .dark ? 0.16 : 0.10))
                        .frame(width: 280, height: 280)
                        .blur(radius: 100)
                        .scaleEffect(animateAmbient ? 1.04 : 0.98)
                        .offset(
                            x: geometry.size.width * 0.1 + (animateAmbient ? 12 : -8),
                            y: geometry.size.height * 0.7 + (animateAmbient ? -18 : 10)
                        )

                    LinearGradient(
                        colors: [
                            accent.opacity(colorScheme == .dark ? 0.12 : 0.14),
                            secondaryAccent.opacity(colorScheme == .dark ? 0.08 : 0.10),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    )

                    RadialGradient(
                        colors: [
                            tertiaryAccent.opacity(colorScheme == .dark ? 0.14 : 0.10),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 20,
                        endRadius: 280
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
