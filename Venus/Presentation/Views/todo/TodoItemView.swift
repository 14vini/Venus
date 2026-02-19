//
//  TodoItemView.swift
//  Venus
//
//  Created by Venus Assistant.
//

import SwiftUI

struct TodoItemView: View {
    let item: TodoItem
    let onToggle: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    if item.isCompleted {
                        Circle()
                            .fill(Color(hex: "FF3D00")) // Orange Theme
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color(hex: "FF3D00").opacity(0.4), radius: 8, x: 0, y: 4)
                    } else {
                        Circle()
                            .strokeBorder(VenusTheme.textSecondary.opacity(0.4), lineWidth: 1.5)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold)) // Slightly bolder
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? VenusTheme.textSecondary.opacity(0.7) : VenusTheme.text)
                    .animation(.spring(), value: item.isCompleted)
                
                // Metadata Row
                HStack(spacing: 12) {
                    if let time = item.time {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(time.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                        }
                        .foregroundColor(VenusTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(VenusTheme.textSecondary.opacity(0.1)) // Subtle tint instead of glass
                        .clipShape(Capsule())
                    }
                    
                    // Example metadata
                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                            .font(.caption2)
                        Text("Prioridade")
                            .font(.caption2)
                    }
                    .foregroundColor(VenusTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(VenusTheme.textSecondary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial) // Blur
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(VenusTheme.surface) // Tint
            }
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            onToggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
}
