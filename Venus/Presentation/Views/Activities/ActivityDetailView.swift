//
//  ActivityDetailView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import Combine

struct ActivityDetailView: View {
    let activity: Activity
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var isCompleted = false
    @State private var showCompletion = false
    @State private var timerActive = false
    @State private var timeRemaining: Int
    
    init(activity: Activity) {
        self.activity = activity
        _timeRemaining = State(initialValue: activity.durationMinutes * 60)
    }
    
    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(VenusTheme.surface)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(VenusTheme.text)
                            )
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(activity.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(VenusTheme.text)
                        
                        Text("\(activity.durationMinutes) min")
                            .font(.caption)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(VenusTheme.primary.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: activity.iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(VenusTheme.primary)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Content Type Logic
                if let steps = activity.steps, !steps.isEmpty {
                    // Guided Steps View
                    guidedStepsView(steps: steps)
                } else if activity.audioUrl != nil {
                    // Audio Placeholder View
                    audioPlayerView()
                } else {
                    // Simple Timer View (for generic activities)
                    simpleTimerView()
                }
            }
        }
        .sheet(isPresented: $showCompletion) {
            ActivityCompletionView(activity: activity) {
                dismiss()
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func guidedStepsView(steps: [String]) -> some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 16) {
                HStack {
                    Text("Passo \(currentStep + 1) de \(steps.count)")
                        .font(.subheadline)
                        .foregroundColor(VenusTheme.textSecondary)
                    
                    Spacer()
                }
                
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: VenusTheme.primary))
                    .scaleEffect(y: 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Content
            ScrollView {
                VStack(spacing: 32) {
                    // Current step
                    VStack(spacing: 20) {
                        Circle()
                            .fill(VenusTheme.primaryGradient)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("\(currentStep + 1)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text(steps[currentStep])
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(VenusTheme.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Breathing animation specific
                    if activity.title.contains("Respiração") {
                        BreathingAnimationView()
                            .frame(height: 200)
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            
            // Controls
            VStack(spacing: 16) {
                if currentStep < steps.count - 1 {
                    Button(action: {
                        withAnimation { currentStep += 1 }
                    }) {
                        PrimaryButtonLabel(text: "Próximo Passo", icon: "arrow.right")
                    }
                } else {
                    Button(action: {
                        showCompletion = true
                    }) {
                        SuccessButtonLabel(text: "Concluir Atividade")
                    }
                }
                
                if currentStep > 0 {
                    Button(action: {
                        withAnimation { currentStep -= 1 }
                    }) {
                        Text("Passo Anterior")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(VenusTheme.primary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    @ViewBuilder
    private func audioPlayerView() -> some View {
        VStack {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(VenusTheme.surface)
                    .frame(width: 200, height: 200)
                    .shadow(color: VenusTheme.primary.opacity(0.2), radius: 20, x: 0, y: 10)
                
                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundColor(VenusTheme.primary)
            }
            
            Spacer()
            
            Text("Áudio em Breve")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(VenusTheme.text)
            
            Text("Esta prática guiada estará disponível numa próxima atualização.")
                .font(.body)
                .foregroundColor(VenusTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                PrimaryButtonLabel(text: "Voltar", icon: "arrow.left")
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private func simpleTimerView() -> some View {
        VStack {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(VenusTheme.primary.opacity(0.3), lineWidth: 20)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(activity.durationMinutes * 60))
                    .stroke(VenusTheme.primary, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                Text(formatTime(timeRemaining))
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
            }
            
            Spacer()
            
            HStack(spacing: 40) {
                Button(action: { timerActive.toggle() }) {
                    Circle()
                        .fill(VenusTheme.primaryGradient)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: timerActive ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                }
            }
            
            Spacer()
            
            if timeRemaining == 0 {
                Button(action: { showCompletion = true }) {
                    SuccessButtonLabel(text: "Concluir")
                }
                .padding(24)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timerActive && timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Reusable Components

struct PrimaryButtonLabel: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
            
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(VenusTheme.primaryGradient)
        .cornerRadius(28)
    }
}

struct SuccessButtonLabel: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            LinearGradient(
                colors: [.green, VenusTheme.primary],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(28)
    }
}

// Reuse existing completion view but updated for Activity model
struct ActivityCompletionView: View {
    let activity: Activity
    let onDismiss: () -> Void
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Celebration animation
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.3), .green.opacity(0.1)],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: showCelebration ? 160 : 100, height: showCelebration ? 160 : 100)
                        .animation(.easeOut(duration: 1), value: showCelebration)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.green)
                        .scaleEffect(showCelebration ? 1.2 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCelebration)
                }
                
                VStack(spacing: 16) {
                    Text("Parabéns! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(VenusTheme.text)
                    
                    Text("Você completou a atividade:")
                        .font(.subheadline)
                        .foregroundColor(VenusTheme.textSecondary)
                    
                    Text(activity.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(VenusTheme.primary)
                    
                    Text("Como você está se sentindo agora?")
                        .font(.body)
                        .foregroundColor(VenusTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("Continuar")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(VenusTheme.primaryGradient)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCelebration = true
            }
        }
    }
}

#Preview {
    ActivityDetailView(activity: Activity(
        title: "Teste",
        description: "Desc",
        category: .relaxation,
        durationMinutes: 5,
        iconName: "star",
        steps: ["Passo 1", "Passo 2"]
    ))
}
