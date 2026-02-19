//
//  BreathingView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import Combine

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BreathingViewModel()
    
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
            
            // Animated background particles
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(VenusTheme.primary.opacity(0.1))
                    .frame(width: CGFloat.random(in: 20...60))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800)
                    )
                    .scaleEffect(viewModel.breathingAnimation ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...5))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: viewModel.breathingAnimation
                    )
            }
            
            VStack(spacing: 40) {
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
                    
                    Text("Respiração")
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
                
                // Breathing Circle
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        VenusTheme.primary.opacity(0.3),
                                        VenusTheme.secondary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 300 + CGFloat(index * 40))
                            .scaleEffect(viewModel.breathingAnimation ? 1.1 : 0.9)
                            .opacity(viewModel.breathingAnimation ? 0.8 : 0.4)
                            .animation(
                                .easeInOut(duration: viewModel.breathingCycleDuration)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: viewModel.breathingAnimation
                            )
                    }
                    
                    // Main breathing circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    VenusTheme.primary.opacity(0.6),
                                    VenusTheme.secondary.opacity(0.3),
                                    VenusTheme.tertiary.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )
                        .frame(width: 250, height: 250)
                        .scaleEffect(viewModel.breathingAnimation ? 1.3 : 0.7)
                        .animation(
                            .easeInOut(duration: viewModel.breathingCycleDuration)
                            .repeatForever(autoreverses: true),
                            value: viewModel.breathingAnimation
                        )
                        .overlay(
                            // Inner glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white.opacity(0.8), .clear],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 80
                                    )
                                )
                                .scaleEffect(viewModel.breathingAnimation ? 0.8 : 1.2)
                                .animation(
                                    .easeInOut(duration: viewModel.breathingCycleDuration)
                                    .repeatForever(autoreverses: true),
                                    value: viewModel.breathingAnimation
                                )
                        )
                    
                    // Instruction text
                    VStack(spacing: 8) {
                        Text(viewModel.currentInstruction)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                        
                        if viewModel.isRunning {
                            Text("\(viewModel.currentCycle)/\(viewModel.totalCycles)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 20) {
                    Button(action: viewModel.toggleBreathing) {
                        HStack {
                            Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                            Text(viewModel.isRunning ? "Pausar" : "Iniciar")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(VenusTheme.primaryGradient)
                        .cornerRadius(25)
                        .shadow(color: VenusTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // Stats
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(viewModel.completedSessions)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black.opacity(0.8))
                            Text("Sessões")
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(viewModel.totalMinutes)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black.opacity(0.8))
                            Text("Minutos")
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
        .onAppear {
            viewModel.startBackgroundAnimation()
        }
        .sheet(isPresented: $viewModel.showSettings) {
            BreathingSettingsView(viewModel: viewModel)
        }
    }
}

@MainActor
class BreathingViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var breathingAnimation = false
    @Published var currentInstruction = "Toque para começar"
    @Published var currentCycle = 0
    @Published var showSettings = false
    
    // Settings
    @Published var inhaleTime: Double = 4.0
    @Published var holdTime: Double = 4.0
    @Published var exhaleTime: Double = 4.0
    @Published var totalCycles = 10
    @Published var completedSessions = 0
    
    private var timer: Timer?
    private var phaseTimer: Timer?
    private var currentPhase: BreathingPhase = .inhale
    
    var breathingCycleDuration: Double {
        inhaleTime + holdTime + exhaleTime
    }
    
    var totalMinutes: Int {
        Int(Double(completedSessions) * breathingCycleDuration * Double(totalCycles) / 60.0)
    }
    
    init() {
        loadSettings()
    }
    
    func startBackgroundAnimation() {
        breathingAnimation = true
    }
    
    func toggleBreathing() {
        if isRunning {
            stopBreathing()
        } else {
            startBreathing()
        }
    }
    
    private func startBreathing() {
        isRunning = true
        currentCycle = 0
        currentPhase = .inhale
        startBreathingCycle()
    }
    
    private func stopBreathing() {
        isRunning = false
        timer?.invalidate()
        phaseTimer?.invalidate()
        currentInstruction = "Toque para começar"
    }
    
    private func startBreathingCycle() {
        guard currentCycle < totalCycles else {
            completeSession()
            return
        }
        
        currentCycle += 1
        currentPhase = .inhale
        runPhase()
    }
    
    private func runPhase() {
        switch currentPhase {
        case .inhale:
            currentInstruction = "Inspire"
            phaseTimer = Timer.scheduledTimer(withTimeInterval: inhaleTime, repeats: false) { _ in
                Task { @MainActor in
                    self.currentPhase = .hold
                    self.runPhase()
                }
            }
        case .hold:
            currentInstruction = "Segure"
            phaseTimer = Timer.scheduledTimer(withTimeInterval: holdTime, repeats: false) { _ in
                Task { @MainActor in
                    self.currentPhase = .exhale
                    self.runPhase()
                }
            }
        case .exhale:
            currentInstruction = "Expire"
            phaseTimer = Timer.scheduledTimer(withTimeInterval: exhaleTime, repeats: false) { _ in
                Task { @MainActor in
                    self.startBreathingCycle()
                }
            }
        }
    }
    
    private func completeSession() {
        stopBreathing()
        completedSessions += 1
        currentInstruction = "Sessão completa!"
        saveSettings()
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentInstruction = "Toque para começar"
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(inhaleTime, forKey: "breathing_inhale_time")
        UserDefaults.standard.set(holdTime, forKey: "breathing_hold_time")
        UserDefaults.standard.set(exhaleTime, forKey: "breathing_exhale_time")
        UserDefaults.standard.set(totalCycles, forKey: "breathing_total_cycles")
        UserDefaults.standard.set(completedSessions, forKey: "breathing_completed_sessions")
    }
    
    private func loadSettings() {
        inhaleTime = UserDefaults.standard.object(forKey: "breathing_inhale_time") as? Double ?? 4.0
        holdTime = UserDefaults.standard.object(forKey: "breathing_hold_time") as? Double ?? 4.0
        exhaleTime = UserDefaults.standard.object(forKey: "breathing_exhale_time") as? Double ?? 4.0
        totalCycles = UserDefaults.standard.object(forKey: "breathing_total_cycles") as? Int ?? 10
        completedSessions = UserDefaults.standard.object(forKey: "breathing_completed_sessions") as? Int ?? 0
    }
}

enum BreathingPhase {
    case inhale, hold, exhale
}

struct BreathingSettingsView: View {
    @ObservedObject var viewModel: BreathingViewModel
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
                        BreathingSettingRow(title: "Inspirar", value: $viewModel.inhaleTime, range: 2.0...8.0)
                        BreathingSettingRow(title: "Segurar", value: $viewModel.holdTime, range: 0.0...8.0)
                        BreathingSettingRow(title: "Expirar", value: $viewModel.exhaleTime, range: 2.0...8.0)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Ciclos por Sessão")
                                    .font(.headline)
                                    .foregroundColor(.black.opacity(0.8))
                                
                                Spacer()
                                
                                Text("\(viewModel.totalCycles)")
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Slider(value: Binding(
                                get: { Double(viewModel.totalCycles) },
                                set: { viewModel.totalCycles = Int($0) }
                            ), in: 5...30, step: 1)
                            .tint(VenusTheme.primary)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.7))
                        )
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

struct BreathingSettingRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
                
                Text(String(format: "%.1fs", value))
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.6))
            }
            
            Slider(value: $value, in: range, step: 0.5)
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
    BreathingView()
}