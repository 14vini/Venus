//
//  HealthPermissionsStep.swift
//  Venus
//
//  Created by Kaua on 06/10/26.
//

import SwiftUI

struct HealthPermissionsStep: View {
    var onContinue: () -> Void
    
    @State private var isRequesting = false
    private let healthKitService: HealthKitServiceProtocol = DependencyContainer.shared.makeHealthKitService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header (sem subtítulo)
            Text("Sincronização de Saúde & Prontidão")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            
            Text("Para a Venus calcular seu score de prontidão, sono e energia diária com precisão científica:")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(VenusTheme.textSecondary)
                .lineSpacing(3)
            
            // Feature List
            VStack(spacing: 12) {
                metricRow(
                    icon: "heart.fill",
                    color: VenusTheme.accentPink,
                    title: "Variabilidade Cardíaca (HRV)",
                    detail: "Avalia a recuperação do seu sistema nervoso"
                )
                
                metricRow(
                    icon: "moon.fill",
                    color: VenusTheme.accentPurple,
                    title: "Sono & Ritmo Circadiano",
                    detail: "Monitora a qualidade e a restauração do seu descanso"
                )
                
                metricRow(
                    icon: "bolt.fill",
                    color: VenusTheme.accentOrange,
                    title: "Frequência Cardíaca & Energia",
                    detail: "Mede o esforço e a bateria corporal durante o dia"
                )
            }
            .padding(.top, 4)
            
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
            
            Spacer(minLength: 30)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
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
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(VenusTheme.text)
                
                Text(detail)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HealthPermissionsStep(onContinue: {})
        .background(VenusTheme.backgroundGradient)
}
