//
//  VenusMascotFaceView.swift
//  Venus
//
//  Created by Kaua on 20/09/26.
//

import SwiftUI

// MARK: - Mascot State & Expression Enums

enum VenusMascotState: String, CaseIterable, Sendable {
    case idle
    case welcoming
    case thinking
    case listening
    case speaking
    case celebrating
    case sleeping
    case empathetic
    case petting
    case yawning
    case curious
    case excited

    // MARK: Novas reações (aditivas — os casos acima permanecem intactos)
    case amused
    case surprised
    case proud
    case shy
    case grateful
    case excitedSoft
    case concerned
    case loving
    case wink
    case sleepyHappy
    case determined
    case sparkling

    /// Expressão que acompanha os novos estados de reação. Nenhum estado
    /// original é alterado: `nil` mantém o comportamento anterior.
    var reactionExpression: VenusMascotExpression? {
        switch self {
        case .amused: return .amused
        case .surprised: return .surprised
        case .proud: return .proud
        case .shy: return .shy
        case .grateful: return .grateful
        case .excitedSoft: return .excitedSoft
        case .concerned: return .concerned
        case .loving: return .loving
        case .wink: return .wink
        case .sleepyHappy: return .sleepyHappy
        case .determined: return .determined
        case .sparkling: return .sparkling
        default: return nil
        }
    }
}

enum VenusMascotExpression: String, CaseIterable, Sendable {
    case happy
    case calm
    case energetic
    case stressed
    case sad
    case tired
    case thinking
    case celebrating
    case listening
    case petting
    case yawning
    case curious
    case welcoming
    case empathetic
    case excited

    // MARK: Novas expressões (aditivas — os casos acima permanecem intactos)
    case amused
    case surprised
    case proud
    case shy
    case grateful
    case excitedSoft
    case concerned
    case loving
    case wink
    case sleepyHappy
    case determined
    case sparkling
    
    init(from mood: MoodType?) {
        guard let mood else {
            self = .calm
            return
        }
        switch mood {
        case .happy: self = .happy
        case .calm: self = .calm
        case .energetic: self = .energetic
        case .stressed: self = .stressed
        case .sad: self = .sad
        case .tired: self = .tired
        }
    }
}

// MARK: - Venus Mascot Face View

struct VenusMascotFaceView: View {
    let expression: VenusMascotExpression
    let state: VenusMascotState
    var faceColor: Color = Color(hex: "27603F")
    var size: CGFloat = 100
    var isThinking: Bool = false
    var gazeOffset: CGSize = .zero
    
    @State private var isBlinking = false
    @State private var blinkScaleY: CGFloat = 1.0
    @State private var blinkTask: Task<Void, Never>? = nil
    @State private var saccadeOffset: CGSize = .zero
    @State private var saccadeTask: Task<Void, Never>? = nil
    @State private var floatingZzz = false
    @State private var mouthPulse = false
    @State private var curiousTilt: Double = 0
    @State private var browBob = false

    @Environment(\.colorScheme) private var colorScheme
    
    // Scale proportions relative to 100pt base
    private var scale: CGFloat { size / 100.0 }
    
    private var activeExpression: VenusMascotExpression {
        if state == .petting { return .petting }
        if state == .yawning { return .yawning }
        if state == .welcoming { return .welcoming }
        if state == .curious { return .curious }
        if state == .excited { return .excited }
        if state == .thinking || isThinking { return .thinking }
        if state == .celebrating { return .celebrating }
        if state == .sleeping { return .tired }
        if state == .listening { return .listening }
        if state == .empathetic { return .empathetic }
        if let reaction = state.reactionExpression { return reaction }
        return expression
    }

    // MARK: - Famílias visuais (novas expressões reaproveitam a identidade)

    /// Olhos em lua: felicidade serena, sem dentes e sem contorno duro.
    private var isMoonEyed: Bool {
        switch activeExpression {
        case .happy, .celebrating, .petting, .welcoming, .amused, .sleepyHappy, .wink:
            return true
        default:
            return false
        }
    }

