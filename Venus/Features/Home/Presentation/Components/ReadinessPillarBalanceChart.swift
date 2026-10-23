//
//  ReadinessPillarBalanceChart.swift
//  Venus
//
//  Created by Kaua on 08/10/26.
//

import SwiftUI

public struct ReadinessPillarBalanceChart: View {
    let focusMetric: ReadinessPillarMetric
    let bodyMetric: ReadinessPillarMetric
    let sleepMetric: ReadinessPillarMetric
    var isAnimated: Bool = true
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var internalProgress: Double = 0.0
    @State private var isGlowActive: Bool = false
    @State private var selectedPillarId: String? = nil
    
    private var isDark: Bool { colorScheme == .dark }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealColor: Color { Color(hex: "0D9488") }
    
    public init(
        focusMetric: ReadinessPillarMetric,
        bodyMetric: ReadinessPillarMetric,
        sleepMetric: ReadinessPillarMetric,
        isAnimated: Bool = true
    ) {
        self.focusMetric = focusMetric
        self.bodyMetric = bodyMetric
        self.sleepMetric = sleepMetric
        self.isAnimated = isAnimated
    }
    
    private var synergyScore: Int {
        let avg = (focusMetric.progress + bodyMetric.progress + sleepMetric.progress) / 3.0
        return Int((avg * 100).rounded())
    }
    
    public var body: some View {
        VStack(spacing: 22) {
            // Section Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Harmonia dos Pilares")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    
                    Text("Sinergia integrada entre mente, corpo e sono")
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(synergyScore)% Sinergia")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(isDark ? mintColor : tealColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill((isDark ? mintColor : tealColor).opacity(isDark ? 0.16 : 0.12))
                )
            }
            
            // Grand Center Concentric Rings (Extra Large & Thick Display: 184px, 14px stroke)
            ZStack {
                concentricRingsView
                    .frame(width: 184, height: 184)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            
            // 3 Prominent Pillar Interactive Cards (3-Column Grid)
            HStack(spacing: 10) {
                pillarColumnCard(
                    id: "focus",
                    metric: focusMetric,
                    icon: "brain.head.profile",
                    title: "Foco",
                    subtitle: "Mente & HRV",
                    color: isDark ? Color(hex: "00F5D4") : Color(hex: "0D9488")
                )
                
                pillarColumnCard(
                    id: "body",
                    metric: bodyMetric,
                    icon: "bolt.heart.fill",
                    title: "Corpo",
                    subtitle: "Recuperação",
                    color: isDark ? Color(hex: "34D399") : Color(hex: "059669")
                )
                
                pillarColumnCard(
                    id: "sleep",
                    metric: sleepMetric,
                    icon: "bed.double.fill",
                    title: "Sono",
                    subtitle: "Restaurador",
                    color: isDark ? Color(hex: "A78BFA") : Color(hex: "6366F1")
                )
            }
            
            // Expanded detail card when a pillar is tapped
            if let selected = selectedPillarId {
                pillarDetailCard(for: selected)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(isDark ? Color(hex: "171717") : Color(hex: "E8E8E8"))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(isDark ? 0.07 : 0.4), lineWidth: 0.8)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.78).delay(0.08)) {
                internalProgress = 1.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isGlowActive = true
            }
        }
    }
}

// MARK: - Subviews

private extension ReadinessPillarBalanceChart {
    
