//
//  VenusCard.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var padding: CGFloat
    var style: VenusNeumorphicStyle
    var depth: CGFloat
    var showBorder: Bool
    
    init(
        cornerRadius: CGFloat = 28,
        padding: CGFloat = 20,
        style: VenusNeumorphicStyle = .raised,
        depth: CGFloat = 8,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.style = style
        self.depth = depth
        self.showBorder = showBorder
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .neumorphicCard(
                cornerRadius: cornerRadius,
                style: style,
                depth: depth,
                showBorder: showBorder
            )
    }
}

#Preview("Neumorphic Showcase - Monochrome B&W") {
    ZStack {
        VenusTheme.background.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("NEUMORPHISM")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .tracking(6)
                    .padding(.top, 10)
                
                // Top Row (Profile & Quick Scene - Monochrome)
                HStack(spacing: 16) {
                    // Circular Avatar
                    ZStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(VenusTheme.text)
                    }
                    .frame(width: 54, height: 54)
                    .neumorphicCircle(style: .raised, depth: 6)
                    
                    // Pill Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Olá, Usuário")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(VenusTheme.text)
                            Text("7 dispositivos ativos")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                        Spacer()
                        VStack(spacing: 4) {
                            Circle().fill(VenusTheme.textSecondary).frame(width: 4, height: 4)
                            Circle().fill(VenusTheme.textTertiary).frame(width: 4, height: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .neumorphicCard(cornerRadius: 22, style: .raised, depth: 6)
                }
                
                // Main Raised Card (Thermostat / Gauge style)
                VenusCard(cornerRadius: 30, padding: 22, style: .raised, depth: 9) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Air Conditioner")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(VenusTheme.text)
                                Text("Auto Cooling")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(VenusTheme.textSecondary)
                            }
                            Spacer()
                            
                            // Sunken Toggle Slot with Raised Power Button
                            HStack(spacing: 6) {
                                Text("On.")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(VenusTheme.textSecondary)
                                Image(systemName: "power")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(VenusTheme.text)
                                    .frame(width: 24, height: 24)
                                    .neumorphicCircle(style: .raised, depth: 3)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .neumorphicCard(cornerRadius: 18, style: .sunken, depth: 4)
                        }
                        
                        // Center Stat
                        VStack(spacing: 4) {
                            Text("24°")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(VenusTheme.text)
                            Text("Temperature")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                }
                
                // Analytics Card with Sunken Monochrome Rows (Matching Reference Image)
                VenusCard(cornerRadius: 30, padding: 20, style: .raised, depth: 9) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(VenusTheme.text)
                                    .font(.system(size: 15, weight: .bold))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI Power Analytics")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(VenusTheme.text)
                                    Text("Daily Usage")
                                        .font(.system(size: 11, weight: .regular, design: .rounded))
                                        .foregroundColor(VenusTheme.textSecondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(VenusTheme.text)
                                .frame(width: 30, height: 30)
                                .neumorphicCircle(style: .raised, depth: 4)
                        }
                        
                        // Sunken Rows
                        VStack(spacing: 10) {
                            ForEach([
                                ("Air Conditioner", "2 Unit | 18 kWh", "tv.fill"),
                                ("Wi-Fi Router", "1 Unit | 8 kWh", "wifi"),
                                ("Smart TV", "2 Unit | 12 kWh", "tv"),
                                ("Humidifier", "1 Unit | 2 kWh", "drop.fill")
                            ], id: \.0) { title, val, icon in
                                HStack {
                                    Image(systemName: icon)
                                        .foregroundColor(VenusTheme.text)
                                        .font(.system(size: 13))
                                        .frame(width: 32, height: 32)
                                        .neumorphicCircle(style: .sunken, depth: 3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(title)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(VenusTheme.text)
                                        Text(val)
                                            .font(.system(size: 11, weight: .regular, design: .rounded))
                                            .foregroundColor(VenusTheme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(VenusTheme.textTertiary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .neumorphicCard(cornerRadius: 18, style: .sunken, depth: 4)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
