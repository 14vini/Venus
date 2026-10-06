//
//  Colors.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import UIKit

struct VenusTheme {
    // MARK: - Palette (Pure Monochrome Neumorphism & Clean Grayscale)
    
    // Primary Brand Colors
    static let primary = Color(dynamicProvider(light: "#FF5C38", dark: "#FF733E"))
    static let primaryLight = Color(dynamicProvider(light: "#FF8159", dark: "#FF9A6E"))
    static let primaryDark = Color(dynamicProvider(light: "#E04818", dark: "#E6501C"))
    static let secondary = Color(dynamicProvider(light: "#FF7E56", dark: "#FFA076"))
    static let tertiary = Color(dynamicProvider(light: "#FFAA8A", dark: "#FFC2A3"))
    
    // Accents
    static let accentOrange = Color(dynamicProvider(light: "#FF5C38", dark: "#FF7E4A"))
    static let accentPink = Color(dynamicProvider(light: "#EC4899", dark: "#FF759E"))
    static let accentBlue = Color(dynamicProvider(light: "#3B82F6", dark: "#6EA0F5"))
    static let accentGreen = Color(dynamicProvider(light: "#10B981", dark: "#55CE90"))
    static let accentPurple = Color(dynamicProvider(light: "#8B5CF6", dark: "#AD7AF7"))
    static let accentPurpleDeep = Color(dynamicProvider(light: "#6D28D9", dark: "#8855D6"))
    static let moodMint = Color(dynamicProvider(light: "#10B981", dark: "#50CFA4"))
    static let moodMintStrong = Color(dynamicProvider(light: "#059669", dark: "#40BC90"))
    static let moodSage = Color(dynamicProvider(light: "#E2E8F0", dark: "#291E18"))
    static let moodMist = Color(dynamicProvider(light: "#F1F5F9", dark: "#18110D"))
    static let moodCream = Color(dynamicProvider(light: "#FAFAFA", dark: "#1C1410"))
    
    // Mood Colors
    static let moodHappy = Color(dynamicProvider(light: "#F59E0B", dark: "#FFB940"))
    static let moodCalm = Color(dynamicProvider(light: "#10B981", dark: "#56CD95"))
    static let moodEnergetic = Color(dynamicProvider(light: "#EF4444", dark: "#FF6A5E"))
    static let moodTired = Color(dynamicProvider(light: "#6366F1", dark: "#7CA5EE"))
    static let moodStressed = Color(dynamicProvider(light: "#F97316", dark: "#FF7847"))
    static let moodSad = Color(dynamicProvider(light: "#8B5CF6", dark: "#B582F7"))

    // MARK: - Pure Monochrome Neumorphic Backgrounds & Surfaces (Black & White Only)
    static let background = Color(dynamicProvider(light: "#E3E3E3", dark: "#141414"))
    static let backgroundWarm = Color(dynamicProvider(light: "#DFDFDF", dark: "#181818"))
    static let backgroundBlush = Color(dynamicProvider(light: "#E1E1E1", dark: "#161616"))
    static let backgroundCool = Color(dynamicProvider(light: "#DDDDDD", dark: "#1A1A1A"))
    static let backgroundSoft = Color(dynamicProvider(light: "#E3E3E3", dark: "#121212"))
    static let ambientWarm = Color(dynamicProvider(light: "#888888", dark: "#333333"))
    static let ambientCool = Color(dynamicProvider(light: "#888888", dark: "#333333"))
    static let ambientRose = Color(dynamicProvider(light: "#888888", dark: "#333333"))
    
