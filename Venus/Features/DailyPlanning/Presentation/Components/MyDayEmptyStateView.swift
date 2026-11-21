//
//  MyDayEmptyStateView.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI

struct MyDayEmptyStateView: View {
    let onPlanWithVenus: () -> Void
    let onManualCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                VenusTheme.primary.opacity(0.25),
                                VenusTheme.accentPurple.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "sparkles.square.filled.on.square")
                    .font(.system(size: 46))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [VenusTheme.primary, VenusTheme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 16)
            
            VStack(spacing: 8) {
                Text("Nenhum plano para hoje")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                
                Text("Você pode pedir para a Venus montar sua rotina ou criá-la manualmente.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            VStack(spacing: 12) {
                // Button 1: Plan with Venus
                Button {
                    onPlanWithVenus()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                        Text("Planejar meu dia com a Venus")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [VenusTheme.primary, VenusTheme.accentPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: VenusTheme.primary.opacity(0.35), radius: 10, x: 0, y: 5)
                    )
                }
                .buttonStyle(.plain)
                
                // Button 2: Manual creation
                Button {
                    onManualCreate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Criar rotina na mão")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(VenusTheme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .fill(VenusTheme.surface)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(VenusTheme.cardSurface)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
