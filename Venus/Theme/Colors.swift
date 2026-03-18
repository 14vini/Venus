//
//  Colors.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import UIKit

struct VenusTheme {
    // MARK: - Palette (Premium & Vibrant)
    
    // Primary Brand Colors (Refined Purples)
    static let primary = Color(dynamicProvider(light: "#7C3AED", dark: "#B091FF"))
    static let secondary = Color(dynamicProvider(light: "#A855F7", dark: "#D2A8FF"))
    static let tertiary = Color(dynamicProvider(light: "#5B52F5", dark: "#9A94FF"))
    
    // Accents (Vibrant Orange & Pink)
    static let accentOrange = Color(dynamicProvider(light: "#FF5E1F", dark: "#FFB36B"))
    static let accentPink = Color(dynamicProvider(light: "#EC4899", dark: "#F472B6"))
    static let accentBlue = Color(dynamicProvider(light: "#3B82F6", dark: "#60A5FA"))
    static let accentGreen = Color(dynamicProvider(light: "#10B981", dark: "#34D399"))
    
    // Backgrounds & Surfaces
    static let background = Color(dynamicProvider(light: "#FFF7F0", dark: "#120905"))
    static let backgroundWarm = Color(dynamicProvider(light: "#FFD4A6", dark: "#2B1308"))
    static let backgroundBlush = Color(dynamicProvider(light: "#FF8A43", dark: "#65270F"))
    static let backgroundCool = Color(dynamicProvider(light: "#FFE9D1", dark: "#351A0F"))
    static let backgroundSoft = Color(dynamicProvider(light: "#FFFDF9", dark: "#1A0F09"))
    static let ambientWarm = Color(dynamicProvider(light: "#FF5A1F", dark: "#FF8E4C"))
    static let ambientCool = Color(dynamicProvider(light: "#FFC34A", dark: "#FFD06C"))
    static let ambientRose = Color(dynamicProvider(light: "#FF7B4E", dark: "#FF9A73"))
    
    // Glassmorphic surfaces
    static let surface = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? 
            UIColor(hex: "1C1009", alpha: 0.76) :
            UIColor(hex: "FFFDFC", alpha: 0.84)
    })
    
    // Solid card surfaces
    static let cardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "21120C") : UIColor(hex: "FFFCFA")
    })
    
    static let cardSurfaceStrong = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "190D08") : UIColor(hex: "FFF0E2")
    })
    
    static let cardBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "5A2D17", alpha: 0.68) : UIColor(hex: "F3D0B1")
    })
    
    // Text
    static let text = Color(dynamicProvider(light: "#261712", dark: "#FFF5EC"))
    static let textSecondary = Color(dynamicProvider(light: "#7A6255", dark: "#D1B7A4"))
    static let textOnPrimary = Color.white
    
    // MARK: - Gradients
    
    // The main background: warm, comforting, and stronger in orange
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundSoft,
                backgroundWarm.opacity(0.92),
                backgroundBlush.opacity(0.84),
                backgroundCool
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var orangeTopGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "FFD27A"),
                Color(hex: "FF7A24"),
                Color(hex: "D9490F")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var salmonCreamGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "FFF1DE"),
                Color(hex: "FFD7B4"),
                Color(hex: "FFB176")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Glowing aura gradient
    static var auraGradient: RadialGradient {
        RadialGradient(
            colors: [
                accentOrange.opacity(0.36),
                accentPink.opacity(0.16),
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
                Color(hex: "FFB35E"),
                accentOrange,
                Color(hex: "C54514")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Components
    static let chipBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "24140D", alpha: 0.8) : UIColor(hex: "FFF5EA", alpha: 0.92)
    })
    
    static let chipBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "5A2D17", alpha: 0.62) : UIColor(hex: "F0D2BA")
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
