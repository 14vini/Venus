//
//  ReadinessStrainGaugeView.swift
//  Venus
//
//  Created by Kaua on 08/10/26.
//

import SwiftUI

public struct ReadinessStrainGaugeView: View {
    let yesterdayActiveEnergy: Double?
    let yesterdayWorkoutMinutes: Double?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedFill: CGFloat = 0.0
    
    private var isDark: Bool { colorScheme == .dark }
    private var mintColor: Color { Color(hex: "00F5D4") }
    private var tealColor: Color { Color(hex: "0D9488") }
    
    public init(
        yesterdayActiveEnergy: Double?,
        yesterdayWorkoutMinutes: Double?
    ) {
        self.yesterdayActiveEnergy = yesterdayActiveEnergy
        self.yesterdayWorkoutMinutes = yesterdayWorkoutMinutes
    }
    
    private var activeCalories: Double {
        yesterdayActiveEnergy ?? 400.0
    }
    
    private var workoutMins: Double {
        yesterdayWorkoutMinutes ?? 35.0
    }
    
    private var strainLevel: (title: String, color: Color, icon: String, description: String) {
        if activeCalories > 750 {
            return (
                "Carga Elevada",
                VenusTheme.accentOrange,
                "flame.fill",
                "Alto consumo muscular ontem. O corpo demanda descanso ativo ou regeneração hoje."
            )
        } else if activeCalories >= 300 {
            return (
                "Estímulo Ideal",
                isDark ? mintColor : tealColor,
                "figure.run",
                "Carga física equilibrada ontem, estimulando boa circulação sem exaustão do sistema nervoso."
            )
        } else {
            return (
                "Dia Regenerativo",
                isDark ? Color(hex: "38BDF8") : Color(hex: "0284C7"),
                "figure.walk",
                "Baixo impacto físico registrado ontem. Bateria preservada para esforço hoje."
            )
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "F97316"))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color(hex: "F97316").opacity(0.14))
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Carga Física & Gasto Ativo")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                        
                        Text("Desgaste Neuromuscular de Ontem")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    if let energy = yesterdayActiveEnergy {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(Int(energy))")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "F97316"))
                            Text("kcal")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(VenusTheme.textTertiary)
                        }
                    } else {
                        Text("Sem treinos")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(VenusTheme.textTertiary)
                    }
                    
                    if let mins = yesterdayWorkoutMinutes, mins > 0 {
                        Text("\(Int(mins)) min de treino")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
            }
            
            // Extra Large & Thick Strain Progress Meter (Height: 20px)
            strainMeterBar
                .padding(.vertical, 2)
            
            // Status Chip & Workouts
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: strainLevel.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(strainLevel.title)
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                }
                .foregroundColor(strainLevel.color)
                .padding(.horizontal, 11)
                .padding(.vertical, 5.5)
                .background(
                    Capsule()
                        .fill(strainLevel.color.opacity(0.14))
                )
                
                Spacer()
                
                if let mins = yesterdayWorkoutMinutes, mins > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 11))
                        Text("\(Int(mins)) min ativos ontem")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(VenusTheme.textSecondary)
                }
            }
            
            // Explanatory Text
            Text(strainLevel.description)
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
            withAnimation(.spring(response: 0.8, dampingFraction: 0.78).delay(0.16)) {
                animatedFill = 1.0
            }
        }
    }
}

// MARK: - Subviews

private extension ReadinessStrainGaugeView {
    var strainMeterBar: some View {
        VStack(spacing: 7) {
            GeometryReader { geo in
                let width = geo.size.width
                let maxCal: Double = 900.0
                let ratio = min(1.0, max(0.05, activeCalories / maxCal))
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.07))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FBBF24"),
                                    Color(hex: "F97316"),
                                    Color(hex: "EF4444")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(18, width * CGFloat(ratio * animatedFill)))
                        .shadow(color: Color(hex: "F97316").opacity(0.45), radius: 6)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("0 kcal (Leve)")
                Spacer()
                Text("300-600 kcal (Ideal)")
                    .foregroundColor(isDark ? mintColor : tealColor)
                Spacer()
                Text("900+ kcal (Alto)")
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(VenusTheme.textTertiary)
        }
    }
}

#Preview {
    ReadinessStrainGaugeView(
        yesterdayActiveEnergy: 450.0,
        yesterdayWorkoutMinutes: 40.0
    )
    .padding()
    .preferredColorScheme(.dark)
}
