//
//  ReadinessHeartRateDipView.swift
//  Venus
//
//  Created by Kaua on 08/10/26.
//

import SwiftUI

public struct ReadinessHeartRateDipView: View {
    let restingHR: Double?
    let sleepingHR: Double?
    let hrDipPercentage: Double?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedFill: CGFloat = 0.0
    @State private var pulseWave: Bool = false
    
    private var isDark: Bool { colorScheme == .dark }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealColor: Color { Color(hex: "0D9488") }
    
    public init(
        restingHR: Double?,
        sleepingHR: Double?,
        hrDipPercentage: Double?
    ) {
        self.restingHR = restingHR
        self.sleepingHR = sleepingHR
        self.hrDipPercentage = hrDipPercentage
    }
    
    private var rhrValue: Double {
        restingHR ?? 62.0
    }
    
    private var sleepHRValue: Double {
        if let s = sleepingHR { return s }
        if let dip = hrDipPercentage {
            return rhrValue * (1.0 - (dip / 100.0))
        }
        return rhrValue * 0.87
    }
    
    private var calculatedDip: Double {
        if let dip = hrDipPercentage { return dip }
        guard rhrValue > 0 else { return 0 }
        return ((rhrValue - sleepHRValue) / rhrValue) * 100.0
    }
    
    private var isDipHealthy: Bool {
        calculatedDip >= 10.0
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isDark ? Color(hex: "38BDF8") : Color(hex: "0284C7"))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill((isDark ? Color(hex: "38BDF8") : Color(hex: "0284C7")).opacity(0.14))
                        )
                        .scaleEffect(pulseWave ? 1.08 : 0.95)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("FC Repouso & Queda Noturna")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                        
                        Text("Descompressão Cardiovascular Noturna")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    if let _ = restingHR {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(Int(rhrValue))")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(isDark ? Color(hex: "38BDF8") : Color(hex: "0284C7"))
                            Text("bpm")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(VenusTheme.textTertiary)
                        }
                    } else {
                        Text("Sem dados")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(VenusTheme.textTertiary)
                    }
                    
                    Text(String(format: "-%.1f%% de queda noturna", calculatedDip))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(isDipHealthy ? (isDark ? mintColor : tealColor) : VenusTheme.accentOrange)
                }
            }
            
            // Extra Large Day vs Night Heart Rate Drop Visualizer (Height: 96px)
            dayNightComparisonView
                .padding(.vertical, 2)
            
            // Dip Progress Bar & Clinical Tag
            dipStatusBar
            
            // Explanatory footnote
            Text(dipExplanationText)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
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
            withAnimation(.spring(response: 0.8, dampingFraction: 0.78).delay(0.14)) {
                animatedFill = 1.0
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseWave = true
            }
        }
    }
}

// MARK: - Subviews

private extension ReadinessHeartRateDipView {
    var dayNightComparisonView: some View {
        HStack(spacing: 12) {
            // Day RHR Box
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text("Diurna")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
                
                Text("\(Int(rhrValue))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                
                Text("bpm repouso")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(VenusTheme.textTertiary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .frame(maxWidth: 104)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isDark ? Color(hex: "131313") : Color(hex: "DADADA"))
            )
            
            // Connecting Descent Slope (Height: 90px, Thicker: 3.8px)
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                
                let startPoint = CGPoint(x: 8, y: height * 0.18)
                let endPoint = CGPoint(x: width - 8, y: height * 0.82)
                let midX = width / 2.0
                
                ZStack {
                    // Soft slope gradient area
                    Path { path in
                        path.move(to: startPoint)
                        path.addCurve(
                            to: endPoint,
                            control1: CGPoint(x: midX, y: startPoint.y),
                            control2: CGPoint(x: midX, y: endPoint.y)
                        )
                        path.addLine(to: CGPoint(x: endPoint.x, y: height))
                        path.addLine(to: CGPoint(x: startPoint.x, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                (isDark ? mintColor : tealColor).opacity(isDark ? 0.30 : 0.16),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Thicker Curve line (3.8px)
                    Path { path in
                        path.move(to: startPoint)
                        path.addCurve(
                            to: endPoint,
                            control1: CGPoint(x: midX, y: startPoint.y),
                            control2: CGPoint(x: midX, y: endPoint.y)
                        )
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "F59E0B"), isDark ? mintColor : tealColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3.8, lineCap: .round)
                    )
                    
                    // Animated Downward Badge
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 9.5, weight: .bold))
                        Text(String(format: "-%.1f%%", calculatedDip))
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(isDark ? mintColor : tealColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(
                        Capsule()
                            .fill(isDark ? Color.black.opacity(0.9) : Color.white.opacity(0.95))
                            .shadow(color: (isDark ? mintColor : tealColor).opacity(0.4), radius: 5)
                    )
                    .position(x: midX, y: height * 0.48)
                    .scaleEffect(animatedFill)
                }
            }
            .frame(height: 90)
            
            // Night Sleep HR Box
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isDark ? mintColor : tealColor)
                    Text("Noite")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
                
                Text("\(Int(sleepHRValue))")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(isDark ? mintColor : tealColor)
                
                Text("bpm sono")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(VenusTheme.textTertiary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .frame(maxWidth: 104)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isDark ? Color(hex: "131313") : Color(hex: "DADADA"))
            )
        }
    }
    
    var dipStatusBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                let targetX = (10.0 / 25.0) * width
                let currentProgress = min(1.0, max(0.0, calculatedDip / 25.0))
                let currentW = max(10, width * CGFloat(currentProgress * animatedFill))
                
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.06))
                    
                    // Filled track
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "F59E0B"), isDark ? mintColor : tealColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: currentW)
                    
                    // 10% clinical threshold marker
                    Rectangle()
                        .fill(VenusTheme.text.opacity(0.75))
                        .frame(width: 2.5, height: 18)
                        .position(x: targetX, y: 8)
                }
            }
            .frame(height: 16)
            
            HStack {
                Text("0% (Sem queda)")
                Spacer()
                Text("Meta Clínica (≥10%)")
                    .foregroundColor(isDark ? mintColor : tealColor)
                Spacer()
                Text("25%+ (Profundo)")
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(VenusTheme.textTertiary)
        }
    }
    
    var dipExplanationText: String {
        if calculatedDip >= 15.0 {
            return "Excelente relaxamento cardiovascular. Uma queda noturna de \(String(format: "%.1f", calculatedDip))% sinaliza descanso profundo das artérias e eficiente recuperação miocárdica."
        } else if calculatedDip >= 10.0 {
            return "Queda noturna saudável de \(String(format: "%.1f", calculatedDip))% (acima da meta clínica de 10%). O coração descansou adequadamente durante a noite."
        } else {
            return "Queda noturna atenuada (\(String(format: "%.1f", calculatedDip))%). Digestão tardia, treinos noturnos ou estresse podem manter o coração acelerado durante o sono."
        }
    }
}

#Preview {
    ReadinessHeartRateDipView(
        restingHR: 62.0,
        sleepingHR: 52.0,
        hrDipPercentage: 16.1
    )
    .padding()
    .preferredColorScheme(.dark)
}
