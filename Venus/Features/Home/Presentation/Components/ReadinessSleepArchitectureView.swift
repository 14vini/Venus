//
//  ReadinessSleepArchitectureView.swift
//  Venus
//
//  Created by Kaua on 08/10/26.
//

import SwiftUI

public struct ReadinessSleepArchitectureView: View {
    let sleepDurationHours: Double?
    let restorativeSleepHours: Double?
    let sleepRespiratoryRate: Double?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedFill: CGFloat = 0.0
    @State private var pulseAura: Bool = false
    @State private var selectedStageKey: String? = nil
    
    private var isDark: Bool { colorScheme == .dark }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealColor: Color { Color(hex: "0D9488") }
    
    public init(
        sleepDurationHours: Double?,
        restorativeSleepHours: Double?,
        sleepRespiratoryRate: Double? = nil
    ) {
        self.sleepDurationHours = sleepDurationHours
        self.restorativeSleepHours = restorativeSleepHours
        self.sleepRespiratoryRate = sleepRespiratoryRate
    }
    
    private var totalHours: Double {
        sleepDurationHours ?? 7.8
    }
    
    private var restorativeHours: Double {
        restorativeSleepHours ?? 2.2
    }
    
    private var deepHours: Double {
        restorativeHours * 0.55
    }
    
    private var remHours: Double {
        restorativeHours * 0.45
    }
    
    private var lightHours: Double {
        max(0.5, totalHours - restorativeHours - awakeHours)
    }
    
    private var awakeHours: Double {
        min(0.8, totalHours * 0.08)
    }
    
    private var restorativePercentage: Int {
        guard totalHours > 0 else { return 0 }
        return Int(((restorativeHours / totalHours) * 100).rounded())
    }
    
    private var isRestorativeTargetMet: Bool {
        restorativePercentage >= 20
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header (No emojis)
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isDark ? Color(hex: "A78BFA") : Color(hex: "6366F1"))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill((isDark ? Color(hex: "A78BFA") : Color(hex: "6366F1")).opacity(0.14))
                        )
                        .scaleEffect(pulseAura ? 1.08 : 0.95)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Estágios do Sono")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                        
                        Text("Distribuição & Arquitetura Noturna")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", totalHours))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(isDark ? Color(hex: "A78BFA") : Color(hex: "6366F1"))
                        Text("h dormidas")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(VenusTheme.textTertiary)
                    }
                    
                    Text("\(restorativePercentage)% sono restaurador")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(isRestorativeTargetMet ? (isDark ? mintColor : tealColor) : VenusTheme.accentOrange)
                }
            }
            
            // Extra Large Vertical Sleep Stages Bar Chart (Height: 160px)
            sleepStagesBarChart
                .padding(.vertical, 4)
            
            // Interactive Detail Chip when a stage bar is tapped
            if let selected = selectedStageKey {
                stageDetailBanner(for: selected)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            
            // Clinical Sleep Insight Pill
            HStack(spacing: 8) {
                Image(systemName: isRestorativeTargetMet ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isRestorativeTargetMet ? (isDark ? mintColor : tealColor) : VenusTheme.accentOrange)
                
                Text(isRestorativeTargetMet
                     ? String(format: "%.1fh de sono restaurador (Profundo + REM). Excelente recuperação muscular e cognitiva.", restorativeHours)
                     : "Sono restaurador abaixo da meta (20%). Corpo pode apresentar fadiga neural precoce hoje.")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDark ? Color(hex: "131313") : Color(hex: "DADADA"))
            )
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
            withAnimation(.spring(response: 0.85, dampingFraction: 0.78).delay(0.1)) {
                animatedFill = 1.0
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseAura = true
            }
        }
    }
}

// MARK: - Subviews

private extension ReadinessSleepArchitectureView {
    
