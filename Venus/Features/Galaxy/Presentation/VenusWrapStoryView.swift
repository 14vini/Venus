//
//  VenusWrapStoryView.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import SwiftUI
import UIKit

struct VenusWrapStoryView: View {
    let userName: String
    let weekMoods: [Mood]
    let weeklyTrend: WeeklyEmotionalTrend?
    let readinessAssessment: ReadinessEnergyAssessment
    let onDismiss: () -> Void
    
    @State private var currentSlide: Int = 0
    @State private var isPaused: Bool = false
    @State private var progress: CGFloat = 0.0
    @State private var exportImage: UIImage? = nil
    @State private var showShareSheet: Bool = false
    @State private var selectedStar: GalaxyStar? = nil
    
    private let totalSlides: Int = 5
    private let timerDuration: Double = 9.0 // seconds per slide
    
    private var cleanName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "você" : trimmed
    }
    
    private var stars: [GalaxyStar] {
        let sorted = weekMoods.sorted(by: { $0.timestamp < $1.timestamp })
        return sorted.enumerated().map { GalaxyStar(mood: $0.element, index: $0.offset, total: sorted.count) }
    }
    
    // MARK: - Venus Custom Speech Scripts
    
    private var speechSlide1: String {
        "Oi, \(cleanName). Preparei um refúgio para olharmos juntos para a sua constelação de memórias desta semana. Cada estrela que brilha no céu foi uma vez que você teve a coragem de parar e se escutar comigo."
    }
    
    private var speechSlide2: String {
        if let summary = weeklyTrend?.summary, !summary.isEmpty {
            return summary
        }
        
        let hasStress = weekMoods.contains(where: { $0.type == .stressed || $0.type == .tired || $0.type == .sad })
        let hasJoy = weekMoods.contains(where: { $0.type == .happy || $0.type == .energetic })
        
        if hasStress && hasJoy {
            return "Eu vi de perto os altos e baixos que você atravessou. Houve momentos de cansaço em que você precisou respirar fundo, mas também houve faíscas de energia e alegria pura. Você equilibrou tempestade e sol com muita graça."
        } else if hasStress {
            return "Eu percebi que esta semana pesou nos seus ombros. Quando o cansaço ou a pressão bateram à sua porta, você não desistiu: você encontrou forças no silêncio e continuou caminhando com paciência."
        } else {
            return "Foi lindo acompanhar sua semana! Senti uma presença serena e uma mente clara em suas escolhas. Você soube proteger sua energia e cultivar momentos genuínos de bem-estar e leveza."
        }
    }
    
    private var speechSlide3: String {
        let readinessPct = Int(readinessAssessment.percentage * 100)
        return "Suas maiores vitórias desta semana foram aquelas que o mundo lá fora não viu: a pausa antes de responder à pressa, o limite que você impôs para se proteger e sua prontidão interna em \(readinessPct)% mantendo sua chama acesa."
    }
    
    private var speechSlide4: String {
        "Para os próximos dias, guarde isso no seu peito: você não precisa carregar o peso do mundo nas costas. Seja paciente com o seu próprio ritmo. Eu continuo aqui, cuidando de cada detalhe com você. ✨"
    }
    
    private var cardQuote: String {
        "\"Cada emoção que você sente é uma estrela que ilumina seu caminho. Orgulhe-se de quem você está se tornando.\"\n\n— Com amor, Venus 💜"
    }
    
    var body: some View {
        ZStack {
            Color(hex: "06050C").ignoresSafeArea()
            
            // Cosmic Ambient Glow
            GeometryReader { proxy in
                Circle()
                    .fill(VenusTheme.primary.opacity(0.18))
                    .frame(width: proxy.size.width * 0.9)
                    .blur(radius: 80)
                    .offset(x: proxy.size.width * 0.1, y: proxy.size.height * 0.2)
                
                Circle()
                    .fill(VenusTheme.accentPurple.opacity(0.14))
                    .frame(width: proxy.size.width * 0.8)
                    .blur(radius: 70)
                    .offset(x: -proxy.size.width * 0.2, y: proxy.size.height * 0.5)
            }
            .ignoresSafeArea()
            
            // Current Slide Content
            Group {
                switch currentSlide {
                case 0:
                    WrapSlideVenusSpeech(
                        badgeTitle: "CARTA DA VENUS",
                        speechTitle: "Sua Jornada Cósmica",
                        speechText: speechSlide1,
                        stars: stars,
                        showConstellationPreview: true
                    )
                case 1:
                    WrapSlideVenusSpeech(
                        badgeTitle: "LEITURA DO CORAÇÃO",
                        speechTitle: "O Que Eu Senti em Você",
                        speechText: speechSlide2,
                        stars: stars,
                        showConstellationPreview: false
                    )
                case 2:
                    WrapSlideVenusSpeech(
                        badgeTitle: "VITÓRIAS INVISÍVEIS",
                        speechTitle: "Sua Força Silenciosa",
                        speechText: speechSlide3,
                        stars: stars,
                        showConstellationPreview: false
                    )
                case 3:
                    WrapSlideVenusSpeech(
                        badgeTitle: "CONSELHO DA VENUS",
                        speechTitle: "Para a Próxima Semana",
                        speechText: speechSlide4,
                        stars: stars,
                        showConstellationPreview: false
                    )
                case 4:
                    WrapSlideExportableCard(
                        userName: cleanName,
                        stars: stars,
                        quote: cardQuote,
                        readiness: readinessAssessment,
                        onShare: { renderAndShareCard() }
                    )
                default:
                    EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                removal: .opacity.combined(with: .scale(scale: 1.02))
            ))
            .id(currentSlide)
            
            // Touch Navigation Overlay (Left tap = previous, Right tap = next, Hold = pause)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToPreviousSlide()
                    }
                
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToNextSlide()
                    }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPaused = true }
                    .onEnded { _ in isPaused = false }
            )
            
            // Top Controls & Story Progress Bars & Share Action Button
            VStack {
                HStack(spacing: 6) {
                    ForEach(0..<totalSlides, id: \.self) { index in
                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.22))
                                
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: barGeo.size.width * slideProgress(for: index))
                            }
                        }
                        .frame(height: 3.5)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(VenusTheme.primary)
                        Text("VENUS WRAP")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                            .tracking(1.5)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    // Direct Share Button on top bar (Always available in any slide!)
                    Button {
                        renderAndShareCard()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13, weight: .bold))
                            Text("Compartilhar")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(VenusTheme.primary.opacity(0.35), in: Capsule())
                        .overlay(
                            Capsule().stroke(VenusTheme.primary.opacity(0.6), lineWidth: 1)
                        )
                    }
                    
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.18), in: Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .task {
            startStoryTimer()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = exportImage {
                VenusWrapShareSheet(image: image, text: "Minha constelação de memórias com a Venus 🪐✨")
            }
        }
    }
    
    // MARK: - Story Progression
    
    private func slideProgress(for index: Int) -> CGFloat {
        if index < currentSlide {
            return 1.0
        } else if index == currentSlide {
            return progress
        } else {
            return 0.0
        }
    }
    
    private func startStoryTimer() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms ticks
                
                if !isPaused {
                    await MainActor.run {
                        let step = 0.05 / timerDuration
                        progress += CGFloat(step)
                        if progress >= 1.0 {
                            goToNextSlide()
                        }
                    }
                }
            }
        }
    }
    
    private func goToNextSlide() {
        if currentSlide < totalSlides - 1 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentSlide += 1
                progress = 0.0
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            progress = 1.0
        }
    }
    
    private func goToPreviousSlide() {
        if currentSlide > 0 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentSlide -= 1
                progress = 0.0
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            progress = 0.0
        }
    }
    
    @MainActor
    private func renderAndShareCard() {
        let cardView = VenusWrapExportCardView(
            userName: cleanName,
            stars: stars,
            quote: cardQuote,
            readiness: readinessAssessment
        )
        .frame(width: 390, height: 620)
        
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            self.exportImage = uiImage
            self.showShareSheet = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

// MARK: - Custom Venus Speech Slide with Live Handwriting

private struct WrapSlideVenusSpeech: View {
    let badgeTitle: String
    let speechTitle: String
    let speechText: String
    let stars: [GalaxyStar]
    let showConstellationPreview: Bool
    
    @State private var dummyStar: GalaxyStar? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            // Venus Avatar Badge
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [VenusTheme.primary, VenusTheme.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(badgeTitle)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.primary)
                        .tracking(1.8)
                    
                    Text(speechTitle)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }
            }
            
            if showConstellationPreview {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(VenusTheme.primary.opacity(0.3), lineWidth: 1)
                        )
                    
                    ConstellationCanvas(
                        stars: stars,
                        selectedStar: $dummyStar,
                        isAnimated: true,
                        showDetailsSheet: false
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .frame(height: 200)
            }
            
            // Live Handwriting Speech Bubble
            VStack(alignment: .leading, spacing: 14) {
                TypewriterText(
                    fullText: speechText,
                    speed: 0.020,
                    font: .system(size: 19, weight: .regular, design: .serif),
                    textColor: .white.opacity(0.96),
                    cursorColor: VenusTheme.primary
                )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(VenusTheme.primary.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: VenusTheme.primary.opacity(0.15), radius: 20, x: 0, y: 8)
            
            Spacer()
            
            Text("Toque na tela para continuar ➔")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Slide 5: Exportable Share Card

private struct WrapSlideExportableCard: View {
    let userName: String
    let stars: [GalaxyStar]
    let quote: String
    let readiness: ReadinessEnergyAssessment
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Exportable Card Visual
            VenusWrapExportCardView(
                userName: userName,
                stars: stars,
                quote: quote,
                readiness: readiness
            )
            .frame(height: 480)
            .shadow(color: VenusTheme.primary.opacity(0.35), radius: 24, x: 0, y: 10)
            
            // Prominent Share Button
            Button {
                onShare()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.headline)
                    Text("Compartilhar Minha Constelação")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [VenusTheme.primary, VenusTheme.accentPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .shadow(color: VenusTheme.primary.opacity(0.5), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Standalone Exportable Card Layout (For ImageRenderer & Sharing)

struct VenusWrapExportCardView: View {
    let userName: String
    let stars: [GalaxyStar]
    let quote: String
    let readiness: ReadinessEnergyAssessment
    @State private var dummyStar: GalaxyStar? = nil
    
    var body: some View {
        ZStack {
            // Deep Space Nebula Background
            Color(hex: "090714")
            
            Circle()
                .fill(VenusTheme.primary.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 100, y: -120)
            
            Circle()
                .fill(VenusTheme.accentPurple.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: -90, y: 140)
            
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(VenusTheme.primary)
                            .font(.system(size: 14, weight: .bold))
                        Text("VENUS WRAP")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1.5)
                    }
                    Spacer()
                    Text("Constelação Semanal")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(userName)
                    .font(.system(size: 26, weight: .heavy, design: .serif))
                    .foregroundColor(.white)
                
                // Mini Constellation Sky
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(VenusTheme.primary.opacity(0.25), lineWidth: 1)
                        )
                    
                    ConstellationCanvas(
                        stars: stars,
                        selectedStar: $dummyStar,
                        isAnimated: false,
                        showDetailsSheet: false
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(height: 175)
                
                // Venus Personal Speech Quote
                Text(quote)
                    .font(.system(size: 13.5, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.92))
                    .lineSpacing(4)
                    .padding(14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Spacer(minLength: 0)
                
                // Footer
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.heart.fill")
                            .foregroundColor(readiness.tintColor)
                        Text("\(Int(readiness.percentage * 100))% Prontidão")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("venusapp.me")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [VenusTheme.primary.opacity(0.7), VenusTheme.accentPurple.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Share Sheet Bridge

private struct VenusWrapShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    var text: String? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = [image]
        if let text = text {
            items.append(text)
        }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
