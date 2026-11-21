//
//  MyDayPrioritiesView.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI

struct MyDayPrioritiesView: View {
    let priorities: [PlannedBlock]
    let onComplete: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Prioridades de Hoje", systemImage: "flag.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                
                Spacer()
                
                Text("Máximo 3")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
            }
            
            VStack(spacing: 8) {
                ForEach(Array(priorities.prefix(3).enumerated()), id: \.element.id) { index, block in
                    HStack(spacing: 12) {
                        // Number
                        ZStack {
                            Circle()
                                .fill(block.category.color.opacity(0.18))
                                .frame(width: 26, height: 26)
                            
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(block.category.color)
                        }
                        
                        // Title & Time
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(block.status == .completed ? VenusTheme.textSecondary : VenusTheme.text)
                                .strikethrough(block.status == .completed)
                                .lineLimit(1)
                            
                            Text(block.formattedTimeRange)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Checkbox
                        Button {
                            onComplete(block.id)
                        } label: {
                            Image(systemName: block.status == .completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(block.status == .completed ? .green : VenusTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(VenusTheme.cardSurface)
                    .cornerRadius(14)
                }
            }
        }
    }
}
