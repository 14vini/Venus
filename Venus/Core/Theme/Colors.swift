//
//  Colors.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import UIKit

struct VenusTheme {
    // MARK: - Palette (Modern Sunset Coral & Crisp Porcelain)
    
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

    // Backgrounds & Surfaces (Clean, luminous, porcelain with subtle warm glow)
    static let background = Color(dynamicProvider(light: "#F9F9FB", dark: "#110B08"))
    static let backgroundWarm = Color(dynamicProvider(light: "#F4F5F8", dark: "#1A100B"))
    static let backgroundBlush = Color(dynamicProvider(light: "#FDF2EE", dark: "#26150E"))
    static let backgroundCool = Color(dynamicProvider(light: "#F0F3F8", dark: "#150E0A"))
    static let backgroundSoft = Color(dynamicProvider(light: "#FFFFFF", dark: "#0C0705"))
    static let ambientWarm = Color(dynamicProvider(light: "#FF8C5A", dark: "#943F1A"))
    static let ambientCool = Color(dynamicProvider(light: "#60A5FA", dark: "#A6582E"))
    static let ambientRose = Color(dynamicProvider(light: "#FB7185", dark: "#964536"))
    
    // Glassmorphic surfaces
    static let surface = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ?
            UIColor(hex: "1F130D", alpha: 0.86) :
            UIColor(hex: "FFFFFF", alpha: 0.94)
    })
    
    // Solid card surfaces
    static let cardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "1C120C") : UIColor(hex: "FFFFFF")
    })
    
    static let cardSurfaceStrong = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "150D08") : UIColor(hex: "F4F4F7")
    })
    
    static let cardBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "3D2418", alpha: 0.75) : UIColor(hex: "E5E7EB", alpha: 0.85)
    })

    static let validationError = Color(dynamicProvider(light: "#EF4444", dark: "#FF667B"))
    static let validationErrorSoft = Color(dynamicProvider(light: "#FEF2F2", dark: "#2C1115"))
    static let validationErrorBorder = Color(dynamicProvider(light: "#FECACA", dark: "#6E1F2A"))
    
    // Text (Deep warm onyx / charcoal in light mode, high legibility)
    static let text = Color(dynamicProvider(light: "#18181B", dark: "#FFF5ED"))
    static let textSecondary = Color(dynamicProvider(light: "#64748B", dark: "#D1B9AA"))
    static let textTertiary = Color(dynamicProvider(light: "#94A3B8", dark: "#8F7464"))
    static let textOnPrimary = Color.white
    
    // MARK: - Gradients
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundSoft,
                backgroundWarm.opacity(0.85),
                backgroundBlush.opacity(0.45),
                backgroundCool
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var readingBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundSoft,
                backgroundWarm.opacity(0.7),
                backgroundCool.opacity(0.5)
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
                Color(dynamicProvider(light: "#F0FDF4", dark: "#18110D")),
                Color(dynamicProvider(light: "#DCFCE7", dark: "#291E18")).opacity(0.5),
                backgroundWarm
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
    
    // High-contrast, rich Sunset & Coral button gradient
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#FF6E40", dark: "#FF6C34")),
                Color(dynamicProvider(light: "#FF542E", dark: "#E24E19")),
                Color(dynamicProvider(light: "#E63E14", dark: "#BD390B"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var proGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#8B5CF6", dark: "#7333D4")),
                Color(dynamicProvider(light: "#6D28D9", dark: "#5116A8")),
                Color(dynamicProvider(light: "#4C1D95", dark: "#380A7A"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Components
    static let chipBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "231610", alpha: 0.92) : UIColor(hex: "F1F5F9", alpha: 0.95)
    })
    
    static let chipBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "40271B", alpha: 0.75) : UIColor(hex: "E2E8F0", alpha: 0.9)
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
