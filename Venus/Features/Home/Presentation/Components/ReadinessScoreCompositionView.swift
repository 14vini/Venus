//
//  ReadinessScoreCompositionView.swift
//  Venus
//
//  Created by Kaua on 08/10/26.
//

import SwiftUI

public struct ReadinessScoreCompositionView: View {
    let breakdown: ReadinessBreakdown
    let totalScore: Double
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedScale: CGFloat = 0.0
    
    private var isDark: Bool { colorScheme == .dark }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealColor: Color { Color(hex: "0D9488") }
    
    public init(breakdown: ReadinessBreakdown, totalScore: Double) {
        self.breakdown = breakdown
        self.totalScore = totalScore
    }
    
    private var bioWeightPct: Int {
        if breakdown.biometricScore != nil && breakdown.biometricWeight > 0 {
            return Int((breakdown.biometricWeight * 100).rounded())
        }
        return 0
    }
    
    private var subWeightPct: Int {
        100 - bioWeightPct
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.2.square.badge.arrow.forward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isDark ? mintColor : tealColor)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill((isDark ? mintColor : tealColor).opacity(0.14))
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Composição da Bateria")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                        
                        Text("Equação Ponderada de Sinais Biológicos & Mentais")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", totalScore))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(isDark ? mintColor : tealColor)
                    Text("/ 10")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(VenusTheme.textTertiary)
                }
            }
            
            // Segmented Math Strip (Height: 12px)
            segmentedWeightBar
                .padding(.vertical, 2)
            
            // Weight components legend
            HStack(spacing: 14) {
                if bioWeightPct > 0 {
                    weightLegend(
                        color: isDark ? mintColor : tealColor,
                        title: "Biometria Watch",
                        percentage: "\(bioWeightPct)%",
                        score: breakdown.biometricScore != nil ? String(format: "%.1f", breakdown.biometricScore!) : "--"
                    )
                }
                
                weightLegend(
                    color: isDark ? Color(hex: "A78BFA") : Color(hex: "6366F1"),
                    title: "Check-in Mente",
                    percentage: "\(subWeightPct)%",
                    score: String(format: "%.1f", breakdown.subjectiveScore)
                )
            }
            
            // Chat Delta Bonus/Penalty row if applicable
            if abs(breakdown.chatDelta) >= 0.1 {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(breakdown.chatDelta >= 0 ? (isDark ? mintColor : tealColor) : VenusTheme.accentOrange)
                    
                    Text("Reflexões com Venus:")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                    
                    Text(String(format: "%+.1f pts", breakdown.chatDelta))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(breakdown.chatDelta >= 0 ? (isDark ? mintColor : tealColor) : VenusTheme.accentOrange)
                    
                    Spacer()
                    
                    Text("Decaimento 6h")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(VenusTheme.textTertiary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isDark ? Color(hex: "131313") : Color(hex: "DADADA"))
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isDark ? Color(hex: "171717") : Color(hex: "E8E8E8"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(isDark ? 0.07 : 0.4), lineWidth: 0.8)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.78).delay(0.18)) {
                animatedScale = 1.0
            }
        }
    }
}

// MARK: - Subviews

private extension ReadinessScoreCompositionView {
    var segmentedWeightBar: some View {
        HStack(spacing: 4) {
            if bioWeightPct > 0 {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [isDark ? mintColor : tealColor, Color(hex: "10B981")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: CGFloat(max(0.15, (Double(bioWeightPct) / 100.0) * Double(animatedScale))), anchor: .leading)
            }
            
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "A78BFA"), Color(hex: "6366F1")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: .infinity)
                .scaleEffect(x: CGFloat(max(0.15, (Double(subWeightPct) / 100.0) * Double(animatedScale))), anchor: .leading)
        }
        .frame(height: 12)
    }
    
    func weightLegend(color: Color, title: String, percentage: String, score: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                    
                    Text("(\(percentage))")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                
                Text("Nota: \(score)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ReadinessScoreCompositionView(
        breakdown: .init(
            subjectiveScore: 8.0,
            biometricScore: 8.2,
            biometricWeight: 0.58,
            chatDelta: 0.5
        ),
        totalScore: 8.4
    )
    .padding()
    .preferredColorScheme(.dark)
}
