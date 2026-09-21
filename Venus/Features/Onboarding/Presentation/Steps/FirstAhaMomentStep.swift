//
//  FirstAhaMomentStep.swift
//  Venus
//
//  Created by Kaua on 20/09/26.
//

import SwiftUI

struct FirstAhaMomentStep: View {
    let userProfile: UserProfile
    let onFinish: () -> Void
    
    @State private var messageAppeared = false
    @State private var chipsAppeared = false
    @State private var selectedTopic: String? = nil
    
    private var firstName: String {
        userProfile.name.components(separatedBy: " ").first ?? "você"
    }
    
    private var toneDescription: String {
        userProfile.coachingTone.isEmpty ? "acolhedor" : userProfile.coachingTone.lowercased()
    }
    
    private let promptStarters = [
        "Tive um dia intenso",
        "Quero organizar meus pensamentos agora",
        "Só quero um momento de paz e clareza"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                
                
                Text("Seu espaço seguro está pronto")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 10)
            
            // Venus Realtime Greeting Card
            VenusCard(cornerRadius: 26, padding: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        VenusMoodOrb(mood: .happy, size: 44)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Venus")
                                .font(.system(.headline, design: .rounded).weight(.black))
                                .foregroundStyle(VenusTheme.text)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(VenusTheme.primary)
                                    .frame(width: 7, height: 7)
                                Text("Online")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(VenusTheme.primary)
                            }
                        }
                    }
                    
                    Text("**\(firstName)**, já sintonizei nosso espaço com o tom **\(toneDescription)**.")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(VenusTheme.text)
                        .lineSpacing(3)
                        .padding(.top, 2)
                }
            }
            .opacity(messageAppeared ? 1 : 0)
            .scaleEffect(messageAppeared ? 1 : 0.95)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: messageAppeared)
            
            // Fast Topic Starters
            VStack(alignment: .leading, spacing: 12) {
                Text("Por onde quer começar?")
                    .font(.system(.subheadline, design: .rounded).weight(.black))
                    .foregroundStyle(VenusTheme.text)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 10) {
                    ForEach(promptStarters, id: \.self) { prompt in
                        starterChip(prompt: prompt)
                    }
                }
            }
            .opacity(chipsAppeared ? 1 : 0)
            .offset(y: chipsAppeared ? 0 : 16)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: chipsAppeared)
            
            Spacer()
            
            // Main Action Button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onFinish()
            } label: {
                HStack(spacing: 10) {
                    Text("Entrar no Meu Refúgio")
                        .font(.system(.headline, design: .rounded).weight(.black))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20, weight: .black))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(VenusTheme.primaryGradient, in: Capsule())
                .shadow(color: VenusTheme.primary.opacity(0.32), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                messageAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    chipsAppeared = true
                }
            }
        }
    }
    
    private func starterChip(prompt: String) -> some View {
        let isSelected = selectedTopic == prompt
        
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedTopic = prompt
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onFinish()
            }
        } label: {
            HStack {
                Text(prompt)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(isSelected ? .white : VenusTheme.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(isSelected ? .white : VenusTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(VenusTheme.primaryGradient)
                }
            }
            .contentShape(.rect)
//            .glassEffect(isSelected ? .clear : .regular.interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FirstAhaMomentStep(userProfile: UserProfile(), onFinish: {})
        .background(VenusTheme.backgroundGradient)
}
