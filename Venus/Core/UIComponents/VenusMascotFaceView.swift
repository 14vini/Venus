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
    case thinking
    case listening
    case speaking
    case celebrating
    case sleeping
    case empathetic
    case petting
    case yawning
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
    
    @State private var isBlinking = false
    @State private var blinkTask: Task<Void, Never>? = nil
    @State private var saccadeOffset: CGSize = .zero
    @State private var saccadeTask: Task<Void, Never>? = nil
    @State private var floatingZzz = false
    @State private var mouthPulse = false
    
    // Scale proportions relative to 100pt base
    private var scale: CGFloat { size / 100.0 }
    
    private var activeExpression: VenusMascotExpression {
        if state == .petting { return .petting }
        if state == .yawning { return .yawning }
        if state == .thinking || isThinking { return .thinking }
        if state == .celebrating { return .celebrating }
        if state == .sleeping { return .tired }
        if state == .listening { return .listening }
        if state == .empathetic { return .calm }
        return expression
    }

    var body: some View {
        ZStack {
            // Cheeks (Soft Airbrushed Blush with Starlight Glints)
            if shouldShowBlush {
                HStack(spacing: 36 * scale) {
                    blushCheekView(isRight: false)
                    blushCheekView(isRight: true)
                }
                .offset(y: 8.5 * scale)
            }
            
            // Eyes
            HStack(spacing: 24 * scale) {
                leftEye
                rightEye
            }
            .offset(x: saccadeOffset.width, y: eyeVerticalOffset + saccadeOffset.height)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: saccadeOffset)
            
            // Mouth
            mouthView
                .offset(y: mouthVerticalOffset)
            
            // Sleep Zzz Micro-particles
            if state == .sleeping || activeExpression == .tired {
                sleepingZzzView
            }
        }
        .frame(width: size * 0.74, height: size * 0.52)
        .onAppear {
            startBlinkingLoop()
            startSaccadeLoop()
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
    
    // MARK: - Blush View
    
    private func blushCheekView(isRight: Bool) -> some View {
        ZStack {
            // Soft atmospheric airbrush glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (activeExpression == .petting ? Color(hex: "FF477E") : Color(hex: "FF6B8B")).opacity(activeExpression == .petting ? 0.65 : 0.40),
                            (activeExpression == .petting ? Color(hex: "FF8E53") : Color(hex: "FFA8E8")).opacity(0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: (activeExpression == .petting ? 12 : 9) * scale
                    )
                )
                .frame(width: (activeExpression == .petting ? 22 : 17) * scale, height: (activeExpression == .petting ? 16 : 12) * scale)
            
            // Micro sparkle in cheek when happy
            if activeExpression == .happy || activeExpression == .petting || activeExpression == .celebrating {
                Image(systemName: "sparkle")
                    .font(.system(size: (activeExpression == .petting ? 5.5 : 4.0) * scale, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.85))
                    .offset(x: isRight ? 1.5 * scale : -1.5 * scale, y: -1 * scale)
            }
        }
    }
    
    // MARK: - Eyes Views
    
    @ViewBuilder
    private var leftEye: some View {
        eyeShape(isRight: false)
    }
    
    @ViewBuilder
    private var rightEye: some View {
        eyeShape(isRight: true)
    }
    
    @ViewBuilder
    private func eyeShape(isRight: Bool) -> some View {
        if isBlinking && state != .sleeping && activeExpression != .tired && activeExpression != .petting {
            // Blinking / Soft closed eyelash arc
            Capsule()
                .fill(faceColor)
                .frame(width: 13 * scale, height: 3.0 * scale)
        } else {
            switch activeExpression {
            case .happy, .celebrating, .petting:
                // Joyful anime curved crescent eyes (^ ^)
                HappyEyeShape()
                    .stroke(
                        faceColor,
                        style: StrokeStyle(
                            lineWidth: (activeExpression == .petting ? 3.8 : 3.4) * scale,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 14 * scale, height: 8.5 * scale)
                
            case .calm:
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
                
            case .energetic:
                // Sparkling Star Eyes
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 12.5 * scale, height: 12.5 * scale)
                    
                    // Primary large star shine
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5.0 * scale, height: 5.0 * scale)
                        .offset(x: isRight ? -2.2 * scale : 2.0 * scale, y: -2.4 * scale)
                    
                    // Secondary star glint
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2.6 * scale, height: 2.6 * scale)
                        .offset(x: isRight ? 2.4 * scale : -2.4 * scale, y: 2.4 * scale)
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
                        .frame(width: 11.5 * scale, height: 11.5 * scale)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4.6 * scale, height: 4.6 * scale)
                        .offset(x: -1.4 * scale, y: -2.0 * scale)
                    
                    Circle()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: 2.0 * scale, height: 2.0 * scale)
                        .offset(x: 2.0 * scale, y: 2.0 * scale)
                }
            }
        }
    }
    
    // MARK: - Mouth View
    
    @ViewBuilder
    private var mouthView: some View {
        switch activeExpression {
        case .happy, .celebrating, .petting:
            // Cute open smile with rounded tongue glow
            HappyMouthShape()
                .fill(faceColor)
                .frame(width: 11.5 * scale, height: 6.5 * scale)
                .scaleEffect(mouthPulse ? 1.15 : 1.0)
            
        case .calm:
            // Gentle serene curve
            SereneSmileShape()
                .stroke(faceColor, style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round))
                .frame(width: 8.5 * scale, height: 4.5 * scale)
            
        case .energetic:
            // Wide happy open mouth
            HappyMouthShape()
                .fill(faceColor)
                .frame(width: 13 * scale, height: 7.5 * scale)
            
        case .thinking:
            // Small curious "o"
            Circle()
                .stroke(faceColor, lineWidth: 2.2 * scale)
                .frame(width: 5.0 * scale, height: 5.0 * scale)
                .offset(x: 1.5 * scale)
            
        case .sad:
            // Reassuring soft small line
            SereneSmileShape()
                .stroke(faceColor.opacity(0.85), style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))
                .frame(width: 7 * scale, height: 3.5 * scale)
            
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
        activeExpression == .happy || activeExpression == .celebrating || activeExpression == .energetic || activeExpression == .petting
    }
    
    private var eyeVerticalOffset: CGFloat {
        switch activeExpression {
        case .thinking: return -4.5 * scale
        default: return -2.5 * scale
        }
    }
    
    private var mouthVerticalOffset: CGFloat {
        switch activeExpression {
        case .happy, .celebrating, .energetic, .petting: return 9.5 * scale
        case .thinking: return 8.5 * scale
        case .yawning: return 9.5 * scale
        default: return 7.5 * scale
        }
    }
    
    private func startBlinkingLoop() {
        blinkTask?.cancel()
        blinkTask = Task { @MainActor in
            while !Task.isCancelled {
                let delay = Double.random(in: 3.2...5.8)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { break }
                
                withAnimation(.easeInOut(duration: 0.12)) {
                    isBlinking = true
                }
                try? await Task.sleep(nanoseconds: 140_000_000)
                guard !Task.isCancelled else { break }
                
                withAnimation(.easeInOut(duration: 0.12)) {
                    isBlinking = false
                }
            }
        }
    }
    
    private func startSaccadeLoop() {
        saccadeTask?.cancel()
        saccadeTask = Task { @MainActor in
            while !Task.isCancelled {
                let delay = Double.random(in: 4.0...7.5)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { break }
                
                guard state == .idle || state == .listening else { continue }
                
                let randomX = CGFloat.random(in: -2.2...2.2) * scale
                let randomY = CGFloat.random(in: -1.0...1.0) * scale
                saccadeOffset = CGSize(width: randomX, height: randomY)
                
                try? await Task.sleep(nanoseconds: 1_500_000_000)
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
