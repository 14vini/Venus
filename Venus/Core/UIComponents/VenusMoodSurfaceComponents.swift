//
//  VenusMoodSurfaceComponents.swift
//  Venus
//
//  Created by Kaua on 24/03/26.
//

import SwiftUI

struct VenusGlassPill: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = VenusTheme.moodMintStrong

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
            }

            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.72 : 0.92)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.10 : 0.06))
                        .blendMode(.overlay)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.14 : 0.22),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .blendMode(.overlay)
                )
        )
    }
}

struct VenusFloatingHintBubble: View {
    let title: String
    var bodyText: String = ""
    var systemImage: String? = nil
    var tint: Color = VenusTheme.moodMintStrong
    var maxWidth: CGFloat = 230

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let systemImage {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 30, height: 30)

                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(tint)
                }
            }

            VStack(alignment: .leading, spacing: bodyText.isEmpty ? 0 : 8) {
                Text(title)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                if !bodyText.isEmpty {
                    Text(bodyText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct VenusMoodWaveform: View {
    var tint: Color = VenusTheme.moodMintStrong
    var secondaryTint: Color = VenusTheme.moodMint
    var barHeights: [CGFloat] = [18, 24, 34, 48, 62, 76, 88, 76, 62, 48, 34, 24, 18]

    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                secondaryTint.opacity(0.1),
                                secondaryTint.opacity(0.34),
                                tint.opacity(index == barHeights.count / 2 ? 0.96 : 0.82)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 8, height: animate ? height : height * 0.9)
                    .opacity(animate ? 1 : 0.82)
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .frame(height: 88)
        .padding(.horizontal, 14)
        .onAppear {
            guard !animate else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Dynamic Ground Shadow

struct VenusGroundShadowView: View {
    let size: CGFloat
    let altitude: CGFloat
    let squishX: CGFloat
    let tint: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var normalizedAltitude: CGFloat {
        max(0, altitude / (size * 0.8))
    }
    
    private var shadowWidth: CGFloat {
        let base = size * 0.65 * squishX
        return max(base * 0.4, base * (1.0 - normalizedAltitude * 0.5))
    }
    
    private var shadowHeight: CGFloat {
        let base = size * 0.16
        return max(base * 0.35, base * (1.0 - normalizedAltitude * 0.55))
    }
    
    private var shadowOpacity: Double {
        let maxOpacity = colorScheme == .dark ? 0.45 : 0.22
        return max(0.08, maxOpacity * (1.0 - Double(normalizedAltitude) * 0.6))
    }

    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.black.opacity(shadowOpacity),
                        tint.opacity(shadowOpacity * 0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: shadowWidth * 0.5
                )
            )
            .frame(width: shadowWidth, height: shadowHeight)
            .blur(radius: max(2, 4 + normalizedAltitude * 8))
            .allowsHitTesting(false)
    }
}

// MARK: - Venus Mood Orb (2.5D Game Character)

struct VenusMoodOrb: View {
    var mood: MoodType? = nil
    var state: VenusMascotState = .idle
    var expression: VenusMascotExpression? = nil
    var cosmetic: VenusCosmeticItem = .none
    var size: CGFloat = 258
    var showFace: Bool = true
    var showHands: Bool = true
    var showShadow: Bool = true
    var isInteractive: Bool = true
    
    @State private var animate = false
    @State private var squishX: CGFloat = 1.0
    @State private var squishY: CGFloat = 1.0
    @State private var orbitAngle: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dangleAngle: Double = 0
    @State private var jumpOffset: CGFloat = 0
    @State private var flipRotation: Double = 0
    @State private var isPetting = false
    @State private var pettingStrokeCount = 0
    @State private var lastPettingX: CGFloat = 0
    @State private var activeParticles: [MascotParticleItem] = []
    @State private var internalState: VenusMascotState? = nil
    @State private var quirkTask: Task<Void, Never>? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var highlightColor: Color {
        guard let mood else { return Color(hex: "D6FFB9") }
        return Color(hex: mood.orbColors.light)
    }
    
    private var baseColor: Color {
        guard let mood else { return Color(hex: "9BF66F") }
        return Color(hex: mood.orbColors.mid)
    }
    
    private var deepColor: Color {
        guard let mood else { return Color(hex: "59D85A") }
        return Color(hex: mood.orbColors.deep)
    }
    
    private var faceColor: Color {
        if let mood {
            return Color(hex: mood.faceColorHex)
        }
        return Color(hex: "27603F")
    }
    
    private var effectiveState: VenusMascotState {
        if let internalState { return internalState }
        if isPetting { return .petting }
        return state
    }
    
    private var effectiveExpression: VenusMascotExpression {
        if isPetting { return .petting }
        if effectiveState == .yawning { return .yawning }
        if let expression { return expression }
        return VenusMascotExpression(from: mood)
    }
    
    private var handPose: VenusHandPose {
        if isPetting || effectiveExpression == .happy || effectiveExpression == .petting {
            return .coveringCheeks
        }
        switch effectiveState {
        case .thinking: return .thinking
        case .celebrating: return .waving
        case .sleeping: return .tucked
        default: return .floatingIdle
        }
    }
    
    private var currentAltitude: CGFloat {
        max(0, -dragOffset.height - jumpOffset)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Particles Layer (Hearts, Stars, Puffs)
                MascotParticleEmitterView(particles: activeParticles)
                
                // Outer Ambient Aura
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [baseColor.opacity(effectiveState == .listening ? 0.45 : 0.30), baseColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * (effectiveState == .listening ? 0.62 : 0.5)
                        )
                    )
                    .blur(radius: 12)
                    .scaleEffect(animate ? (effectiveState == .listening ? 1.15 : 1.08) : 0.94)
                
                // Cosmetics (Behind / Wings)
                if cosmetic == .astralWings {
                    VenusCosmeticAccessoryView(item: cosmetic, size: size * 0.76, mood: mood)
                }
                
                // Orbiting sparkles when thinking
                if effectiveState == .thinking {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [highlightColor.opacity(0.6), highlightColor.opacity(0.1), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: size * 0.92, height: size * 0.92)
                            .rotationEffect(.degrees(orbitAngle))
                        
                        Image(systemName: "sparkle")
                            .font(.system(size: max(8, size * 0.08), weight: .bold))
                            .foregroundColor(highlightColor)
                            .offset(x: size * 0.46)
                            .rotationEffect(.degrees(orbitAngle))
                        
                        Image(systemName: "sparkle")
                            .font(.system(size: max(6, size * 0.06), weight: .medium))
                            .foregroundColor(highlightColor.opacity(0.8))
                            .offset(x: -size * 0.46)
                            .rotationEffect(.degrees(orbitAngle))
                    }
                }
                
                // Main Volumetric Character Body (3D Jelly / Celestial Spirit)
                ZStack {
                    // Base sphere with rich color depth
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    highlightColor,
                                    baseColor,
                                    deepColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Internal radiant core glow (soul light)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.40),
                                    highlightColor.opacity(0.20),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.30
                            )
                        )
                    
                    // Bottom subsurface reflection (bounce light)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    highlightColor.opacity(0.35),
                                    Color.clear
                                ],
                                center: .bottom,
                                startRadius: 0,
                                endRadius: size * 0.35
                            )
                        )
                    
                    // Top-down glassy dome highlight (glossy candy/glass effect)
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    Color.white.opacity(0.10),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.54, height: size * 0.28)
                        .offset(x: -size * 0.05, y: -size * 0.22)
                        .blur(radius: max(1.0, size * 0.015))
                    
                    // Specular star glint on upper dome
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: max(4, size * 0.035), height: max(4, size * 0.035))
                        .offset(x: -size * 0.20, y: -size * 0.24)
                        .blur(radius: 0.5)
                    
                    // Fresnel Rim Lighting Stroke
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.65),
                                    highlightColor.opacity(0.40),
                                    Color.white.opacity(0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.2, size * 0.014)
                        )
                }
                .frame(width: size * 0.76, height: size * 0.76)
                .shadow(color: baseColor.opacity(0.40), radius: max(8, size * 0.08), x: 0, y: max(4, size * 0.04))
                .overlay(
                    Group {
                        if showFace {
                            VenusMascotFaceView(
                                expression: effectiveExpression,
                                state: effectiveState,
                                faceColor: faceColor,
                                size: size * 0.76
                            )
                        }
                    }
                )
                
                // Cute Forehead Starlight Crown (Floating secondary star on top)
                if effectiveState != .thinking && effectiveState != .sleeping && cosmetic == .none {
                    Image(systemName: "sparkle")
                        .font(.system(size: max(8, size * 0.065), weight: .bold))
                        .foregroundColor(Color.white.opacity(0.9))
                        .shadow(color: highlightColor.opacity(0.8), radius: 4)
                        .offset(y: -size * 0.40 + (animate ? -2 : 2))
                }
                
                // Hands / Paws Layer (Positioned on the flanks so they never cover the face)
                if showHands && effectiveState != .thinking {
                    VenusMascotHandsView(
                        pose: handPose,
                        tint: baseColor,
                        highlightTint: highlightColor,
                        size: size * 0.76
                    )
                }
                
                // Cosmetics (Foreground / Halo / Headphones / Cap / Saturn Ring)
                if cosmetic != .none && cosmetic != .astralWings {
                    VenusCosmeticAccessoryView(item: cosmetic, size: size * 0.76, mood: mood)
                }
            }
            .scaleEffect(x: squishX, y: squishY)
            .scaleEffect(animate ? (effectiveState == .sleeping ? 1.01 : 1.03) : 0.97)
            .rotationEffect(.degrees(dangleAngle + flipRotation))
            .offset(x: dragOffset.width, y: dragOffset.height + jumpOffset)
            .gesture(isInteractive ? dragGesture : nil)
            .onTapGesture(count: 2) {
                guard isInteractive else { return }
                triggerBackflip()
            }
            .onTapGesture(count: 1) {
                guard isInteractive else { return }
                triggerSquishBounce()
            }
            
            // Ground Shadow
            if showShadow {
                VenusGroundShadowView(
                    size: size,
                    altitude: currentAltitude,
                    squishX: squishX,
                    tint: baseColor
                )
                .offset(x: dragOffset.width * 0.2, y: -size * 0.04)
            }
        }
        .contentShape(Circle())
        .onAppear {
            withAnimation(.easeInOut(duration: effectiveState == .sleeping ? 3.5 : 2.5).repeatForever(autoreverses: true)) {
                animate = true
            }
            if effectiveState == .thinking {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    orbitAngle = 360
                }
            }
            startIdleQuirksLoop()
        }
        .onDisappear {
            quirkTask?.cancel()
            quirkTask = nil
        }
        .onChange(of: effectiveState) { _, newState in
            if newState == .thinking {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    orbitAngle = 360
                }
            }
        }
    }
    
    // MARK: - Gestures & Interactions
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .local)
            .onChanged { value in
                let translation = value.translation
                
                // Check if user is scrubbing back and forth near the top of the head (Petting)
                let isTopHead = value.location.y < size * 0.45
                let deltaX = abs(translation.width - lastPettingX)
                if isTopHead && deltaX > 6 {
                    pettingStrokeCount += 1
                    lastPettingX = translation.width
                    
                    if pettingStrokeCount > 3 && !isPetting {
                        isPetting = true
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        spawnPettingHearts()
                    }
                }
                
                if !isPetting {
                    // Dangle & drag physics
                    dragOffset = translation
                    dangleAngle = Double(min(22, max(-22, translation.width * 0.12)))
                    
                    let stretchY = max(0.92, 1.0 + abs(translation.height) * 0.001)
                    squishX = 2.0 - stretchY
                    squishY = stretchY
                }
            }
            .onEnded { value in
                if isPetting {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isPetting = false
                        pettingStrokeCount = 0
                        squishX = 1.0
                        squishY = 1.0
                    }
                } else {
                    let releaseAltitude = -dragOffset.height
                    let hadSignificantDrag = abs(dragOffset.width) > 20 || abs(dragOffset.height) > 20
                    
                    // Gravity fall & rebound
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.58)) {
                        dragOffset = .zero
                        dangleAngle = 0
                    }
                    
                    if hadSignificantDrag {
                        // Impact squash upon hitting ground
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if releaseAltitude > 30 {
                                spawnLandingPuff()
                            }
                            withAnimation(.spring(response: 0.16, dampingFraction: 0.45)) {
                                squishX = 1.20
                                squishY = 0.80
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.55)) {
                                    squishX = 1.0
                                    squishY = 1.0
                                }
                            }
                        }
                    } else {
                        squishX = 1.0
                        squishY = 1.0
                    }
                }
            }
    }
    
    private func triggerSquishBounce() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) {
            squishX = 1.14
            squishY = 0.86
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.52)) {
                squishX = 1.0
                squishY = 1.0
            }
        }
    }
    
    private func triggerBackflip() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        spawnSparkles()
        
        // Jump up + spin 360
        withAnimation(.easeOut(duration: 0.32)) {
            jumpOffset = -size * 0.36
            flipRotation = -180
            squishX = 0.88
            squishY = 1.14
        }
        
        // Land + complete 360
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(.easeIn(duration: 0.30)) {
                jumpOffset = 0
                flipRotation = -360
                squishX = 1.22
                squishY = 0.78
            }
            
            // Rebound to baseline
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                flipRotation = 0
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    squishX = 1.0
                    squishY = 1.0
                }
            }
        }
    }
    
    // MARK: - Particles
    
    private func spawnPettingHearts() {
        let newHearts = MascotParticleFactory.makePettingHearts(count: 5)
        activeParticles.append(contentsOf: newHearts)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            activeParticles.removeAll { p in newHearts.contains { $0.id == p.id } }
        }
    }
    
    private func spawnLandingPuff() {
        let puffs = MascotParticleFactory.makeLandingPuff(count: 6, baseline: size * 0.36)
        activeParticles.append(contentsOf: puffs)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            activeParticles.removeAll { p in puffs.contains { $0.id == p.id } }
        }
    }
    
    private func spawnSparkles() {
        let sparkles = MascotParticleFactory.makeSparkleBurst(count: 8)
        activeParticles.append(contentsOf: sparkles)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            activeParticles.removeAll { p in sparkles.contains { $0.id == p.id } }
        }
    }
    
    // MARK: - Idle Quirks Scheduler
    
    private func startIdleQuirksLoop() {
        guard isInteractive else { return }
        quirkTask?.cancel()
        quirkTask = Task { @MainActor in
            while !Task.isCancelled {
                let delay = Double.random(in: 12.0...18.0)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { break }
                guard !isPetting && dragOffset == .zero && state == .idle else { continue }
                
                // Random quirk: small happy hop or yawn
                let quirkRoll = Int.random(in: 0...2)
                if quirkRoll == 0 {
                    // Mini joyful hop
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) {
                        jumpOffset = -size * 0.12
                        squishX = 0.92
                        squishY = 1.10
                    }
                    try? await Task.sleep(nanoseconds: 240_000_000)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                        jumpOffset = 0
                        squishX = 1.0
                        squishY = 1.0
                    }
                } else if quirkRoll == 1 {
                    // Sleepy yawn
                    internalState = .yawning
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    internalState = nil
                }
            }
        }
    }
}