    // Large 4-Column Vertical Bar Chart for Sleep Stages (Height: 160px)
    var sleepStagesBarChart: some View {
        let maxDuration = max(1.0, totalHours)
        
        return HStack(alignment: .bottom, spacing: 12) {
            stageBarColumn(
                key: "deep",
                title: "Profundo",
                icon: "waveform.path",
                hours: deepHours,
                percentage: Int((deepHours / totalHours) * 100),
                ratio: deepHours / maxDuration,
                color: isDark ? mintColor : tealColor,
                idealText: "15-25%"
            )
            
            stageBarColumn(
                key: "rem",
                title: "REM",
                icon: "sparkles",
                hours: remHours,
                percentage: Int((remHours / totalHours) * 100),
                ratio: remHours / maxDuration,
                color: Color(hex: "818CF8"),
                idealText: "20-25%"
            )
            
            stageBarColumn(
                key: "light",
                title: "Leve",
                icon: "leaf.fill",
                hours: lightHours,
                percentage: Int((lightHours / totalHours) * 100),
                ratio: lightHours / maxDuration,
                color: Color(hex: "38BDF8"),
                idealText: "45-55%"
            )
            
            stageBarColumn(
                key: "awake",
                title: "Vigília",
                icon: "eye.fill",
                hours: awakeHours,
                percentage: Int((awakeHours / totalHours) * 100),
                ratio: awakeHours / maxDuration,
                color: Color(hex: "F59E0B"),
                idealText: "<10%"
            )
        }
        .frame(height: 160)
    }
    
    func stageBarColumn(
        key: String,
        title: String,
        icon: String,
        hours: Double,
        percentage: Int,
        ratio: Double,
        color: Color,
        idealText: String
    ) -> some View {
        let isSelected = selectedStageKey == key
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedStageKey = isSelected ? nil : key
            }
        } label: {
            VStack(spacing: 7) {
                // Top Values (Hours + Percentage)
                VStack(spacing: 1) {
                    Text(String(format: "%.1fh", hours))
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    
                    Text("\(percentage)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                
                // Thicker & Taller Vertical Bar Capsule (Height: 92px)
                GeometryReader { geo in
                    let height = geo.size.height
                    let barH = max(12, height * CGFloat(min(1.0, ratio * 1.5)) * animatedFill)
                    
                    ZStack(alignment: .bottom) {
                        // Background Track
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.06))
                        
                        // Animated Filled Bar
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.78)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: barH)
                            .shadow(color: isSelected ? color.opacity(0.55) : color.opacity(0.2), radius: 6)
                    }
                }
                .frame(height: 92)
                
                // Stage Label & Icon underneath
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? VenusTheme.text : VenusTheme.textSecondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? color.opacity(0.14) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    func stageDetailBanner(for key: String) -> some View {
        let (title, target, desc, color) = stageInfo(for: key)
        
        return HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    
                    Spacer()
                    
                    Text("Meta: \(target)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                
                Text(desc)
                    .font(.system(size: 11.5, weight: .regular, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? Color(hex: "121212") : Color(hex: "D8D8D8"))
        )
    }
    
    func stageInfo(for key: String) -> (title: String, target: String, desc: String, color: Color) {
        switch key {
        case "deep":
            return (
                "Sono Profundo (Ondas Lentas)",
                "15% a 25%",
                "Essencial para liberação do hormônio do crescimento (GH), reparo das fibras musculares e desintoxicação celular pelo sistema glinfático.",
                isDark ? mintColor : tealColor
            )
        case "rem":
            return (
                "Sono REM (Movimento Ocular Rápido)",
                "20% a 25%",
                "Fase dos sonhos onde ocorre a consolidação da memória, processamento emocional e aprendizado de novas habilidades cognitivas.",
                Color(hex: "818CF8")
            )
        case "light":
            return (
                "Sono Leve",
                "45% a 55%",
                "Estágio de transição metabólica que compõe a maior parte da noite, permitindo a desaceleração gradual da frequência cardíaca.",
                Color(hex: "38BDF8")
            )
        case "awake":
            return (
                "Vigília / Despertares",
                "< 10%",
                "Microdespertares naturais durante a troca de ciclos de sono. Valores abaixo de 10% indicam sono contínuo e de alta eficiência.",
                Color(hex: "F59E0B")
            )
        default:
            return ("", "", "", mintColor)
        }
    }
}

#Preview {
    ReadinessSleepArchitectureView(
        sleepDurationHours: 7.8,
        restorativeSleepHours: 2.2,
        sleepRespiratoryRate: 15.2
    )
    .padding()
    .preferredColorScheme(.dark)
}