    /// Olhos com estrelas para alegria intensa e descoberta.
    private var isStarEyed: Bool {
        switch activeExpression {
        case .energetic, .excited, .excitedSoft, .sparkling, .surprised:
            return true
        default:
            return false
        }
    }

    private var closedEyelash: some View {
        Capsule()
            .fill(faceColor)
            .frame(width: 13 * scale, height: 3.0 * scale)
    }

    var body: some View {
        ZStack {
            // Convex sheen across the face plane: a soft top light that makes
            // the features feel embedded in a rounded surface, not painted on.
            RadialGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.14 : 0.22),
                    Color.white.opacity(0.06),
                    Color.clear
                ],
                center: .init(x: 0.34, y: 0.16),
                startRadius: 0,
                endRadius: size * 0.42
            )
            .frame(width: size * 0.74, height: size * 0.52)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)

            // Eyebrows / Expressive micro-accents
            eyebrowsView
                .offset(
                    y: eyeVerticalOffset - 8 * scale
                        + ((activeExpression == .surprised || activeExpression == .amused) ? (browBob ? -1.6 * scale : 0) : 0)
                )
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: activeExpression)
            
            // Cheeks (Soft Airbrushed Blush with Starlight Glints)
            if shouldShowBlush {
                HStack(spacing: 36 * scale) {
                    blushCheekView(isRight: false)
                    blushCheekView(isRight: true)
                }
                .offset(y: 8.5 * scale)
            }
            
            // Eyes with dynamic gaze tracking & saccades
            HStack(spacing: 24 * scale) {
                leftEye
                rightEye
            }
            .offset(
                x: saccadeOffset.width + gazeOffset.width * 0.15,
                y: eyeVerticalOffset + saccadeOffset.height + gazeOffset.height * 0.15
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: saccadeOffset)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: gazeOffset)
            
            // Mouth
            mouthView
                .offset(
                    x: gazeOffset.width * 0.06,
                    y: mouthVerticalOffset + gazeOffset.height * 0.06
                )
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: activeExpression)
            
            // Sleep Zzz Micro-particles
            if state == .sleeping || activeExpression == .tired {
                sleepingZzzView
            }
        }
        .frame(width: size * 0.74, height: size * 0.52)
        // Cross-fade com mola na troca de expressão: leve recuo, rotação e
        // opacidade que retornam ao repouso. Blink/saccade/float continuam
        // em camadas próprias — nenhuma animação é duplicada aqui.
        .phaseAnimator([false, true], trigger: activeExpression.rawValue) { content, phase in
            content
                .opacity(phase ? 1.0 : 0.42)
                .scaleEffect(phase ? 1.0 : 0.94)
                .rotationEffect(.degrees(phase ? 0 : -3.5))
        } animation: { _ in
            .spring(response: 0.42, dampingFraction: 0.8)
        }
        .onAppear {
            startBlinkingLoop()
            startSaccadeLoop()
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                browBob = true
            }
            if state == .speaking {
                withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                    mouthPulse = true
                }
            }
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
            saccadeTask?.cancel()
            saccadeTask = nil
        }
        .onChange(of: state) { _, newState in
            if newState == .speaking {
                withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                    mouthPulse = true
                }
            } else {
                mouthPulse = false
            }
        }
    }
    
    // MARK: - Eyebrows View
    
    @ViewBuilder
    private var eyebrowsView: some View {
        switch activeExpression {
        case .curious:
            HStack(spacing: 26 * scale) {
                // Left eyebrow raised, right neutral
                Capsule()
                    .fill(faceColor.opacity(0.75))
                    .frame(width: 8 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(-15))
                    .offset(y: -2 * scale)
                
                Capsule()
                    .fill(faceColor.opacity(0.75))
                    .frame(width: 8 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(5))
            }
            
        case .empathetic:
            HStack(spacing: 26 * scale) {
                // Caring gentle slanted brows
                Capsule()
                    .fill(faceColor.opacity(0.70))
                    .frame(width: 7.5 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(12))
                
                Capsule()
                    .fill(faceColor.opacity(0.70))
                    .frame(width: 7.5 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(-12))
            }
            
        case .excited, .celebrating, .sparkling, .excitedSoft:
            HStack(spacing: 28 * scale) {
                Capsule()
                    .fill(faceColor.opacity(0.85))
                    .frame(width: 8 * scale, height: 2.0 * scale)
                    .rotationEffect(.degrees(-8))
                    .offset(y: -1.5 * scale)
                
                Capsule()
                    .fill(faceColor.opacity(0.85))
                    .frame(width: 8 * scale, height: 2.0 * scale)
                    .rotationEffect(.degrees(8))
                    .offset(y: -1.5 * scale)
            }

        case .surprised:
            // Sobrancelhas erguidas — espanto doce, nunca tenso.
            HStack(spacing: 28 * scale) {
                Capsule()
                    .fill(faceColor.opacity(0.80))
                    .frame(width: 8 * scale, height: 2.0 * scale)
                    .rotationEffect(.degrees(-6))
                    .offset(y: -4 * scale)

                Capsule()
                    .fill(faceColor.opacity(0.80))
                    .frame(width: 8 * scale, height: 2.0 * scale)
                    .rotationEffect(.degrees(6))
                    .offset(y: -4 * scale)
            }

        case .amused, .wink:
            // Uma sobrancelha levanta: cumplicidade e piscadela.
            HStack(spacing: 27 * scale) {
                Capsule()
                    .fill(faceColor.opacity(0.78))
                    .frame(width: 8 * scale, height: 1.9 * scale)
                    .rotationEffect(.degrees(-14))
                    .offset(y: -2.6 * scale)

                Capsule()
                    .fill(faceColor.opacity(0.70))
                    .frame(width: 7.5 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(4))
            }

        case .proud, .determined:
            // Arco confiante, levemente inclinado para dentro.
            HStack(spacing: 27 * scale) {
                Capsule()
                    .fill(faceColor.opacity(0.82))
                    .frame(width: 8 * scale, height: 2.0 * scale)
                    .rotationEffect(.degrees(9))
                    .offset(y: 0.5 * scale)

                Capsule()
                    .fill(faceColor.opacity(0.82))
                    .frame(width: 8 * scale, height: 2.0 * scale)
                    .rotationEffect(.degrees(-9))
                    .offset(y: 0.5 * scale)
            }

        case .concerned, .shy:
            HStack(spacing: 26 * scale) {
                Capsule()
                    .fill(faceColor.opacity(0.70))
                    .frame(width: 7.5 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(-12))

                Capsule()
                    .fill(faceColor.opacity(0.70))
                    .frame(width: 7.5 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(12))
            }

        case .loving, .grateful:
            HStack(spacing: 26 * scale) {
                Capsule()
                    .fill(faceColor.opacity(0.72))
                    .frame(width: 8 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(8))
                    .offset(y: -1 * scale)

                Capsule()
                    .fill(faceColor.opacity(0.72))
                    .frame(width: 8 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(-8))
                    .offset(y: -1 * scale)
            }

        case .sleepyHappy:
            HStack(spacing: 26 * scale) {
                Capsule()
                    .fill(faceColor.opacity(0.55))
                    .frame(width: 7 * scale, height: 1.6 * scale)
                    .rotationEffect(.degrees(10))

                Capsule()
                    .fill(faceColor.opacity(0.55))
                    .frame(width: 7 * scale, height: 1.6 * scale)
                    .rotationEffect(.degrees(-10))
            }
            
        case .thinking:
            HStack(spacing: 26 * scale) {
                Capsule()
                    .fill(faceColor.opacity(0.75))
                    .frame(width: 7.5 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(-10))
                
                Capsule()
                    .fill(faceColor.opacity(0.75))
                    .frame(width: 7.5 * scale, height: 1.8 * scale)
                    .rotationEffect(.degrees(-18))
                    .offset(y: -2 * scale)
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Blush View
    
    private func blushCheekView(isRight: Bool) -> some View {
        let isIntense = activeExpression == .petting || activeExpression == .welcoming
            || activeExpression == .excited || activeExpression == .loving
            || activeExpression == .shy || activeExpression == .grateful
        
        return ZStack {
            // Soft atmospheric airbrush glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (isIntense ? Color(hex: "FF477E") : Color(hex: "FF6B8B")).opacity(isIntense ? 0.68 : 0.42),
                            (isIntense ? Color(hex: "FF8E53") : Color(hex: "FFA8E8")).opacity(0.20),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: (isIntense ? 13 : 9.5) * scale
                    )
                )
                .frame(width: (isIntense ? 23 : 18) * scale, height: (isIntense ? 17 : 13) * scale)
            
            // Micro sparkle in cheek when happy / celebrating / welcoming
            if isMoonEyed || isStarEyed || activeExpression == .empathetic
                || activeExpression == .grateful || activeExpression == .loving {
                Image(systemName: "sparkle")
                    .font(.system(size: (isIntense ? 5.5 : 4.0) * scale, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.90))
                    .offset(x: isRight ? 1.5 * scale : -1.5 * scale, y: -1 * scale)
            }
        }
    }
    
    // MARK: - Eyes Views

    /// Extra reflections that make round pupils read as glossy glass instead
    /// of flat dots. Sized from the existing per-expression scale factor.
    private func specularGlints(isRight: Bool, radius: CGFloat) -> some View {
        // A highlight belongs to the light source, not to the pupil. Drifting
        // it slightly against the existing saccade/gaze gives the navy eyes
        // depth without adding a second animation loop.
        let lightShift = CGSize(
            width: -(saccadeOffset.width + gazeOffset.width * 0.15) * 0.35,
            height: -(saccadeOffset.height + gazeOffset.height * 0.15) * 0.25
        )

        return ZStack {
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: radius * 0.95, height: radius * 0.95)
                .offset(x: (isRight ? -1 : 1) * radius * 0.34, y: -radius * 0.36)
                .blur(radius: max(0.5, 0.6 * scale))

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: max(0.8, 1.1 * scale), height: max(0.8, 1.1 * scale))
                .offset(x: (isRight ? 1 : -1) * radius * 0.30, y: radius * 0.34)
        }
        .offset(x: lightShift.width, y: lightShift.height)
    }

    /// A whisper of light along the lower lid makes the round eyes read as wet
    /// glass. Same palette, same geometry — only an inner reflection.
    @ViewBuilder
    private func lowerLidCatchlight(isRight: Bool) -> some View {
        if hasLowerLidCatchlight {
            Capsule()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.20))
                .frame(width: max(2, 4.2 * scale), height: max(0.6, 0.9 * scale))
                .offset(x: isRight ? 0.6 * scale : -0.6 * scale, y: -1.2 * scale)
                .blur(radius: max(0.3, 0.4 * scale))
        }
    }

    private var hasLowerLidCatchlight: Bool {
        switch activeExpression {
        case .calm, .energetic, .excited, .curious, .empathetic, .thinking, .sad, .stressed, .listening,
             .proud, .determined, .grateful, .shy, .concerned, .surprised, .loving, .sleepyHappy, .amused:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private var leftEye: some View {
        eyeShape(isRight: false)
            .overlay(lowerLidCatchlight(isRight: false))
            .scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
    
    @ViewBuilder
    private var rightEye: some View {
        eyeShape(isRight: true)
            .overlay(lowerLidCatchlight(isRight: true))
            .scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }
    
    @ViewBuilder
    private func eyeShape(isRight: Bool) -> some View {
        if isBlinking && state != .sleeping && activeExpression != .tired && activeExpression != .petting {
            closedEyelash
        } else if activeExpression == .wink && isRight {
            // Piscadela: um olho fecha enquanto o outro continua brilhando.
            closedEyelash
        } else {
            switch activeExpression {
            case .loving:
                // Olhos em coração — reação de carinho, sem texto.
                HeartEyeShape()
                    .fill(faceColor)
                    .frame(width: 13 * scale, height: 12 * scale)
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: max(0.8, 2.4 * scale), height: max(0.8, 2.4 * scale))
                            .offset(x: isRight ? 3.0 * scale : -3.0 * scale, y: -3.4 * scale)
                    )

            case .happy, .celebrating, .petting, .welcoming, .amused, .sleepyHappy, .wink:
                // Olhos em lua: mesma identidade azul-marinho, mais doçura.
                MoonEyeShape(isRight: isRight)
                    .fill(faceColor)
                    .frame(width: 15 * scale, height: 9.5 * scale)
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.55))
                            .frame(width: max(0.8, 1.4 * scale), height: max(0.8, 1.4 * scale))
                            .offset(x: isRight ? 3.8 * scale : -3.8 * scale, y: -2.8 * scale)
                    )
                
            case .calm, .proud, .determined:
                // Premium Anime/Game Eye with Dual Glossy Specular Dome
                ZStack {
                    // Pupil with vertical depth
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    faceColor,
                                    faceColor.opacity(0.88)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 10.5 * scale, height: 10.5 * scale)
                    
                    // Primary glossy specular highlight (top left)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4.2 * scale, height: 4.2 * scale)
                        .offset(x: -2.0 * scale, y: -2.0 * scale)
                    
                    // Secondary micro-sparkle reflection (bottom right)
                    Circle()
                        .fill(Color.white.opacity(0.80))
                        .frame(width: 1.8 * scale, height: 1.8 * scale)
                        .offset(x: 2.2 * scale, y: 2.2 * scale)
                }
                .overlay(specularGlints(isRight: isRight, radius: 10.5 * scale))
                .offset(y: activeExpression == .proud ? -0.8 * scale : 0)
                
            case .energetic, .excited, .excitedSoft, .sparkling, .surprised:
                // Sparkling Star Eyes
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 13.0 * scale, height: 13.0 * scale)
                    
                    // Primary large star shine
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5.4 * scale, height: 5.4 * scale)
                        .offset(x: isRight ? -2.2 * scale : 2.0 * scale, y: -2.4 * scale)
                    
                    // Secondary star glint
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 2.8 * scale, height: 2.8 * scale)
                        .offset(x: isRight ? 2.6 * scale : -2.6 * scale, y: 2.6 * scale)
                }
                .scaleEffect(activeExpression == .surprised ? 1.10 : 1.0)
                
            case .curious:
                // Big curious eyes looking with interest
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [faceColor, faceColor.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 12.0 * scale, height: 12.0 * scale)
                    
                    // Main curiosity gleam
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5.0 * scale, height: 5.0 * scale)
                        .offset(x: -1.0 * scale, y: -2.4 * scale)
                    
                    // Sub-gleam
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 2.2 * scale, height: 2.2 * scale)
                        .offset(x: 2.2 * scale, y: 1.8 * scale)
                }
                .offset(y: 1.0 * scale)
                
            case .empathetic, .grateful, .shy, .concerned:
                // Empathetic gentle shining eyes
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 10.5 * scale, height: 10.5 * scale)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4.4 * scale, height: 4.4 * scale)
                        .offset(x: -1.6 * scale, y: -1.6 * scale)
                    
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 2.0 * scale, height: 2.0 * scale)
                        .offset(x: 1.8 * scale, y: 1.8 * scale)
                }
                
            case .thinking:
                // Curious eyes looking up to the side
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 10.5 * scale, height: 10.5 * scale)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4.4 * scale, height: 4.4 * scale)
                        .offset(x: 2.0 * scale, y: -2.4 * scale)
                    
                    Circle()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: 1.8 * scale, height: 1.8 * scale)
                        .offset(x: -2.0 * scale, y: 2.0 * scale)
                }
                .overlay(specularGlints(isRight: isRight, radius: 10.5 * scale))
                .offset(x: 2.2 * scale, y: -3.2 * scale)
                
            case .sad:
                // Empathetic, gently tilted curved eyes
                SadEyeShape(isRight: isRight)
                    .stroke(faceColor, style: StrokeStyle(lineWidth: 3.0 * scale, lineCap: .round))
                    .frame(width: 12 * scale, height: 6.5 * scale)
                
            case .stressed:
                // Open concerned dot eyes with glint
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 8.5 * scale, height: 8.5 * scale)
                    
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 3.0 * scale, height: 3.0 * scale)
                        .offset(x: -1.2 * scale, y: -1.2 * scale)
                }
                
            case .tired, .yawning:
                // Sleeping horizontal line / calm shut eyes
                Capsule()
                    .fill(faceColor)
                    .frame(width: 13 * scale, height: 2.8 * scale)
                
            case .listening:
                // Wide attentive curious eyes
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 11.8 * scale, height: 11.8 * scale)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4.8 * scale, height: 4.8 * scale)
                        .offset(x: -1.4 * scale, y: -2.0 * scale)
                    
                    Circle()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: 2.0 * scale, height: 2.0 * scale)
                        .offset(x: 2.0 * scale, y: 2.0 * scale)
                }
                .overlay(specularGlints(isRight: isRight, radius: 11.8 * scale))
            }
        }
    }
    
    // MARK: - Mouth View
    
    @ViewBuilder
    private var mouthView: some View {
        switch activeExpression {
        case .happy, .celebrating, .petting, .welcoming, .excited, .sparkling, .wink:
            // Cute open smile with rounded tongue glow
            HappyMouthShape()
                .fill(faceColor)
                .frame(width: (activeExpression == .excited ? 13 : 11.5) * scale, height: (activeExpression == .excited ? 7.5 : 6.5) * scale)
                .scaleEffect(mouthPulse ? 1.15 : 1.0)

        case .excitedSoft:
            // Alegria contida: mesmo sorriso, um pouco menor.
            HappyMouthShape()
                .fill(faceColor)
                .frame(width: 10.5 * scale, height: 5.8 * scale)
                .scaleEffect(mouthPulse ? 1.10 : 1.0)
            
        case .calm, .empathetic, .grateful, .loving, .sleepyHappy:
            // Gentle serene curve
            SereneSmileShape()
                .stroke(faceColor, style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round))
                .frame(width: 8.5 * scale, height: 4.5 * scale)

        case .shy, .proud, .amused:
            // Sorriso assimétrico e gentil — curvatura que conversa com a emoção.
            SmirkMouthShape()
                .stroke(faceColor, style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))
                .frame(width: 8 * scale, height: 4.2 * scale)
            
        case .energetic:
            // Wide happy open mouth
            HappyMouthShape()
                .fill(faceColor)
                .frame(width: 13 * scale, height: 7.5 * scale)

        case .determined:
            // Linha curta e firme, sem dureza de contorno.
            Capsule()
                .fill(faceColor.opacity(0.9))
                .frame(width: 7.5 * scale, height: 2.2 * scale)
            
        case .curious:
            // Cute soft small "o"
            Circle()
                .stroke(faceColor, lineWidth: 2.2 * scale)
                .frame(width: 4.6 * scale, height: 4.6 * scale)

        case .surprised:
            // "o" um pouco maior: espanto doce, sem texto.
            Circle()
                .stroke(faceColor, lineWidth: 2.3 * scale)
                .frame(width: 6.2 * scale, height: 6.2 * scale)
            
        case .thinking:
            // Small curious "o" shifted
            Circle()
                .stroke(faceColor, lineWidth: 2.2 * scale)
                .frame(width: 5.0 * scale, height: 5.0 * scale)
                .offset(x: 1.5 * scale)
            
        case .sad:
            // Reassuring soft small line
            SereneSmileShape()
                .stroke(faceColor.opacity(0.85), style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))
                .frame(width: 7 * scale, height: 3.5 * scale)

        case .concerned:
            // Leve curva descendente: cuidado sem peso.
            ConcernedMouthShape()
                .stroke(faceColor.opacity(0.85), style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))
                .frame(width: 7.5 * scale, height: 3.8 * scale)
            
        case .stressed:
            // Neutral wavy little line
            Capsule()
                .fill(faceColor)
                .frame(width: 7 * scale, height: 2.2 * scale)
            
        case .tired:
            // Tiny peaceful dot/smile
            SereneSmileShape()
                .stroke(faceColor.opacity(0.7), style: StrokeStyle(lineWidth: 2.0 * scale, lineCap: .round))
                .frame(width: 5.5 * scale, height: 2.8 * scale)
            
        case .yawning:
            // Big open round yawning mouth
            Ellipse()
                .fill(faceColor)
                .frame(width: 7.5 * scale, height: 10 * scale)
            
        case .listening:
            // Curious open small mouth
            Capsule()
                .fill(faceColor)
                .frame(width: 5.5 * scale, height: (mouthPulse ? 5.5 : 3.5) * scale)
        }
    }
    
    // MARK: - Auxiliary Views
    
    private var sleepingZzzView: some View {
        VStack(spacing: 2) {
            Text("z")
                .font(.system(size: 9 * scale, weight: .bold, design: .rounded))
            Text("Z")
                .font(.system(size: 12 * scale, weight: .bold, design: .rounded))
        }
        .foregroundColor(faceColor.opacity(0.80))
        .offset(x: 28 * scale, y: floatingZzz ? -22 * scale : -15 * scale)
        .opacity(floatingZzz ? 0.95 : 0.4)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                floatingZzz = true
            }
        }
    }
    
    // MARK: - Helpers & Positions
    
    private var shouldShowBlush: Bool {
        activeExpression == .happy || activeExpression == .celebrating || activeExpression == .energetic
            || activeExpression == .petting || activeExpression == .welcoming || activeExpression == .excited
            || activeExpression == .empathetic || activeExpression == .loving || activeExpression == .shy
            || activeExpression == .grateful || activeExpression == .amused || activeExpression == .sleepyHappy
            || activeExpression == .wink || activeExpression == .proud
    }
    
    private var eyeVerticalOffset: CGFloat {
        switch activeExpression {
        case .thinking: return -4.5 * scale
        case .curious: return -1.5 * scale
        case .surprised: return -1.0 * scale
        case .sleepyHappy: return 0.5 * scale
        default: return -2.5 * scale
        }
    }
    
    private var mouthVerticalOffset: CGFloat {
        switch activeExpression {
        case .happy, .celebrating, .energetic, .petting, .welcoming, .excited,
             .excitedSoft, .sparkling, .wink, .loving, .grateful: return 9.5 * scale
        case .thinking: return 8.5 * scale
        case .yawning: return 9.5 * scale
        case .curious: return 8.5 * scale
        case .surprised: return 9.0 * scale
        default: return 7.5 * scale
        }
    }
    
    private func startBlinkingLoop() {
        blinkTask?.cancel()
        blinkTask = Task { @MainActor in
            while !Task.isCancelled {
                let delay = Double.random(in: 2.8...5.2)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { break }

                // A piscadela e o sorriso sonolento já fecham um olho:
                // não competem com um blink duplo.
                if activeExpression == .wink || activeExpression == .sleepyHappy { continue }
                
                withAnimation(.spring(response: 0.10, dampingFraction: 0.8)) {
                    isBlinking = true
                }
                try? await Task.sleep(nanoseconds: 120_000_000)
                guard !Task.isCancelled else { break }
                
                withAnimation(.spring(response: 0.12, dampingFraction: 0.75)) {
                    isBlinking = false
                }
                
                // 25% chance of charming double-blink
                if Double.random(in: 0...1) < 0.25 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    guard !Task.isCancelled else { break }
                    withAnimation(.spring(response: 0.09, dampingFraction: 0.8)) {
                        isBlinking = true
                    }
                    try? await Task.sleep(nanoseconds: 110_000_000)
                    guard !Task.isCancelled else { break }
                    withAnimation(.spring(response: 0.12, dampingFraction: 0.75)) {
                        isBlinking = false
                    }
                }
            }
        }
    }
    
    private func startSaccadeLoop() {
        saccadeTask?.cancel()
        saccadeTask = Task { @MainActor in
            while !Task.isCancelled {
                let delay = Double.random(in: 3.5...6.5)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { break }
                
                guard state == .idle || state == .listening || state == .welcoming || state == .empathetic
                    || state == .proud || state == .grateful || state == .loving || state == .determined
                    || state == .amused else { continue }
                
                let randomX = CGFloat.random(in: -2.2...2.2) * scale
                let randomY = CGFloat.random(in: -1.0...1.0) * scale
                saccadeOffset = CGSize(width: randomX, height: randomY)
                
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                guard !Task.isCancelled else { break }
                saccadeOffset = .zero
            }
        }
    }
}

