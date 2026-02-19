//
//  GratitudeView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import Combine

struct GratitudeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GratitudeViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "E9D5FF"),
                    Color(hex: "FDE68A"),
                    Color(hex: "FBCFE8"),
                    Color(hex: "DDD6FE")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating hearts animation
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .font(.system(size: CGFloat.random(in: 12...24)))
                    .foregroundColor(VenusTheme.accentPink.opacity(0.3))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800)
                    )
                    .scaleEffect(viewModel.heartAnimation ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: viewModel.heartAnimation
                    )
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.7))
                            )
                    }
                    
                    Spacer()
                    
                    Text("Gratidão")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black.opacity(0.8))
                    
                    Spacer()
                    
                    Button(action: { viewModel.showHistory.toggle() }) {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.7))
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Prompt
                        VStack(spacing: 16) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(VenusTheme.accentPink)
                                .scaleEffect(viewModel.heartAnimation ? 1.1 : 0.9)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: viewModel.heartAnimation)
                            
                            Text("Pelo que você é grato hoje?")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            Text("Escreva três coisas que trouxeram alegria ao seu dia")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        
                        // Gratitude entries
                        VStack(spacing: 20) {
                            ForEach(0..<3, id: \.self) { index in
                                GratitudeEntryCard(
                                    number: index + 1,
                                    text: Binding(
                                        get: { viewModel.gratitudeEntries[index] },
                                        set: { viewModel.gratitudeEntries[index] = $0 }
                                    ),
                                    placeholder: viewModel.placeholders[index]
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Save button
                        Button(action: viewModel.saveGratitude) {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("Salvar Momento")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [VenusTheme.accentPink, VenusTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: VenusTheme.accentPink.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(!viewModel.canSave)
                        .opacity(viewModel.canSave ? 1.0 : 0.6)
                        .padding(.horizontal, 24)
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack(spacing: 4) {
                                Text("\(viewModel.totalEntries)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black.opacity(0.8))
                                Text("Momentos")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            VStack(spacing: 4) {
                                Text("\(viewModel.streakDays)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black.opacity(0.8))
                                Text("Dias Seguidos")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.6))
                        )
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            viewModel.startAnimations()
        }
        .alert("Momento Salvo!", isPresented: $viewModel.showSavedAlert) {
            Button("OK") { }
        } message: {
            Text("Seu momento de gratidão foi salvo com sucesso!")
        }
        .sheet(isPresented: $viewModel.showHistory) {
            GratitudeHistoryView(viewModel: viewModel)
        }
    }
}

struct GratitudeEntryCard: View {
    let number: Int
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(VenusTheme.accentPink.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("\(number)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(VenusTheme.accentPink)
                    )
                
                Text("Gratidão \(number)")
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
            }
            
            TextField(placeholder, text: $text, axis: .vertical)
                .focused($isFocused)
                .font(.body)
                .foregroundColor(.black.opacity(0.8))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFocused ? VenusTheme.accentPink : .clear, lineWidth: 2)
                        )
                )
                .lineLimit(3...6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.8), lineWidth: 1)
                )
        )
    }
}

@MainActor
class GratitudeViewModel: ObservableObject {
    @Published var gratitudeEntries = ["", "", ""]
    @Published var heartAnimation = false
    @Published var showSavedAlert = false
    @Published var showHistory = false
    @Published var totalEntries = 0
    @Published var streakDays = 0
    
    let placeholders = [
        "Ex: O sorriso de uma pessoa querida...",
        "Ex: Um momento de paz no meu dia...",
        "Ex: Uma pequena conquista pessoal..."
    ]
    
    var canSave: Bool {
        gratitudeEntries.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    init() {
        loadStats()
    }
    
    func startAnimations() {
        heartAnimation = true
    }
    
    func saveGratitude() {
        let entry = GratitudeEntry(
            id: UUID(),
            entries: gratitudeEntries.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            date: Date()
        )
        
        var savedEntries = loadGratitudeEntries()
        savedEntries.append(entry)
        
        if let encoded = try? JSONEncoder().encode(savedEntries) {
            UserDefaults.standard.set(encoded, forKey: "gratitude_entries")
        }
        
        // Clear entries
        gratitudeEntries = ["", "", ""]
        
        // Update stats
        updateStats()
        
        showSavedAlert = true
    }
    
    private func loadGratitudeEntries() -> [GratitudeEntry] {
        guard let data = UserDefaults.standard.data(forKey: "gratitude_entries"),
              let entries = try? JSONDecoder().decode([GratitudeEntry].self, from: data) else {
            return []
        }
        return entries
    }
    
    private func updateStats() {
        let entries = loadGratitudeEntries()
        totalEntries = entries.count
        
        // Calculate streak
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        
        for i in 0..<30 { // Check last 30 days
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let hasEntry = entries.contains { calendar.isDate($0.date, inSameDayAs: date) }
            
            if hasEntry {
                streak += 1
            } else if i > 0 { // Don't break on today if no entry yet
                break
            }
        }
        
        streakDays = streak
        
        // Save stats
        UserDefaults.standard.set(totalEntries, forKey: "gratitude_total_entries")
        UserDefaults.standard.set(streakDays, forKey: "gratitude_streak_days")
    }
    
    private func loadStats() {
        totalEntries = UserDefaults.standard.integer(forKey: "gratitude_total_entries")
        streakDays = UserDefaults.standard.integer(forKey: "gratitude_streak_days")
    }
}

struct GratitudeEntry: Codable, Identifiable {
    let id: UUID
    let entries: [String]
    let date: Date
}

struct GratitudeHistoryView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var gratitudeEntries: [GratitudeEntry] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "E9D5FF"),
                        Color(hex: "FDE68A"),
                        Color(hex: "FBCFE8"),
                        Color(hex: "DDD6FE")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(gratitudeEntries.reversed()) { entry in
                            GratitudeHistoryCard(entry: entry)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Histórico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadEntries()
        }
    }
    
    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: "gratitude_entries"),
              let entries = try? JSONDecoder().decode([GratitudeEntry].self, from: data) else {
            gratitudeEntries = []
            return
        }
        gratitudeEntries = entries
    }
}

struct GratitudeHistoryCard: View {
    let entry: GratitudeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(VenusTheme.accentPink)
                
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(entry.entries.enumerated()), id: \.offset) { index, gratitude in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(VenusTheme.accentPink.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        
                        Text(gratitude)
                            .font(.body)
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.7))
        )
    }
}

#Preview {
    GratitudeView()
}