//
//  CelestialMapView.swift
//  Venus
//

import SwiftUI

struct CelestialMapView: View {
    let weekMoods: [Mood]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Gradients
                LinearGradient(
                    colors: [
                        Color(hex: "0A0B1A"), // Noite escura no topo/esquerda
                        Color(hex: "1F234B"), // Transição central
                        Color(hex: "342345")  // Amanhecer suave
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Névoa calma na base
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color.clear, VenusTheme.moodMintStrong.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.4)
                }

                // Grid sutil (opcional)
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    path.move(to: CGPoint(x: w/2, y: 0))
                    path.addLine(to: CGPoint(x: w/2, y: h))
                    path.move(to: CGPoint(x: 0, y: h/2))
                    path.addLine(to: CGPoint(x: w, y: h/2))
                }
                .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [4]))

                // Axis Labels
                VStack {
                    Text("Alta Energia")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                        .padding(.top, 8)
                    Spacer()
                    Text("Calma / Baixa Energia")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                        .padding(.bottom, 8)
                }
                
                HStack {
                    Text("Desconforto")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                        .rotationEffect(.degrees(-90))
                        .padding(.leading, -16)
                    Spacer()
                    Text("Bem-estar")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                        .rotationEffect(.degrees(90))
                        .padding(.trailing, -10)
                }

                // Plotting the Stars
                ForEach(weekMoods) { mood in
                    let position = calculatePosition(for: mood, in: geometry.size)
                    let starColor = color(for: mood.type)
                    
                    Circle()
                        .fill(starColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: starColor, radius: 6, x: 0, y: 0)
                        .position(position)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func calculatePosition(for mood: Mood, in size: CGSize) -> CGPoint {
        // Valência: -1 (triste) a 1 (feliz)
        var valence: CGFloat = 0
        switch mood.type {
        case .happy: valence = 0.8
        case .calm: valence = 0.5
        case .energetic: valence = 0.7
        case .tired: valence = -0.3
        case .stressed: valence = -0.7
        case .sad: valence = -0.8
        }
        
        // Energia: -1 (baixa) a 1 (alta)
        var energy: CGFloat = 0
        if let energyLevel = mood.energyLevel {
            switch energyLevel {
            case .low: energy = -0.8
            case .medium: energy = 0
            case .high: energy = 0.8
            }
        } else {
            // Fallback based on mood
            switch mood.type {
            case .happy, .energetic, .stressed: energy = 0.6
            case .calm: energy = 0
            case .tired, .sad: energy = -0.6
            }
        }
        
        // Intensidade aumenta o deslocamento do centro
        let intensityFactor = CGFloat(mood.intensity ?? 5) / 10.0
        valence *= (0.5 + 0.5 * intensityFactor)
        energy *= (0.5 + 0.5 * intensityFactor)
        
        // Limitar dentro dos bounds com margem
        let safeMargin: CGFloat = 20
        let availableWidth = size.width - (safeMargin * 2)
        let availableHeight = size.height - (safeMargin * 2)
        
        // Mapear para a tela (Eixo Y invertido porque 0 é no topo)
        let x = safeMargin + ((valence + 1) / 2 * availableWidth)
        let y = safeMargin + ((1 - energy) / 2 * availableHeight)
        
        return CGPoint(x: x, y: y)
    }

    private func color(for moodType: MoodType) -> Color {
        switch moodType {
        case .happy: return Color(hex: "FFD700") // Ouro
        case .calm: return VenusTheme.moodMintStrong
        case .energetic: return VenusTheme.accentOrange
        case .tired: return Color(hex: "8A2BE2") // Roxo profundo
        case .stressed: return VenusTheme.accentPink
        case .sad: return VenusTheme.accentBlue
        }
    }
}
