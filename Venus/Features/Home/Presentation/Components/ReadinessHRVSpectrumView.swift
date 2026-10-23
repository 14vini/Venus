//
//  ReadinessHRVSpectrumView.swift
//  Venus
//
//  Created by Kaua on 08/10/26.
//

import SwiftUI

public struct ReadinessHRVSpectrumView: View {
    let currentHRV: Double?
    let baselineAverage: Double?
    let ratio: Double?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedMarker: Bool = false
    @State private var pulseAura: Bool = false
    
    private var isDark: Bool { colorScheme == .dark }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealColor: Color { Color(hex: "0D9488") }
    
    public init(
        currentHRV: Double?,
        baselineAverage: Double?,
        ratio: Double?
    ) {
        self.currentHRV = currentHRV
        self.baselineAverage = baselineAverage
        self.ratio = ratio
    }
    
    private var hrvValue: Double {
        currentHRV ?? 55.0
    }
    
    private var baseValue: Double {
        baselineAverage ?? 50.0
    }
    
    private var deltaPercentage: Int {
        if let ratio = ratio {
            return Int(((ratio - 1.0) * 100).rounded())
        }
        if let current = currentHRV, let base = baselineAverage, base > 0 {
            return Int((((current - base) / base) * 100).rounded())
        }
        return 0
    }
    
    private var autonomicStatus: (title: String, color: Color, icon: String) {
        let delta = deltaPercentage
        if delta >= 8 {
            return ("Supercompensação", isDark ? Color(hex: "00F5D4") : Color(hex: "0D9488"), "bolt.fill")
        } else if delta >= -8 {
            return ("Equilíbrio Basal Ideal", isDark ? Color(hex: "34D399") : Color(hex: "10B981"), "checkmark.circle.fill")
        } else {
            return ("Fadiga Autonômica", VenusTheme.accentOrange, "exclamationmark.triangle.fill")
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isDark ? mintColor : tealColor)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill((isDark ? mintColor : tealColor).opacity(0.14))
                        )
                        .scaleEffect(pulseAura ? 1.08 : 0.95)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Variabilidade Cardíaca (HRV)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                        
                        Text("Tônus Parassimpático & Prontidão Neural")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    if let current = currentHRV {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(Int(current))")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(isDark ? mintColor : tealColor)
                            Text("ms")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(VenusTheme.textTertiary)
                        }
                    } else {
                        Text("Sem dados")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(VenusTheme.textTertiary)
                    }
                    
                    let sign = deltaPercentage >= 0 ? "+" : ""
                    Text("\(sign)\(deltaPercentage)% vs média 7d")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(deltaPercentage >= -8 ? (isDark ? mintColor : tealColor) : VenusTheme.accentOrange)
                }
            }
            
            // Extra Large & Thick Bell Curve Distribution Chart (Height: 130px)
            hrvWaveDistributionChart
                .frame(height: 130)
                .padding(.vertical, 2)
            
            // Zone Breakdown Legend
            HStack(spacing: 12) {
                zoneLegendItem(color: VenusTheme.accentOrange, label: "Fadiga (<45ms)")
                zoneLegendItem(color: isDark ? mintColor : tealColor, label: "Basal (\(Int(baseValue))ms)")
                zoneLegendItem(color: Color(hex: "38BDF8"), label: "Pico (>65ms)")
            }
            
            // Text Insight
            Text(hrvExplanationText)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
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
            withAnimation(.spring(response: 0.85, dampingFraction: 0.75).delay(0.1)) {
                animatedMarker = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseAura = true
            }
        }
    }
}

// MARK: - Subviews

private extension ReadinessHRVSpectrumView {
    var hrvWaveDistributionChart: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            let minScale = baseValue * 0.40
            let maxScale = baseValue * 1.65
            let range = max(1.0, maxScale - minScale)
            
            let normalizedPos = min(0.95, max(0.05, (hrvValue - minScale) / range))
            let markerX = normalizedPos * width
            let markerY = height * 0.20
            
            let baseNormalized = min(0.95, max(0.05, (baseValue - minScale) / range))
            let baseX = baseNormalized * width
            
