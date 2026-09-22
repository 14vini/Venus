//
//  Colors.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import UIKit

struct VenusTheme {
    // MARK: - Palette (Peach, Terracotta & Warm Sunset)
    
    // Primary Brand Colors
    static let primary = Color(dynamicProvider(light: "#E05320", dark: "#FF733E"))
    static let primaryLight = Color(dynamicProvider(light: "#F07B4D", dark: "#FF9A6E"))
    static let primaryDark = Color(dynamicProvider(light: "#B83A0F", dark: "#E6501C"))
    static let secondary = Color(dynamicProvider(light: "#F07B4D", dark: "#FFA076"))
    static let tertiary = Color(dynamicProvider(light: "#F7A37C", dark: "#FFC2A3"))
    
    // Accents
    static let accentOrange = Color(dynamicProvider(light: "#E05320", dark: "#FF7E4A"))
    static let accentPink = Color(dynamicProvider(light: "#D84A6F", dark: "#FF759E"))
    static let accentBlue = Color(dynamicProvider(light: "#3E74C4", dark: "#6EA0F5"))
    static let accentGreen = Color(dynamicProvider(light: "#389462", dark: "#55CE90"))
    static let accentPurple = Color(dynamicProvider(light: "#7B4BBF", dark: "#AD7AF7"))
    static let accentPurpleDeep = Color(dynamicProvider(light: "#582C96", dark: "#8855D6"))
    static let moodMint = Color(dynamicProvider(light: "#58B896", dark: "#50CFA4"))
    static let moodMintStrong = Color(dynamicProvider(light: "#2B9471", dark: "#40BC90"))
    static let moodSage = Color(dynamicProvider(light: "#EADFD5", dark: "#291E18"))
    static let moodMist = Color(dynamicProvider(light: "#F9F3EC", dark: "#18110D"))
    static let moodCream = Color(dynamicProvider(light: "#FDFBF7", dark: "#1C1410"))
    
    // Mood Colors
    static let moodHappy = Color(dynamicProvider(light: "#E2981E", dark: "#FFB940"))
    static let moodCalm = Color(dynamicProvider(light: "#389A6B", dark: "#56CD95"))
    static let moodEnergetic = Color(dynamicProvider(light: "#E64438", dark: "#FF6A5E"))
    static let moodTired = Color(dynamicProvider(light: "#4874BD", dark: "#7CA5EE"))
    static let moodStressed = Color(dynamicProvider(light: "#D85324", dark: "#FF7847"))
    static let moodSad = Color(dynamicProvider(light: "#8250BD", dark: "#B582F7"))

    // Backgrounds & Surfaces
    static let background = Color(dynamicProvider(light: "#FDF8F4", dark: "#110B08"))
    static let backgroundWarm = Color(dynamicProvider(light: "#F8ECE1", dark: "#1A100B"))
    static let backgroundBlush = Color(dynamicProvider(light: "#F4DFCE", dark: "#26150E"))
    static let backgroundCool = Color(dynamicProvider(light: "#FAF0E8", dark: "#150E0A"))
    static let backgroundSoft = Color(dynamicProvider(light: "#FFFDFC", dark: "#0C0705"))
    static let ambientWarm = Color(dynamicProvider(light: "#E57B4A", dark: "#943F1A"))
    static let ambientCool = Color(dynamicProvider(light: "#F5AD83", dark: "#A6582E"))
    static let ambientRose = Color(dynamicProvider(light: "#E58A78", dark: "#964536"))
    
    // Glassmorphic surfaces
    static let surface = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ?
            UIColor(hex: "1F130D", alpha: 0.86) :
            UIColor(hex: "FFFFFF", alpha: 0.88)
    })
    
    // Solid card surfaces
    static let cardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "1C120C") : UIColor(hex: "FFFFFF")
    })
    
    static let cardSurfaceStrong = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "150D08") : UIColor(hex: "F8EFE7")
    })
    
    static let cardBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "3D2418", alpha: 0.75) : UIColor(hex: "ECDACD")
    })

    static let validationError = Color(dynamicProvider(light: "#D23448", dark: "#FF667B"))
    static let validationErrorSoft = Color(dynamicProvider(light: "#FDF2F4", dark: "#2C1115"))
    static let validationErrorBorder = Color(dynamicProvider(light: "#F6B4C0", dark: "#6E1F2A"))
    
    // Text
    static let text = Color(dynamicProvider(light: "#24140D", dark: "#FFF5ED"))
    static let textSecondary = Color(dynamicProvider(light: "#664E41", dark: "#D1B9AA"))
    static let textTertiary = Color(dynamicProvider(light: "#947666", dark: "#8F7464"))
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
                backgroundWarm.opacity(0.85),
                backgroundCool
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var orangeTopGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#FFA56E", dark: "#E67836")),
                Color(dynamicProvider(light: "#EE6928", dark: "#CC5016")),
                Color(dynamicProvider(light: "#CB4610", dark: "#A63207"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var salmonCreamGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#FFF8F3", dark: "#231610")),
                Color(dynamicProvider(light: "#FCE7DB", dark: "#352018")),
                Color(dynamicProvider(light: "#F5CDBB", dark: "#46281E"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var homeMintGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundSoft,
                moodMist,
                moodSage.opacity(0.6),
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
                Color(dynamicProvider(light: "#F26935", dark: "#E2531D")),
                Color(dynamicProvider(light: "#C64112", dark: "#AE3108"))
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
                primary.opacity(0.24),
                secondary.opacity(0.14),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
    }
    
    // High-contrast, rich Sunset & Terracotta button gradient (ensures 100% legibility of white text)
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#E65A26", dark: "#FF6C34")),
                Color(dynamicProvider(light: "#D24514", dark: "#E24E19")),
                Color(dynamicProvider(light: "#B23307", dark: "#BD390B"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var proGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(dynamicProvider(light: "#8246DE", dark: "#7333D4")),
                Color(dynamicProvider(light: "#6124B8", dark: "#5116A8")),
                Color(dynamicProvider(light: "#45128F", dark: "#380A7A"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Components
    static let chipBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "231610", alpha: 0.92) : UIColor(hex: "F9EFE6", alpha: 0.95)
    })
    
    static let chipBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "40271B", alpha: 0.75) : UIColor(hex: "E6D2C3")
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
