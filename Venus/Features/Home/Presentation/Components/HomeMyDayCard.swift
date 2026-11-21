//
//  HomeMyDayCard.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI

struct HomeMyDayCard: View {
    let plan: DailyPlan?
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [VenusTheme.primary.opacity(0.2), VenusTheme.accentPurple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [VenusTheme.primary, VenusTheme.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("MEU DIA")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(VenusTheme.primary)
                        
                        Spacer()
                        
                        if let plan = plan, !plan.blocks.isEmpty {
                            Text("\(plan.completedBlocksCount)/\(plan.totalBlocksCount)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                    }
                    
                    if let plan = plan, !plan.blocks.isEmpty {
                        let activeBlock = plan.blocks.first(where: { $0.status == .inProgress }) ??
                                          plan.blocks.first(where: { $0.status == .planned && $0.endTime > Date() })
                        
                        if let current = activeBlock {
                            Text(current.title)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(VenusTheme.text)
                                .lineLimit(1)
                            
                            Text("\(current.formattedTimeRange) • \(current.category.displayName)")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        } else {
                            Text("Todos os blocos de hoje foram concluídos! ✨")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.text)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Monte sua rotina sem culpa")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                        
                        Text("Conte à Venus para criar um plano realista.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(VenusTheme.textSecondary.opacity(0.6))
            }
            .padding(16)
            .background(VenusTheme.cardSurface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