            ZStack(alignment: .bottom) {
                // Background Zone Gradient bands
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(VenusTheme.accentOrange.opacity(isDark ? 0.08 : 0.05))
                        .frame(width: width * 0.32)
                    Rectangle()
                        .fill((isDark ? mintColor : tealColor).opacity(isDark ? 0.10 : 0.06))
                        .frame(width: width * 0.38)
                    Rectangle()
                        .fill(Color(hex: "38BDF8").opacity(isDark ? 0.08 : 0.05))
                        .frame(maxWidth: .infinity)
                }
                .cornerRadius(14)
                
                // Bell Distribution Curve Path
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height - 12))
                    path.addCurve(
                        to: CGPoint(x: baseX, y: 16),
                        control1: CGPoint(x: width * 0.2, y: height - 14),
                        control2: CGPoint(x: baseX - 35, y: 16)
                    )
                    path.addCurve(
                        to: CGPoint(x: width, y: height - 12),
                        control1: CGPoint(x: baseX + 35, y: 16),
                        control2: CGPoint(x: width * 0.8, y: height - 14)
                    )
                    path.addLine(to: CGPoint(x: width, y: height - 12))
                    path.addLine(to: CGPoint(x: 0, y: height - 12))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            (isDark ? mintColor : tealColor).opacity(isDark ? 0.34 : 0.22),
                            (isDark ? mintColor : tealColor).opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Thicker Curve Stroke Line (3.8px)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height - 12))
                    path.addCurve(
                        to: CGPoint(x: baseX, y: 16),
                        control1: CGPoint(x: width * 0.2, y: height - 14),
                        control2: CGPoint(x: baseX - 35, y: 16)
                    )
                    path.addCurve(
                        to: CGPoint(x: width, y: height - 12),
                        control1: CGPoint(x: baseX + 35, y: 16),
                        control2: CGPoint(x: width * 0.8, y: height - 14)
                    )
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            VenusTheme.accentOrange,
                            isDark ? mintColor : tealColor,
                            Color(hex: "38BDF8")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3.8, lineCap: .round)
                )
                
                // Baseline Target Line (dashed)
                VStack(spacing: 2) {
                    Text("Basal")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.textTertiary)
                    
                    Path { path in
                        path.move(to: CGPoint(x: baseX, y: 18))
                        path.addLine(to: CGPoint(x: baseX, y: height - 12))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundColor(VenusTheme.textTertiary.opacity(0.7))
                }
                
                // Interactive / Animated Current HRV Marker Pin
                if animatedMarker {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isDark ? Color.black : Color.white)
                                .frame(width: 5.5, height: 5.5)
                            Text("\(Int(hrvValue)) ms")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .foregroundColor(isDark ? Color.black : Color.white)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule()
                                .fill(isDark ? mintColor : tealColor)
                                .shadow(color: (isDark ? mintColor : tealColor).opacity(0.55), radius: 6)
                        )
                        
                        // Pin stem
                        Circle()
                            .fill(isDark ? mintColor : tealColor)
                            .frame(width: 6.5, height: 6.5)
                    }
                    .position(x: markerX, y: markerY + 4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    func zoneLegendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
        }
    }
    
    var hrvExplanationText: String {
        let status = autonomicStatus
        if deltaPercentage >= 8 {
            return "\(status.title): Seu sistema nervoso autônomo está com forte predominância parassimpática (+ \(deltaPercentage)% acima da média). Corpo pronto para desafios intensos."
        } else if deltaPercentage >= -8 {
            return "\(status.title): HRV perfeitamente alinhado com seu padrão fisiológico habitual dos últimos 7 dias. Resposta balanceada e estável."
        } else {
            return "\(status.title): HRV \(abs(deltaPercentage))% abaixo da média basal de 7 dias, sugerindo fadiga acumulada ou estresse fisiológico. Priorize sono e recuperação hoje."
        }
    }
}

#Preview {
    ReadinessHRVSpectrumView(
        currentHRV: 58.0,
        baselineAverage: 52.0,
        ratio: 1.11
    )
    .padding()
    .preferredColorScheme(.dark)
}
