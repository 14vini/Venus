//
//  AddTodoView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct AddTodoView: View {
    let onAdd: (String, Date?, TodoType) -> Void
    
    @State private var title = ""
    @State private var selectedTime = Date()
    @State private var hasTime = false
    @State private var selectedType = TodoType.task
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private var isAddDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.accentOrange,
                secondaryAccent: VenusTheme.ambientRose,
                tertiaryAccent: VenusTheme.ambientCool
            )

            VStack(spacing: 24) {
                
                Text("Nova Tarefa")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                
                VStack(spacing: 20) {
                    // Title Input
                    TextField("O que você precisa fazer?", text: $title)
                        .font(.system(size: 18))
                        .padding()
                        .glassEffect(.clear.interactive(true))
                    
                    // Toggle Time
                    HStack {
                        Toggle("Definir horário", isOn: $hasTime)
                            .tint(VenusTheme.accentOrange)
                            .foregroundColor(VenusTheme.text)
                    }
                    .padding()
                    .glassEffect(.clear.interactive(true), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // Date Picker
                    if hasTime {
                        DatePicker("Horário", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .padding()
                            .glassEffect(.clear.interactive(true), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Type Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Categoria")
                            .font(.caption)
                            .foregroundColor(VenusTheme.textSecondary)
                            .padding(.leading, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(TodoType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedType = type
                                        }
                                    }) {
                                        Text(type.rawValue.capitalized)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 14)
                                            .background(
                                                Capsule()
                                                    .fill(selectedType == type ? VenusTheme.accentOrange : Color.clear)
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(selectedType == type ? Color.clear : VenusTheme.chipBorder, lineWidth: 1)
                                                    )
                                            )
                                            .foregroundColor(selectedType == type ? .white : VenusTheme.text)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Add Button
                Button(action: {
                    let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    onAdd(normalizedTitle, hasTime ? selectedTime : nil, selectedType)
                    dismiss()
                }) {
                    Text("Adicionar Tarefa")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            VenusTheme.orangeTopGradient
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: VenusTheme.accentOrange.opacity(0.38), radius: 10, x: 0, y: 5)
                }
                .disabled(isAddDisabled)
                .opacity(isAddDisabled ? 0.6 : 1)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}