// MARK: - Custom Vector Shapes

struct HappyEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.4)
        )
        return path
    }
}

struct SadEyeShape: Shape {
    let isRight: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isRight {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + 2))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: rect.midX, y: rect.minY)
            )
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + 2),
                control: CGPoint(x: rect.midX, y: rect.minY)
            )
        }
        return path
    }
}

struct HappyMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 1.5)
        )
        path.closeSubpath()
        return path
    }
}

struct SereneSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + 1),
            control: CGPoint(x: rect.midX, y: rect.maxY * 1.3)
        )
        return path
    }
}

// MARK: - New Expressive Shapes

/// Olho em lua cheia inclinada: um arco externo amplo e um interno mais
/// raso criam a lua sem contorno duro. Preenchido com o azul-marinho da Venus.
struct MoonEyeShape: Shape {
    let isRight: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tilt: CGFloat = isRight ? 0.6 : -0.6
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - tilt))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY + tilt),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.22)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - tilt),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.48)
        )
        path.closeSubpath()
        return path
    }
}

/// Coração simplificado, usado apenas nos olhos da expressão `.loving`.
struct HeartEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + h * 0.42),
            control1: CGPoint(x: rect.minX - w * 0.08, y: rect.minY + h * 0.62),
            control2: CGPoint(x: rect.minX - w * 0.02, y: rect.minY + h * 0.06)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + h * 0.30),
            control1: CGPoint(x: rect.minX + w * 0.16, y: rect.minY - h * 0.06),
            control2: CGPoint(x: rect.midX - w * 0.08, y: rect.minY - h * 0.04)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - w * 0.02, y: rect.minY + h * 0.42),
            control1: CGPoint(x: rect.midX + w * 0.08, y: rect.minY - h * 0.04),
            control2: CGPoint(x: rect.maxX - w * 0.16, y: rect.minY - h * 0.06)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX + w * 0.02, y: rect.minY + h * 0.06),
            control2: CGPoint(x: rect.maxX + w * 0.08, y: rect.minY + h * 0.62)
        )
        path.closeSubpath()
        return path
    }
}

/// Sorriso levemente assimétrico para travessura, orgulho e timidez.
struct SmirkMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + 2.5),
            control: CGPoint(x: rect.midX, y: rect.maxY * 1.2)
        )
        return path
    }
}

/// Curva suavemente descendente para cuidado — sem traço duro.
struct ConcernedMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 2.5))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + 1),
            control: CGPoint(x: rect.midX, y: rect.maxY * 0.9)
        )
        return path
    }
}
