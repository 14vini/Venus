//
//  PomodoroView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import Combine

struct PomodoroView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PomodoroViewModel()
    
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
            
            // Animated orbs
            ZStack {
                Circle()
                    .fill(VenusTheme.primary.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(x: -80, y: -150)
                    .scaleEffect(viewModel.isRunning ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: viewModel.isRunning)
                
                Circle()
                    .fill(VenusTheme.accentPink.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)
                    .offset(x: 100, y: 200)
                    .scaleEffect(viewModel.isRunning ? 0.7 : 1.1)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(1), value: viewModel.isRunning)
            }
            
            VStack(spacing: 30) {
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
                    
                    Text("Pomodoro")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black.opacity(0.8))
                    
                    Spacer()
                    
                    Button(action: { viewModel.showSettings.toggle() }) {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.7))
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Timer Circle
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 280, height: 280)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(
                            LinearGradient(
                                colors: [VenusTheme.primary, VenusTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.progress)
                    
                    // Center content
                    VStack(spacing: 12) {
                        Text(viewModel.currentPhase.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black.opacity(0.6))
                        
                        Text(viewModel.timeString)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text("Sessão \(viewModel.currentSession)/\(viewModel.totalSessions)")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        // Reset button
                        Button(action: viewModel.reset) {
                            Circle()
                                .fill(.white.opacity(0.6))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title2)
                                        .foregroundColor(.black.opacity(0.7))
                                )
                        }
                        
                        // Play/Pause button
                        Button(action: viewModel.toggleTimer) {
                            Circle()
                                .fill(VenusTheme.primaryGradient)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .offset(x: viewModel.isRunning ? 0 : 3)
                                )
                                .scaleEffect(viewModel.isRunning ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isRunning)
                        }
                        
                        // Skip button
                        Button(action: viewModel.skipPhase) {
                            Circle()
                                .fill(.white.opacity(0.6))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "forward.fill")
                                        .font(.title2)
                                        .foregroundColor(.black.opacity(0.7))
                                )
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(viewModel.completedSessions)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black.opacity(0.8))
                            Text("Completas")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(viewModel.totalFocusTime)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black.opacity(0.8))
                            Text("Min Foco")
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
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            PomodoroSettingsView(viewModel: viewModel)
        }
    }
}

@MainActor
class PomodoroViewModel: ObservableObject {
    @Published var timeRemaining: Int = 25 * 60 // 25 minutes
    @Published var isRunning = false
    @Published var currentPhase: PomodoroPhase = .focus
    @Published var currentSession = 1
    @Published var completedSessions = 0
    @Published var showSettings = false
    
    // Settings
    @Published var focusTime = 25
    @Published var shortBreakTime = 5
    @Published var longBreakTime = 15
    @Published var totalSessions = 4
    
    private var timer: Timer?
    private var initialTime: Int = 25 * 60
    
    var progress: Double {
        guard initialTime > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(initialTime))
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var totalFocusTime: Int {
        completedSessions * focusTime
    }
    
    init() {
        loadSettings()
        updateInitialTime()
    }
    
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.tick()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completePhase()
        }
    }
    
    private func completePhase() {
        pauseTimer()
        
        switch currentPhase {
        case .focus:
            completedSessions += 1
            if completedSessions % totalSessions == 0 {
                currentPhase = .longBreak
                timeRemaining = longBreakTime * 60
            } else {
                currentPhase = .shortBreak
                timeRemaining = shortBreakTime * 60
            }
        case .shortBreak, .longBreak:
            currentPhase = .focus
            currentSession += 1
            timeRemaining = focusTime * 60
        }
        
        updateInitialTime()
        saveSettings()
    }
    
    func skipPhase() {
        pauseTimer()
        completePhase()
    }
    
    func reset() {
        pauseTimer()
        currentPhase = .focus
        currentSession = 1
        timeRemaining = focusTime * 60
        updateInitialTime()
    }
    
    private func updateInitialTime() {
        switch currentPhase {
        case .focus:
            initialTime = focusTime * 60
        case .shortBreak:
            initialTime = shortBreakTime * 60
        case .longBreak:
            initialTime = longBreakTime * 60
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(focusTime, forKey: "pomodoro_focus_time")
        UserDefaults.standard.set(shortBreakTime, forKey: "pomodoro_short_break")
        UserDefaults.standard.set(longBreakTime, forKey: "pomodoro_long_break")
        UserDefaults.standard.set(totalSessions, forKey: "pomodoro_total_sessions")
        UserDefaults.standard.set(completedSessions, forKey: "pomodoro_completed_sessions")
    }
    
    private func loadSettings() {
        focusTime = UserDefaults.standard.object(forKey: "pomodoro_focus_time") as? Int ?? 25
        shortBreakTime = UserDefaults.standard.object(forKey: "pomodoro_short_break") as? Int ?? 5
        longBreakTime = UserDefaults.standard.object(forKey: "pomodoro_long_break") as? Int ?? 15
        totalSessions = UserDefaults.standard.object(forKey: "pomodoro_total_sessions") as? Int ?? 4
        completedSessions = UserDefaults.standard.object(forKey: "pomodoro_completed_sessions") as? Int ?? 0
    }
}

enum PomodoroPhase: CaseIterable {
    case focus, shortBreak, longBreak
    
    var title: String {
        switch self {
        case .focus: return "Foco"
        case .shortBreak: return "Pausa Curta"
        case .longBreak: return "Pausa Longa"
        }
    }
}

struct PomodoroSettingsView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                
                VStack(spacing: 30) {
                    VStack(spacing: 20) {
                        SettingRow(title: "Tempo de Foco", value: $viewModel.focusTime, range: 15...60)
                        SettingRow(title: "Pausa Curta", value: $viewModel.shortBreakTime, range: 3...15)
                        SettingRow(title: "Pausa Longa", value: $viewModel.longBreakTime, range: 10...30)
                        SettingRow(title: "Sessões por Ciclo", value: $viewModel.totalSessions, range: 2...8)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
                
                Text("\(value) min")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
            .tint(VenusTheme.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.7))
        )
    }
}

#Preview {
    PomodoroView()
}