    // Glassmorphic surfaces (Monochrome)
    static let surface = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ?
            UIColor(hex: "202020", alpha: 0.90) :
            UIColor(hex: "E3E3E3", alpha: 0.95)
    })
    
    // Solid card surfaces (Monochrome matching canvas for tactile 3D relief)
    static let cardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "202020") : UIColor(hex: "E3E3E3")
    })
    
    static let cardSurfaceStrong = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "1A1A1A") : UIColor(hex: "D8D8D8")
    })
    
    static let cardBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "333333", alpha: 0.7) : UIColor(hex: "FFFFFF", alpha: 0.7)
    })

    // MARK: - Pure Monochrome Neumorphic Tokens (Softened White Highlight & Deep Black Shadow)
    static let neumorphicBase = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "141414") : UIColor(hex: "E3E3E3")
    })

    static let neumorphicShadowDark = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor.black.withAlphaComponent(0.98) :
            UIColor(hex: "9E9E9E").withAlphaComponent(0.85)
    })

    static let neumorphicShadowLight = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor.white.withAlphaComponent(0.09) :
            UIColor.white.withAlphaComponent(0.80)
    })

    static let neumorphicBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ?
            UIColor.white.withAlphaComponent(0.14) :
            UIColor.white.withAlphaComponent(0.60)
    })

    static let validationError = Color(dynamicProvider(light: "#EF4444", dark: "#FF667B"))
    static let validationErrorSoft = Color(dynamicProvider(light: "#FEF2F2", dark: "#2C1115"))
    static let validationErrorBorder = Color(dynamicProvider(light: "#FECACA", dark: "#6E1F2A"))
    
    // Text (Monochrome high-contrast)
    static let text = Color(dynamicProvider(light: "#171717", dark: "#F5F5F5"))
    static let textSecondary = Color(dynamicProvider(light: "#5A5A5A", dark: "#A8A8A8"))
    static let textTertiary = Color(dynamicProvider(light: "#8E8E8E", dark: "#707070"))
    static let textOnPrimary = Color.white
    
    // MARK: - Gradients (Monochrome Black & White)
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundSoft,
                backgroundWarm,
                backgroundSoft
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var readingBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundSoft,
                backgroundWarm,
                backgroundCool
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var orangeTopGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#FFA270", dark: "#E67836")),
                Color(dynamicProvider(light: "#FF6536", dark: "#CC5016")),
                Color(dynamicProvider(light: "#E04818", dark: "#A63207"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var salmonCreamGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#FFFFFF", dark: "#231610")),
                Color(dynamicProvider(light: "#FFF5EE", dark: "#352018")),
                Color(dynamicProvider(light: "#FDEAE0", dark: "#46281E"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var homeMintGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundSoft,
                backgroundWarm,
                backgroundSoft
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var moodOrbGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#FFAE82", dark: "#FF8A54")),
                Color(dynamicProvider(light: "#FF6536", dark: "#E2531D")),
                Color(dynamicProvider(light: "#D94418", dark: "#AE3108"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var homeWaveGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentOrange.opacity(0.12),
                primary.opacity(0.48),
                primaryDark.opacity(0.88)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    static var auraGradient: RadialGradient {
        RadialGradient(
            colors: [
                primary.opacity(0.20),
                secondary.opacity(0.10),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
    }
    
    // High-contrast primary button gradient
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#262626", dark: "#EDEDED")),
                Color(dynamicProvider(light: "#121212", dark: "#D4D4D4"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var proGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#333333", dark: "#CCCCCC")),
                Color(dynamicProvider(light: "#1A1A1A", dark: "#AAAAAA"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Pure Monochrome Neumorphic Card Gradients (Black & White Only)
    static var neumorphicRaisedGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#ECECEC", dark: "#272727")),
                Color(dynamicProvider(light: "#DBDBDB", dark: "#1A1A1A"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var neumorphicSunkenGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#D4D4D4", dark: "#121212")),
                Color(dynamicProvider(light: "#EBEBEB", dark: "#222222"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var neumorphicFlatGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#E3E3E3", dark: "#202020")),
                Color(dynamicProvider(light: "#DFDFDF", dark: "#1C1C1C"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Components (Monochrome)
    static let chipBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "222222", alpha: 0.95) : UIColor(hex: "D8D8D8", alpha: 0.95)
    })
    
    static let chipBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "3A3A3A", alpha: 0.8) : UIColor(hex: "FFFFFF", alpha: 0.8)
    })
    
    static let darkGreen = accentGreen
    
    // Helper to create dynamic UIColor
    private static func dynamicProvider(light: String, dark: String) -> UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue:  CGFloat(b) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}
