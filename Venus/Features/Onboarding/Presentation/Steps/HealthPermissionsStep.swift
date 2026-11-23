//
//  HealthPermissionsStep.swift
//  Venus
//
//  Created by Kaua on 06/10/26.
//

import SwiftUI

struct HealthPermissionsStep: View {
    var onContinue: () -> Void
    
    @State private var appeared = false
    private let healthKitService: HealthKitServiceProtocol = DependencyContainer.shared.makeHealthKitService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header (sem subtítulo)
            Text("Sincronização de Saúde & Prontidão")
                .font(.system(size: 26, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
                .contentTransition(.opacity)
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: appeared)
            
            Text("Para cuidar do seu score de prontidão, sono e energia:")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(VenusTheme.textSecondary)
                .lineSpacing(3)
                .contentTransition(.opacity)
                .animation(.spring(response: 0.42, dampingFraction: 0.8).delay(0.08), value: appeared)
            
            // Feature List
            VStack(spacing: 12) {
                metricRow(
                    icon: "heart.fill",
                    color: VenusTheme.accentPink,
                    title: "Variabilidade Cardíaca (HRV)",
                    detail: "Recuperação do sistema nervoso"
                )
                
                metricRow(
                    icon: "moon.fill",
                    color: VenusTheme.accentPurple,
                    title: "Sono & Ritmo Circadiano",
                    detail: "Qualidade do seu descanso"
                )
                
                metricRow(
                    icon: "bolt.fill",
                    color: VenusTheme.accentOrange,
                    title: "Frequência Cardíaca & Energia",
                    detail: "Esforço e energia ao longo do dia"
                )
            }
            .padding(.top, 4)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.14), value: appeared)
            
            // Privacy Note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(VenusTheme.primary)
                
                Text("Seus dados de saúde nunca saem do seu dispositivo sem sua autorização.")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
            }
            .padding(.top, 8)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.42, dampingFraction: 0.8).delay(0.2), value: appeared)
            
            Spacer(minLength: 30)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .accessibilityElement(children: .contain)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
    
    private func metricRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusTheme.text)
                    .contentTransition(.opacity)
                
                Text(detail)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .contentTransition(.opacity)
            }
            
            Spacer()
        }
        .padding(12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    HealthPermissionsStep(onContinue: {})
        .background(VenusTheme.backgroundGradient)
}
