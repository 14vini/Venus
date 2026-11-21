//
//  VenusCheckInCarouselPicker.swift
//  Venus
//
//  Seletor e controle deslizante tátil (arrastar com os dedos) para escolha
//  de produtividade e energia, adaptado para modo claro e escuro.
//

import SwiftUI

struct VenusCheckInCarouselPicker: View {
    @Binding var selectedLevel: VenusCheckInMoodLevel
    var onLevelChanged: ((VenusCheckInMoodLevel) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private let levels = VenusCheckInMoodLevel.allCases

    @State private var isDragging: Bool = false
    @State private var dragCurrentX: CGFloat? = nil

    private var activeTextColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "18263E")
    }

    private var unselectedTextColor: Color {
        colorScheme == .dark ? Color(hex: "94A3B8") : Color(hex: "18263E")
    }

    private var accentColor: Color {
        colorScheme == .dark ? Color(hex: "60A5FA") : Color(hex: "4F78DE")
    }

    private var trackBaseColor: Color {
        colorScheme == .dark ? Color(hex: "162438") : Color.white.opacity(0.75)
    }

    private var thumbColor: Color {
        colorScheme == .dark ? Color(hex: "1E2E44") : Color.white
    }

    var body: some View {
        VStack(spacing: 20) {
            // 1. Carrossel de Texto das Opções (Opção central em destaque)
            textCarouselView

            // 2. Slider Tátil Interativo de Arrastar com os Dedos
            interactiveSliderTrack
                .padding(.horizontal, 28)
        }
    }

    // MARK: - Carrossel de Texto

    private var textCarouselView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let itemWidth: CGFloat = width * 0.72

            HStack(spacing: 0) {
                ForEach(levels) { level in
                    let isSelected = level == selectedLevel
                    let distance = abs(level.rawValue - selectedLevel.rawValue)

                    Button {
                        selectLevel(level)
                    } label: {
                        VStack(spacing: 4) {
                            Text(level.title)
                                .font(
                                    .system(
                                        size: isSelected ? 22 : 16,
                                        weight: isSelected ? .bold : .medium,
                                        design: .rounded
                                    )
                                )
                                .foregroundColor(
                                    isSelected
                                        ? activeTextColor
                                        : unselectedTextColor.opacity(max(0.25, 0.60 - Double(distance) * 0.18))
                                )
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: itemWidth)
                                .scaleEffect(isSelected ? 1.0 : 0.86)
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)

                            // Rótulo curto sob a opção ativa
                            if isSelected {
                                Text(level.shortLabel)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(accentColor)
                                    .textCase(.uppercase)
                                    .tracking(1.0)
                                    .transition(.opacity)
                            }
                        }
                        .frame(width: itemWidth)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .offset(x: (width - itemWidth) / 2 - CGFloat(selectedLevel.rawValue) * itemWidth)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: selectedLevel)
            .gesture(
                DragGesture(minimumDistance: 15)
                    .onEnded { value in
                        let threshold: CGFloat = 30
                        if value.translation.width < -threshold {
                            advanceLevel()
                        } else if value.translation.width > threshold {
                            retreatLevel()
                        }
                    }
            )
        }
        .frame(height: 58)
    }

    // MARK: - Barra / Slider Tátil de Arrastar com os Dedos

    private var interactiveSliderTrack: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let thumbRadius: CGFloat = 16
            let totalSteps = CGFloat(levels.count - 1)
            let stepSpacing = (trackWidth - (thumbRadius * 2)) / totalSteps

            let activePosition = CGFloat(selectedLevel.rawValue) * stepSpacing + thumbRadius
            let currentThumbX = dragCurrentX ?? activePosition

            ZStack(alignment: .leading) {
                // Trilho Base
                Capsule()
                    .fill(trackBaseColor)
                    .frame(height: 12)
                    .overlay(
                        Capsule()
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : accentColor.opacity(0.12), lineWidth: 1)
                    )

                // Trilho Preenchido Ativo (Progress Fill)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "38BDF8"), accentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(thumbRadius * 2, currentThumbX), height: 12)

                // Marcadores dos 5 Passos (Dots no Trilho)
                HStack(spacing: 0) {
                    ForEach(levels) { level in
                        let levelX = CGFloat(level.rawValue) * stepSpacing + thumbRadius
                        let isPast = level.rawValue <= selectedLevel.rawValue

                        Circle()
                            .fill(
                                isPast
                                    ? Color.white
                                    : (colorScheme == .dark ? Color.white.opacity(0.20) : accentColor.opacity(0.25))
                            )
                            .frame(width: 6, height: 6)
                            .position(x: levelX, y: 18)
                    }
                }
                .frame(height: 36)

                // Botão / Thumb Deslizante de Arrastar
                Circle()
                    .fill(thumbColor)
                    .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                    .overlay(
                        Circle()
                            .stroke(accentColor, lineWidth: 2.5)
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.45) : accentColor.opacity(0.35),
                        radius: isDragging ? 10 : 6,
                        y: 2
                    )
                    .scaleEffect(isDragging ? 1.18 : 1.0)
                    .position(x: currentThumbX, y: 18)
                    .animation(.spring(response: 0.32, dampingFraction: 0.75), value: currentThumbX)
            }
            .frame(height: 36)
            .contentShape(Rectangle())
            // Gesto de toque e arrasto contínuo com os dedos
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let touchX = min(max(value.location.x, thumbRadius), trackWidth - thumbRadius)
                        dragCurrentX = touchX

                        let fraction = (touchX - thumbRadius) / (trackWidth - (thumbRadius * 2))
                        let rawIndex = Int(round(fraction * totalSteps))
                        let clampedIndex = min(max(rawIndex, 0), levels.count - 1)

                        if let newLevel = VenusCheckInMoodLevel(rawValue: clampedIndex), newLevel != selectedLevel {
                            selectedLevel = newLevel
                            UISelectionFeedbackGenerator().selectionChanged()
                            onLevelChanged?(newLevel)
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            let touchX = min(max(value.location.x, thumbRadius), trackWidth - thumbRadius)
                            let fraction = (touchX - thumbRadius) / (trackWidth - (thumbRadius * 2))
                            let rawIndex = Int(round(fraction * totalSteps))
                            let clampedIndex = min(max(rawIndex, 0), levels.count - 1)

                            if let newLevel = VenusCheckInMoodLevel(rawValue: clampedIndex) {
                                selectedLevel = newLevel
                                UISelectionFeedbackGenerator().selectionChanged()
                                onLevelChanged?(newLevel)
                            }
                            dragCurrentX = nil
                        }
                    }
            )
        }
        .frame(height: 38)
    }

    // MARK: - Ações Auxiliares

    private func selectLevel(_ level: VenusCheckInMoodLevel) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            selectedLevel = level
            UISelectionFeedbackGenerator().selectionChanged()
            onLevelChanged?(level)
        }
    }

    private func advanceLevel() {
        if selectedLevel.rawValue < levels.count - 1,
           let next = VenusCheckInMoodLevel(rawValue: selectedLevel.rawValue + 1) {
            selectLevel(next)
        }
    }

    private func retreatLevel() {
        if selectedLevel.rawValue > 0,
           let prev = VenusCheckInMoodLevel(rawValue: selectedLevel.rawValue - 1) {
            selectLevel(prev)
        }
    }
}
