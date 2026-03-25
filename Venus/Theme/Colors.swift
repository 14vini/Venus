//
//  Colors.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import UIKit

struct VenusTheme {
    // MARK: - Palette (Warm, Bright, and Comfortable)
    
    // Primary Brand Colors
    static let primary = Color(dynamicProvider(light: "#56C271", dark: "#85EA92"))
    static let secondary = Color(dynamicProvider(light: "#7FD38B", dark: "#A2F0AA"))
    static let tertiary = Color(dynamicProvider(light: "#A9E4AF", dark: "#BFF4C3"))
    
    // Accents
    static let accentOrange = Color(dynamicProvider(light: "#FF6424", dark: "#FFB36B"))
    static let accentPink = Color(dynamicProvider(light: "#F58B74", dark: "#FFB3A0"))
    static let accentBlue = Color(dynamicProvider(light: "#5C8DFF", dark: "#9BC0FF"))
    static let accentGreen = Color(dynamicProvider(light: "#58B887", dark: "#7AD0A3"))
    static let accentPurple = Color(dynamicProvider(light: "#8D5CFF", dark: "#C6A7FF"))
    static let accentPurpleDeep = Color(dynamicProvider(light: "#6937D8", dark: "#9B72FF"))
    static let moodMint = Color(dynamicProvider(light: "#9BF66F", dark: "#83E96E"))
    static let moodMintStrong = Color(dynamicProvider(light: "#59D85A", dark: "#7EF07E"))
    static let moodSage = Color(dynamicProvider(light: "#D2E0CC", dark: "#203124"))
    static let moodMist = Color(dynamicProvider(light: "#EBF2E6", dark: "#121713"))
    static let moodCream = Color(dynamicProvider(light: "#FFFDF7", dark: "#1B201A"))
    
    // Backgrounds & Surfaces
    static let background = Color(dynamicProvider(light: "#F6FBF5", dark: "#0D150F"))
    static let backgroundWarm = Color(dynamicProvider(light: "#E7F4E4", dark: "#142116"))
    static let backgroundBlush = Color(dynamicProvider(light: "#D5ECCC", dark: "#1C2C1F"))
    static let backgroundCool = Color(dynamicProvider(light: "#EEF8EB", dark: "#16241A"))
    static let backgroundSoft = Color(dynamicProvider(light: "#FCFEFB", dark: "#101813"))
    static let ambientWarm = Color(dynamicProvider(light: "#8BD48B", dark: "#5DAF62"))
    static let ambientCool = Color(dynamicProvider(light: "#C5E8BB", dark: "#7ACB7B"))
    static let ambientRose = Color(dynamicProvider(light: "#B7DDB1", dark: "#6DAA73"))
    
    // Glassmorphic surfaces
    static let surface = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ?
            UIColor(hex: "18231A", alpha: 0.8) :
            UIColor(hex: "FFFFFF", alpha: 0.84)
    })
    
    // Solid card surfaces
    static let cardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "182119") : UIColor(hex: "FFFFFF")
    })
    
    static let cardSurfaceStrong = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "121A14") : UIColor(hex: "F2F7EF")
    })
    
    static let cardBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "435544", alpha: 0.72) : UIColor(hex: "C7D8C2")
    })

    static let validationError = Color(dynamicProvider(light: "#D84F62", dark: "#FF94A0"))
    static let validationErrorSoft = Color(dynamicProvider(light: "#FCECEF", dark: "#34181D"))
    static let validationErrorBorder = Color(dynamicProvider(light: "#F2B8C0", dark: "#73313B"))
    
    // Text
    static let text = Color(dynamicProvider(light: "#183223", dark: "#F4FFF7"))
    static let textSecondary = Color(dynamicProvider(light: "#4D6656", dark: "#C7DCCA"))
    static let textOnPrimary = Color.white
    
    // MARK: - Gradients
    
    // The main background: clear, warm, and bright in orange
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundSoft,
                backgroundWarm.opacity(0.88),
                backgroundBlush.opacity(0.52),
                backgroundCool
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var readingBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "F1FAED"),
                Color(hex: "E8F6E2"),
                backgroundWarm.opacity(0.98),
                backgroundBlush.opacity(0.42),
                Color(hex: "EDF8E8")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var orangeTopGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "DDF5CF"),
                Color(hex: "82D686"),
                Color(hex: "4AA95C")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var salmonCreamGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "FAFEF8"),
                Color(hex: "E5F4E0"),
                Color(hex: "C6E7BE")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var homeMintGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                moodMist,
                moodSage.opacity(0.96),
                Color(hex: "EEF5EA")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var moodOrbGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "D6FFB9"),
                moodMint,
                moodMintStrong,
                Color(hex: "7DDC73")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var homeWaveGradient: LinearGradient {
        LinearGradient(
            colors: [
                moodMint.opacity(0.18),
                moodMintStrong.opacity(0.78),
                Color(hex: "86FF84")
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    // Glowing aura gradient
    static var auraGradient: RadialGradient {
        RadialGradient(
            colors: [
                primary.opacity(0.28),
                secondary.opacity(0.18),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
    }
    
    // Button gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "D8F6CF"),
                primary,
                Color(hex: "3E9D50")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var proGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentPurple,
                accentPurpleDeep,
                Color(dynamicProvider(light: "#B892FF", dark: "#D8C1FF"))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Components
    static let chipBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "1E2E20", alpha: 0.9) : UIColor(hex: "F1F7EE", alpha: 0.96)
    })
    
    static let chipBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "2E4A32", alpha: 0.72) : UIColor(hex: "C4D6BF")
    })
    
    static let darkGreen = accentGreen
    
    // Helper to create dynamic UIColor
    private static func dynamicProvider(light: String, dark: String) -> UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

// Helper for Hex to UIColor
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

// SwiftUI Color extension using the same hex logic if needed, but we rely on UIColor now
extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}
