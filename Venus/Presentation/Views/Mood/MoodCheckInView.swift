//
//  MoodCheckInView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct MoodCheckInView: View {
    @StateObject var viewModel: MoodCheckInViewModel
    var onCompleted: ((MoodType) -> Void)?
    @Environment(\.dismiss) var dismiss
    
    // Grid layout for moods
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(VenusTheme.textSecondary)
                            .padding(8)
                            .background(VenusTheme.surface)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 40) {
                        // Title
                        VStack(spacing: 12) {
                            Text("Como você está hoje?")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(VenusTheme.text)
                            
                            Text("Escolha o que melhor descreve seu momento.")
                                .font(.body)
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                        
                        // Mood Grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(MoodType.allCases, id: \.self) { mood in
                                MoodOptionCircle(
                                    mood: mood,
                                    isSelected: viewModel.selectedMood == mood,
                                    onTap: { viewModel.selectMood(mood) }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Note Section (appears if selected)
                        if viewModel.selectedMood != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quer adicionar uma nota? (Opcional)")
                                    .font(.subheadline)
                                    .foregroundColor(VenusTheme.text)
                                
                                TextField("Ex: Tive uma reunião difícil...", text: $viewModel.note)
                                    .padding()
                                    .background(VenusTheme.surface)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
                
                // Save Button
                if viewModel.selectedMood != nil {
                    Button(action: { viewModel.saveCheckIn() }) {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Salvar Check-in")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color(hex: "FF3D00").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(viewModel.isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .onChange(of: viewModel.savedSuccess) { _, success in
            if success, let mood = viewModel.selectedMood {
                onCompleted?(mood)
                dismiss()
            }
        }
    }
}

struct MoodOptionCircle: View {
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                
                Text(mood.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : VenusTheme.text)
            }
            .frame(width: 100, height: 120)
            .background(
                ZStack {
                    if isSelected {
                        Color(hex: mood.colorHex)
                    } else {
                        VenusTheme.surface
                    }
                }
            )
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.clear : VenusTheme.chipBorder, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? Color(hex: mood.colorHex).opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}