    // Grand Concentric Rings (184px Diameter, 14px Stroke)
    var concentricRingsView: some View {
        ZStack {
            // Background Tracks
            Circle()
                .stroke(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06), lineWidth: 14)
                .frame(width: 176, height: 176)
            Circle()
                .stroke(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06), lineWidth: 14)
                .frame(width: 140, height: 140)
            Circle()
                .stroke(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06), lineWidth: 14)
                .frame(width: 104, height: 104)
            
            // Outer Ring - Focus (Mint / Cyan)
            Circle()
                .trim(from: 0, to: CGFloat(focusMetric.progress * internalProgress))
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "00F5D4"), Color(hex: "0284C7")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 176, height: 176)
                .shadow(color: (isDark ? Color(hex: "00F5D4") : Color(hex: "0D9488")).opacity(isGlowActive ? 0.38 : 0.15), radius: 10)
            
            // Middle Ring - Body (Emerald)
            Circle()
                .trim(from: 0, to: CGFloat(bodyMetric.progress * internalProgress))
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "34D399"), Color(hex: "10B981")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 140, height: 140)
            
            // Inner Ring - Sleep (Purple / Indigo)
            Circle()
                .trim(from: 0, to: CGFloat(sleepMetric.progress * internalProgress))
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "A78BFA"), Color(hex: "6366F1")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 104, height: 104)
            
            // Center Large Synergy Value
            VStack(spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(synergyScore)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    Text("%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(isDark ? mintColor : tealColor)
                }
                
                Text("Harmonia")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.textTertiary)
                    .textCase(.uppercase)
            }
        }
    }
    
    // 3-Column Pillar Cards
    func pillarColumnCard(
        id: String,
        metric: ReadinessPillarMetric,
        icon: String,
        title: String,
        subtitle: String,
        color: Color
    ) -> some View {
        let isSelected = selectedPillarId == id
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedPillarId = isSelected ? nil : id
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Top Icon + Value
                HStack(alignment: .center) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(color.opacity(0.14))
                        )
                    
                    Spacer()
                    
                    Text("\(metric.percentageInt)%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textTertiary)
                }
                
                // Thicker Progress Bar (6.5px)
                GeometryReader { geo in
                    let width = geo.size.width
                    let fillW = max(6, width * CGFloat(metric.progress * internalProgress))
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06))
                        
                        Capsule()
                            .fill(color)
                            .frame(width: fillW)
                    }
                }
                .frame(height: 6.5)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? color.opacity(0.14) : (isDark ? Color(hex: "131313") : Color(hex: "DADADA")))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    func pillarDetailCard(for id: String) -> some View {
        let (title, desc, status, color) = pillarData(for: id)
        
        return HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    
                    Spacer()
                    
                    Text(status)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                
                Text(desc)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDark ? Color(hex: "121212") : Color(hex: "D8D8D8"))
        )
    }
    
    func pillarData(for id: String) -> (title: String, desc: String, status: String, color: Color) {
        switch id {
        case "focus":
            return (
                "Foco Mental & HRV",
                "Calculado com base na estabilidade do HRV noturno e no seu check-in subjetivo de clareza.",
                focusMetric.progress >= 0.8 ? "Ótimo" : "Normal",
                isDark ? Color(hex: "00F5D4") : Color(hex: "0D9488")
            )
        case "body":
            return (
                "Recuperação Física",
                "Equilíbrio entre a queda cardíaca noturna (RHR dip) e a demanda de treino de ontem.",
                bodyMetric.progress >= 0.8 ? "Recuperado" : "Em repouso",
                isDark ? Color(hex: "34D399") : Color(hex: "059669")
            )
        case "sleep":
            return (
                "Qualidade do Sono",
                "Combina o tempo total em sono profundo/REM com a regularidade dos seus horários de repouso.",
                sleepMetric.progress >= 0.8 ? "Restaurador" : "Adequado",
                isDark ? Color(hex: "A78BFA") : Color(hex: "6366F1")
            )
        default:
            return ("", "", "", mintColor)
        }
    }
}

#Preview {
    ReadinessPillarBalanceChart(
        focusMetric: ReadinessPillarMetric(
            title: "Foco",
            iconName: "scope",
            isCompleted: true,
            detail: "Carga mental equilibrada",
            score: 8.4
        ),
        bodyMetric: ReadinessPillarMetric(
            title: "Corpo",
            iconName: "atom",
            isCompleted: true,
            detail: "Recuperação física estável",
            score: 8.0
        ),
        sleepMetric: ReadinessPillarMetric(
            title: "Sono",
            iconName: "bed.double.fill",
            isCompleted: true,
            detail: "Descanso restaurador",
            score: 7.8
        )
    )
    .padding()
    .preferredColorScheme(.dark)
}
