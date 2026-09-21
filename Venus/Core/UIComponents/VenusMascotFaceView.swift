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
    @State private var pupilGazeOffset: CGSize = .zero
    @State private var floatingZzz = false
    @State private var mouthPulse = false
    
    // Scale proportions relative to 100pt base
    private var scale: CGFloat { size / 100.0 }
    
    private var activeExpression: VenusMascotExpression {
        if state == .thinking || isThinking { return .thinking }
        if state == .celebrating { return .celebrating }
        if state == .sleeping { return .tired }
        if state == .listening { return .listening }
        if state == .empathetic { return .calm }
        return expression
    }

    var body: some View {
        ZStack {
            // Cheeks (Blush)
            if shouldShowBlush {
                HStack(spacing: 38 * scale) {
                    Circle()
                        .fill(blushColor)
                        .frame(width: 14 * scale, height: 10 * scale)
                        .blur(radius: 2 * scale)
                    
                    Circle()
                        .fill(blushColor)
                        .frame(width: 14 * scale, height: 10 * scale)
                        .blur(radius: 2 * scale)
                }
                .offset(y: 8 * scale)
            }
            
            // Eyes
            HStack(spacing: 24 * scale) {
                leftEye
                rightEye
            }
            .offset(y: eyeVerticalOffset)
            
            // Mouth
            mouthView
                .offset(y: mouthVerticalOffset)
            
            // Extra details (Sleep Zzz or Orbiting Stars)
            if state == .sleeping || activeExpression == .tired {
                sleepingZzzView
            }
        }
        .frame(width: size * 0.7, height: size * 0.5)
        .onAppear {
            startBlinkingLoop()
            if state == .speaking {
                withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                    mouthPulse = true
                }
            }
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
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
        if isBlinking && state != .sleeping && activeExpression != .tired {
            // Blinking / Closed line
            Capsule()
                .fill(faceColor)
                .frame(width: 12 * scale, height: 2.5 * scale)
        } else {
            switch activeExpression {
            case .happy, .celebrating:
                // Happy curved crescent eyes (^ ^)
                HappyEyeShape()
                    .stroke(faceColor, style: StrokeStyle(lineWidth: 3.2 * scale, lineCap: .round, lineJoin: .round))
                    .frame(width: 13 * scale, height: 8 * scale)
                
            case .calm:
                // Calm serene eyes (relaxed downward gentle arc or soft dot)
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 8.5 * scale, height: 8.5 * scale)
                    
                    // Specular glint
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 3 * scale, height: 3 * scale)
                        .offset(x: -1.5 * scale, y: -1.5 * scale)
                }
                
            case .energetic:
                // Big sparkling eyes with sparkle glint
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 11 * scale, height: 11 * scale)
                    
                    // Specular stars
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4 * scale, height: 4 * scale)
                        .offset(x: isRight ? -2 * scale : 1.5 * scale, y: -2 * scale)
                    
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 2 * scale, height: 2 * scale)
                        .offset(x: isRight ? 2 * scale : -2 * scale, y: 2 * scale)
                }
                
            case .thinking:
                // Eyes looking up & slightly right
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 9 * scale, height: 9 * scale)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3.5 * scale, height: 3.5 * scale)
                        .offset(x: 1.5 * scale, y: -2 * scale)
                }
                .offset(x: 2 * scale, y: -3 * scale)
                
            case .sad:
                // Empathetic, gently tilted curved eyes
                SadEyeShape(isRight: isRight)
                    .stroke(faceColor, style: StrokeStyle(lineWidth: 2.8 * scale, lineCap: .round))
                    .frame(width: 11 * scale, height: 6 * scale)
                
            case .stressed:
                // Open concerned dot eyes
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 7.5 * scale, height: 7.5 * scale)
                    
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2.5 * scale, height: 2.5 * scale)
                        .offset(x: -1 * scale, y: -1 * scale)
                }
                
            case .tired:
                // Sleeping horizontal line / calm shut eyes
                Capsule()
                    .fill(faceColor)
                    .frame(width: 12 * scale, height: 2.6 * scale)
                
            case .listening:
                // Wide attentive curious eyes
                ZStack {
                    Circle()
                        .fill(faceColor)
                        .frame(width: 9.5 * scale, height: 9.5 * scale)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3.5 * scale, height: 3.5 * scale)
                        .offset(x: -1 * scale, y: -1.5 * scale)
                }
            }
        }
    }
    
    // MARK: - Mouth View
    
    @ViewBuilder
    private var mouthView: some View {
        switch activeExpression {
        case .happy, .celebrating:
            // Cute open smile
            HappyMouthShape()
                .fill(faceColor)
                .frame(width: 10 * scale, height: 5.5 * scale)
                .scaleEffect(mouthPulse ? 1.15 : 1.0)
            
        case .calm:
            // Gentle serene curve
            SereneSmileShape()
                .stroke(faceColor, style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))
                .frame(width: 8 * scale, height: 4 * scale)
            
        case .energetic:
            // Wide happy mouth
            HappyMouthShape()
                .fill(faceColor)
                .frame(width: 12 * scale, height: 7 * scale)
            
        case .thinking:
            // Small curious "o" or soft line
            Circle()
                .stroke(faceColor, lineWidth: 2 * scale)
                .frame(width: 4.5 * scale, height: 4.5 * scale)
                .offset(x: 1.5 * scale)
            
        case .sad:
            // Reassuring soft small line
            SereneSmileShape()
                .stroke(faceColor.opacity(0.85), style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
                .frame(width: 6 * scale, height: 3 * scale)
            
        case .stressed:
            // Neutral wavy little line
            Capsule()
                .fill(faceColor)
                .frame(width: 6 * scale, height: 2 * scale)
            
        case .tired:
            // Tiny peaceful dot/smile
            SereneSmileShape()
                .stroke(faceColor.opacity(0.7), style: StrokeStyle(lineWidth: 1.8 * scale, lineCap: .round))
                .frame(width: 5 * scale, height: 2.5 * scale)
            
        case .listening:
            // Curious open small mouth
            Capsule()
                .fill(faceColor)
                .frame(width: 5 * scale, height: (mouthPulse ? 5 : 3) * scale)
        }
    }
    
    // MARK: - Auxiliary Views
    
    private var sleepingZzzView: some View {
        VStack(spacing: 2) {
            Text("z")
                .font(.system(size: 8 * scale, weight: .bold, design: .rounded))
            Text("Z")
                .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
        }
        .foregroundColor(faceColor.opacity(0.75))
        .offset(x: 28 * scale, y: floatingZzz ? -20 * scale : -14 * scale)
        .opacity(floatingZzz ? 0.9 : 0.4)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                floatingZzz = true
            }
        }
    }
    
    // MARK: - Helpers & Positions
    
    private var shouldShowBlush: Bool {
        activeExpression == .happy || activeExpression == .celebrating || activeExpression == .energetic
    }
    
    private var blushColor: Color {
        Color.pink.opacity(0.28)
    }
    
    private var eyeVerticalOffset: CGFloat {
        switch activeExpression {
        case .thinking: return -5 * scale
        default: return -3 * scale
        }
    }
    
    private var mouthVerticalOffset: CGFloat {
        switch activeExpression {
        case .happy, .celebrating, .energetic: return 9 * scale
        case .thinking: return 8 * scale
        default: return 7 * scale
        }
    }
    
    private func startBlinkingLoop() {
        blinkTask?.cancel()
        blinkTask = Task { @MainActor in
            while !Task.isCancelled {
                // Random blink every 3.2 to 5.8 seconds
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

// MARK: - Previews

#Preview("Venus Expressions") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            VenusMascotFaceView(expression: .happy, state: .idle, size: 80)
            VenusMascotFaceView(expression: .calm, state: .idle, size: 80)
            VenusMascotFaceView(expression: .energetic, state: .idle, size: 80)
        }
        HStack(spacing: 20) {
            VenusMascotFaceView(expression: .thinking, state: .thinking, size: 80)
            VenusMascotFaceView(expression: .sad, state: .idle, size: 80)
            VenusMascotFaceView(expression: .tired, state: .sleeping, size: 80)
        }
    }
    .padding(40)
    .background(Color(hex: "9BF66F"))
}
