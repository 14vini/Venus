//
//  TypewriterText.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import SwiftUI
import UIKit

/// Renders text character-by-character with a gentle handwriting/typewriter cadence and subtle glowing cursor.
struct TypewriterText: View {
    let fullText: String
    var speed: Double = 0.024
    var font: Font = .system(size: 18, weight: .medium, design: .serif)
    var textColor: Color = .white
    var cursorColor: Color = VenusTheme.primary
    var onFinished: (() -> Void)? = nil
    
    @State private var displayedCount: Int = 0
    @State private var isWriting: Bool = false
    @State private var cursorVisible: Bool = true
    @State private var timerTask: Task<Void, Never>? = nil
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .soft)
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            Text(currentDisplayedText)
                .font(font)
                .foregroundColor(textColor)
                .lineSpacing(6)
            
            if isWriting || cursorVisible {
                Rectangle()
                    .fill(cursorColor)
                    .frame(width: 2.5, height: 20)
                    .opacity(cursorVisible ? 0.9 : 0.1)
                    .offset(y: -2)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: cursorVisible)
            }
        }
        .onAppear {
            lightHaptic.prepare()
            startTyping()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }
    
    private var currentDisplayedText: String {
        let prefixCount = min(displayedCount, fullText.count)
        return String(fullText.prefix(prefixCount))
    }
    
    private func startTyping() {
        guard !fullText.isEmpty else {
            onFinished?()
            return
        }
        
        displayedCount = 0
        isWriting = true
        cursorVisible = true
        timerTask?.cancel()
        
        timerTask = Task {
            for i in 1...fullText.count {
                if Task.isCancelled { break }
                
                try? await Task.sleep(nanoseconds: UInt64(speed * 1_000_000_000))
                
                await MainActor.run {
                    self.displayedCount = i
                    if i % 6 == 0 {
                        self.lightHaptic.impactOccurred(intensity: 0.25)
                    }
                }
            }
            
            await MainActor.run {
                self.isWriting = false
                self.onFinished?()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TypewriterText(
            fullText: "Nesta semana, você navegou por momentos de alta intensidade, mas soube reencontrar sua calma nas pequenas pausas. Sua constelação brilha com resiliência.",
            speed: 0.03
        )
        .padding(24)
    }
}
