//
//  VenusMascot3DCute.swift
//  Venus
//
//  Created by Kaua on 27/03/26.
//

import AVFoundation
import SceneKit
import SwiftUI
import UIKit

struct VenusMascot3DCute: View {
    var mood: MoodType? = nil
    var size: CGFloat = 220

    @State private var bubbleText: String? = nil
    @State private var bubbleVisible: Bool = false
    @State private var bubbleNonce: Int = 0

    private var tint: Color {
        Color(hex: (mood?.orbColors.mid ?? "9BF66F"))
    }

    var body: some View {
        ZStack(alignment: .top) {
            VenusMascot3DCuteSceneView(mood: mood) { phrase in
                presentBubble(phrase)
            }
            .frame(width: size, height: size)

            if bubbleVisible, let bubbleText {
                VenusFloatingHintBubble(
                    title: bubbleText,
                    bodyText: "",
                    systemImage: "sparkles",
                    tint: tint,
                    maxWidth: 240
                )
                .padding(.top, 6)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mascote da Venus")
        .accessibilityHint("Toque para reagir")
    }

    private func presentBubble(_ text: String) {
        bubbleNonce += 1
        let currentNonce = bubbleNonce
        bubbleText = text

        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            bubbleVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard currentNonce == bubbleNonce else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                bubbleVisible = false
            }
        }
    }
}

private struct VenusMascot3DCuteSceneView: UIViewRepresentable {
    var mood: MoodType?
    var onPhrase: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPhrase: onPhrase)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.rendersContinuously = true
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false

        let scene = VenusMascot3DCuteSceneFactory.makeScene(mood: mood)
        view.scene = scene
        view.pointOfView = VenusMascot3DCuteSceneFactory.makeCameraNode()

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.onPhrase = onPhrase
    }

    final class Coordinator: NSObject {
        weak var view: SCNView?
        var onPhrase: (String) -> Void

        private let synthesizer = AVSpeechSynthesizer()
        private var lastTap = Date.distantPast

        private weak var mascot: SCNNode?
        private weak var leftEye: SCNNode?
        private weak var rightEye: SCNNode?
        private weak var aura: SCNNode?
        private weak var halo: SCNNode?
        private weak var gem: SCNNode?

        init(onPhrase: @escaping (String) -> Void) {
            self.onPhrase = onPhrase
        }

        func attach(to view: SCNView) {
            self.view = view
            cacheNodes()
        }

        private func cacheNodes() {
            guard let root = view?.scene?.rootNode else { return }
            mascot = root.childNode(withName: "mascot.cute", recursively: true)
            leftEye = root.childNode(withName: "mascot.eye.left", recursively: true)
            rightEye = root.childNode(withName: "mascot.eye.right", recursively: true)
            aura = root.childNode(withName: "mascot.aura", recursively: true)
            halo = root.childNode(withName: "mascot.halo", recursively: true)
            gem = root.childNode(withName: "mascot.gem", recursively: true)
        }

        @objc func handleTap() {
            let now = Date()
            guard now.timeIntervalSince(lastTap) > 0.55 else { return }
            lastTap = now

            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            let phrase = "Prove it!"
            onPhrase(phrase)
            speak(phrase)
            animateTap()
        }

        private func speak(_ text: String) {
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }

            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.46
            utterance.pitchMultiplier = 1.20
            utterance.volume = 0.92
            synthesizer.speak(utterance)
        }

        private func animateTap() {
            let squash = SCNAction.scale(to: 0.94, duration: 0.08)
            squash.timingMode = .easeInEaseOut
            let stretch = SCNAction.scale(to: 1.06, duration: 0.14)
            stretch.timingMode = .easeInEaseOut
            let settle = SCNAction.scale(to: 1.0, duration: 0.18)
            settle.timingMode = .easeInEaseOut

            let bob = SCNAction.sequence([squash, stretch, settle])
            mascot?.removeAction(forKey: "tap")
            mascot?.runAction(bob, forKey: "tap")

            if let aura {
                aura.removeAction(forKey: "tap")
                aura.runAction(.sequence([
                    .fadeOpacity(to: 0.42, duration: 0.08),
                    .fadeOpacity(to: 0.18, duration: 0.22)
                ]), forKey: "tap")
            }

            if let halo {
                halo.removeAction(forKey: "tap")
                halo.runAction(.sequence([
                    .scale(to: 1.08, duration: 0.10),
                    .scale(to: 1.0, duration: 0.22)
                ]), forKey: "tap")
            }

            if let gem {
                gem.removeAction(forKey: "tap")
                gem.runAction(.sequence([
                    .scale(to: 1.14, duration: 0.10),
                    .rotateBy(x: 0, y: CGFloat(Double.pi), z: 0, duration: 0.18),
                    .scale(to: 1.0, duration: 0.16)
                ]), forKey: "tap")
            }

            if let leftEye {
                blink(eye: leftEye, wink: true)
            }
            if let rightEye {
                blink(eye: rightEye, wink: false)
            }
        }

        private func blink(eye: SCNNode, wink: Bool) {
            let downDuration: TimeInterval = wink ? 0.06 : 0.07
            let upDuration: TimeInterval = wink ? 0.11 : 0.09

            let blinkDown = SCNAction.customAction(duration: downDuration) { node, elapsed in
                let progress = Float(elapsed / downDuration)
                let y = max(0.14, 1.0 - progress * 0.86)
                node.scale = SCNVector3(1.0, y, 1.0)
            }
            let blinkUp = SCNAction.customAction(duration: upDuration) { node, elapsed in
                let progress = Float(elapsed / upDuration)
                let y = 0.14 + progress * 0.86
                node.scale = SCNVector3(1.0, y, 1.0)
            }

            eye.runAction(.sequence([blinkDown, blinkUp]))
        }
    }
}

private enum VenusMascot3DCuteSceneFactory {
    static func makeCameraNode() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 32
        camera.wantsHDR = true

        let node = SCNNode()
        node.camera = camera
        node.position = SCNVector3(0, 0.2, 6.4)
        return node
    }

    static func makeScene(mood: MoodType?) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let highlight = UIColor(Color(hex: (mood?.orbColors.light ?? "D6FFB9")))
        let base = UIColor(Color(hex: (mood?.orbColors.mid ?? "9BF66F")))
        let deep = UIColor(Color(hex: (mood?.orbColors.deep ?? "59D85A")))

        scene.lightingEnvironment.contents = makeEnvironmentMap(highlight: highlight, base: base, deep: deep)
        scene.lightingEnvironment.intensity = 1.35

        let root = scene.rootNode
        root.addChildNode(makeAmbientLight())
        root.addChildNode(makeKeyLight())
        root.addChildNode(makeFillLight())
        root.addChildNode(makeRimLight())

        let mascot = makeMascotNode(highlight: highlight, base: base, deep: deep, faceInk: UIColor(Color(hex: (mood?.faceColorHex ?? "27603F"))))
        root.addChildNode(mascot)

        return scene
    }

    private static func makeAmbientLight() -> SCNNode {
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 560
        light.color = UIColor(white: 1, alpha: 1)

        let node = SCNNode()
        node.light = light
        return node
    }

    private static func makeKeyLight() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1400
        light.attenuationStartDistance = 7
        light.attenuationEndDistance = 18
        light.color = UIColor(white: 1, alpha: 1)

        let node = SCNNode()
        node.light = light
        node.position = SCNVector3(2.1, 2.2, 5.8)
        return node
    }

    private static func makeFillLight() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 760
        light.attenuationStartDistance = 7
        light.attenuationEndDistance = 18
        light.color = UIColor(white: 0.96, alpha: 1)

        let node = SCNNode()
        node.light = light
        node.position = SCNVector3(-2.8, -1.1, 7.0)
        return node
    }

    private static func makeRimLight() -> SCNNode {
        let light = SCNLight()
        light.type = .directional
        light.intensity = 880
        light.color = UIColor(white: 1, alpha: 1)

        let node = SCNNode()
        node.light = light
        node.eulerAngles = SCNVector3(Float(-34.0 * .pi / 180.0), Float(46.0 * .pi / 180.0), 0)
        return node
    }

    private static func makeMascotNode(highlight: UIColor, base: UIColor, deep: UIColor, faceInk: UIColor) -> SCNNode {
        let container = SCNNode()
        container.name = "mascot.cute"

        // Core body
        let coreSphere = SCNSphere(radius: 1.22)
        coreSphere.segmentCount = 112
        let core = SCNNode(geometry: coreSphere)
        core.geometry?.materials = [makeCoreMaterial(highlight: highlight, base: base, deep: deep)]
        core.position = SCNVector3(0, -0.05, 0)
        core.scale = SCNVector3(1.0, 0.96, 1.0)
        container.addChildNode(core)

        // Glass shell
        let shellSphere = SCNSphere(radius: 1.34)
        shellSphere.segmentCount = 112
        let shell = SCNNode(geometry: shellSphere)
        shell.geometry?.materials = [makeGlassShellMaterial(tint: highlight)]
        shell.position = SCNVector3(0, -0.05, 0)
        container.addChildNode(shell)

        // Aura
        let auraSphere = SCNSphere(radius: 1.58)
        auraSphere.segmentCount = 72
        let aura = SCNNode(geometry: auraSphere)
        aura.name = "mascot.aura"
        aura.geometry?.materials = [makeAuraMaterial(tint: base)]
        aura.opacity = 0.18
        aura.position = SCNVector3(0, -0.05, 0)
        container.addChildNode(aura)

        // Ears (cute nubs)
        let earSphere = SCNSphere(radius: 0.28)
        earSphere.segmentCount = 64

        let leftEar = SCNNode(geometry: earSphere)
        leftEar.geometry?.materials = [makeCoreMaterial(highlight: highlight, base: base, deep: deep)]
        leftEar.position = SCNVector3(-0.72, 0.98, 0.12)
        container.addChildNode(leftEar)

        let rightEar = SCNNode(geometry: earSphere)
        rightEar.geometry?.materials = [makeCoreMaterial(highlight: highlight, base: base, deep: deep)]
        rightEar.position = SCNVector3(0.72, 0.98, 0.12)
        container.addChildNode(rightEar)

        // Arms (stubby)
        let armCapsule = SCNCapsule(capRadius: 0.18, height: 0.9)
        let leftArm = SCNNode(geometry: armCapsule)
        leftArm.geometry?.materials = [makeCoreMaterial(highlight: highlight, base: base, deep: deep)]
        leftArm.position = SCNVector3(-1.22, -0.22, 0.1)
        leftArm.eulerAngles = SCNVector3(0.0, 0.0, Float(-38.0 * .pi / 180.0))
        container.addChildNode(leftArm)

        let rightArm = SCNNode(geometry: armCapsule)
        rightArm.geometry?.materials = [makeCoreMaterial(highlight: highlight, base: base, deep: deep)]
        rightArm.position = SCNVector3(1.22, -0.22, 0.1)
        rightArm.eulerAngles = SCNVector3(0.0, 0.0, Float(38.0 * .pi / 180.0))
        container.addChildNode(rightArm)

        // AI halo ring
        let haloTorus = SCNTorus(ringRadius: 1.45, pipeRadius: 0.035)
        let halo = SCNNode(geometry: haloTorus)
        halo.name = "mascot.halo"
        halo.geometry?.materials = [makeHaloMaterial(tint: highlight)]
        halo.position = SCNVector3(0.0, 0.22, 0.0)
        halo.eulerAngles = SCNVector3(Float(18.0 * .pi / 180.0), 0, Float(10.0 * .pi / 180.0))
        container.addChildNode(halo)

        // Face
        let eyeGeometry = SCNSphere(radius: 0.22)
        eyeGeometry.segmentCount = 72

        let leftEye = SCNNode(geometry: eyeGeometry)
        leftEye.name = "mascot.eye.left"
        leftEye.geometry?.materials = [makeEyeMaterial(ink: faceInk)]
        leftEye.position = SCNVector3(-0.42, 0.14, 1.1)
        container.addChildNode(leftEye)

        let rightEye = SCNNode(geometry: eyeGeometry)
        rightEye.name = "mascot.eye.right"
        rightEye.geometry?.materials = [makeEyeMaterial(ink: faceInk)]
        rightEye.position = SCNVector3(0.42, 0.14, 1.1)
        container.addChildNode(rightEye)

        // Eye highlights
        let sparkle = SCNSphere(radius: 0.07)
        sparkle.segmentCount = 32
        let sparkleMaterial = makeSparkleMaterial()

        let leftSpark = SCNNode(geometry: sparkle)
        leftSpark.geometry?.materials = [sparkleMaterial]
        leftSpark.position = SCNVector3(-0.47, 0.23, 1.28)
        container.addChildNode(leftSpark)

        let rightSpark = SCNNode(geometry: sparkle)
        rightSpark.geometry?.materials = [sparkleMaterial]
        rightSpark.position = SCNVector3(0.37, 0.22, 1.28)
        container.addChildNode(rightSpark)

        // Cheeks
        let blush = SCNSphere(radius: 0.14)
        blush.segmentCount = 48
        let blushMaterial = makeBlushMaterial()

        let leftBlush = SCNNode(geometry: blush)
        leftBlush.geometry?.materials = [blushMaterial]
        leftBlush.position = SCNVector3(-0.78, -0.02, 1.02)
        container.addChildNode(leftBlush)

        let rightBlush = SCNNode(geometry: blush)
        rightBlush.geometry?.materials = [blushMaterial]
        rightBlush.position = SCNVector3(0.78, -0.02, 1.02)
        container.addChildNode(rightBlush)

        let mouth = SCNNode(geometry: SCNTorus(ringRadius: 0.24, pipeRadius: 0.05))
        mouth.geometry?.materials = [makeInkMaterial(color: faceInk.withAlphaComponent(0.92))]
        mouth.position = SCNVector3(0.0, -0.30, 1.1)
        mouth.eulerAngles = SCNVector3(Float(90.0 * .pi / 180.0), 0.0, 0.0)
        mouth.scale = SCNVector3(1.0, 0.6, 1.0)
        container.addChildNode(mouth)

        // Floating prism gem
        let gem = SCNNode(geometry: SCNBox(width: 0.58, height: 0.58, length: 0.58, chamferRadius: 0.14))
        gem.name = "mascot.gem"
        gem.geometry?.materials = [makeGemMaterial(tint: base)]
        gem.position = SCNVector3(0.0, 1.75, 0.25)
        gem.eulerAngles = SCNVector3(Float(18.0 * .pi / 180.0), Float(26.0 * .pi / 180.0), Float(12.0 * .pi / 180.0))
        container.addChildNode(gem)

        // Idle animations
        let bob = SCNAction.sequence([
            .moveBy(x: 0, y: 0.10, z: 0, duration: 1.75),
            .moveBy(x: 0, y: -0.10, z: 0, duration: 1.75)
        ])
        container.runAction(.repeatForever(bob))

        let haloSpin = SCNAction.repeatForever(.rotateBy(x: 0, y: CGFloat(2 * Double.pi), z: 0, duration: 8.0))
        halo.runAction(haloSpin)

        let gemSpin = SCNAction.repeatForever(.rotateBy(x: 0, y: CGFloat(2 * Double.pi), z: 0, duration: 10.0))
        gem.runAction(gemSpin)

        return container
    }

    private static func makeCoreMaterial(highlight: UIColor, base: UIColor, deep: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = makeVerticalGradientImage(top: highlight, mid: base, bottom: deep)
        material.metalness.contents = 0.02
        material.roughness.contents = 0.28
        material.clearCoat.contents = 0.65
        material.clearCoatRoughness.contents = 0.14
        material.emission.contents = deep.withAlphaComponent(0.22)
        material.emission.intensity = 0.9
        material.specular.contents = UIColor(white: 1.0, alpha: 0.35)
        return material
    }

    private static func makeInkMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        material.metalness.contents = 0.0
        material.roughness.contents = 0.33
        return material
    }

    private static func makeEyeMaterial(ink: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = ink
        material.metalness.contents = 0.0
        material.roughness.contents = 0.06
        material.clearCoat.contents = 1.0
        material.clearCoatRoughness.contents = 0.05
        material.specular.contents = UIColor(white: 1.0, alpha: 0.65)
        return material
    }

    private static func makeGlassShellMaterial(tint: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = tint.withAlphaComponent(0.10)
        material.metalness.contents = 0.0
        material.roughness.contents = 0.05
        material.clearCoat.contents = 1.0
        material.clearCoatRoughness.contents = 0.07
        material.transparency = 0.36
        material.fresnelExponent = 2.2
        material.specular.contents = UIColor(white: 1.0, alpha: 0.9)
        material.blendMode = .alpha
        material.isDoubleSided = true
        return material
    }

    private static func makeAuraMaterial(tint: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor.clear
        material.emission.contents = tint.withAlphaComponent(0.22)
        material.emission.intensity = 1.2
        material.transparency = 0.18
        material.roughness.contents = 1.0
        material.blendMode = .add
        material.isDoubleSided = true
        return material
    }

    private static func makeHaloMaterial(tint: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = tint.withAlphaComponent(0.10)
        material.emission.contents = tint.withAlphaComponent(0.35)
        material.emission.intensity = 1.1
        material.metalness.contents = 0.0
        material.roughness.contents = 0.12
        material.transparency = 0.55
        material.blendMode = .alpha
        material.isDoubleSided = true
        return material
    }

    private static func makeSparkleMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(white: 1, alpha: 1)
        material.emission.contents = UIColor(white: 1, alpha: 1)
        material.emission.intensity = 1.2
        material.metalness.contents = 0.0
        material.roughness.contents = 0.05
        material.transparency = 0.85
        material.blendMode = .add
        return material
    }

    private static func makeBlushMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(red: 1.0, green: 0.45, blue: 0.62, alpha: 1)
        material.emission.contents = UIColor(red: 1.0, green: 0.40, blue: 0.60, alpha: 1)
        material.emission.intensity = 0.55
        material.metalness.contents = 0.0
        material.roughness.contents = 0.35
        material.transparency = 0.38
        material.blendMode = .alpha
        material.isDoubleSided = true
        return material
    }

    private static func makeGemMaterial(tint: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = tint.withAlphaComponent(0.30)
        material.emission.contents = tint.withAlphaComponent(0.26)
        material.emission.intensity = 0.9
        material.metalness.contents = 0.06
        material.roughness.contents = 0.10
        material.transparency = 0.82
        material.fresnelExponent = 2.2
        material.blendMode = .alpha
        material.isDoubleSided = true
        return material
    }

    private static func makeEnvironmentMap(highlight: UIColor, base: UIColor, deep: UIColor) -> UIImage {
        let size = CGSize(width: 512, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext

            let top = highlight.withAlphaComponent(0.55).cgColor
            let mid = base.withAlphaComponent(0.22).cgColor
            let bottom = deep.withAlphaComponent(0.12).cgColor

            let colors = [top, mid, bottom] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1])!
            cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])

            cg.setBlendMode(.screen)
            drawBlob(in: cg, center: CGPoint(x: size.width * 0.22, y: size.height * 0.28), radius: 180, color: UIColor(white: 1.0, alpha: 0.28))
            drawBlob(in: cg, center: CGPoint(x: size.width * 0.78, y: size.height * 0.22), radius: 160, color: highlight.withAlphaComponent(0.22))
            drawBlob(in: cg, center: CGPoint(x: size.width * 0.64, y: size.height * 0.74), radius: 220, color: UIColor(white: 0.95, alpha: 0.12))
        }
    }

    private static func drawBlob(in cg: CGContext, center: CGPoint, radius: CGFloat, color: UIColor) {
        let colors = [color.cgColor, UIColor.clear.cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        cg.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: [.drawsBeforeStartLocation]
        )
    }

    private static func makeVerticalGradientImage(top: UIColor, mid: UIColor, bottom: UIColor) -> UIImage {
        let size = CGSize(width: 8, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            let colors = [top.cgColor, mid.cgColor, bottom.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.45, 1])!
            cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        VenusMascot3DCute(mood: .happy, size: 240)
        VenusMascot3DCute(mood: .calm, size: 240)
    }
    .padding()
    .background(VenusTheme.backgroundGradient)
}
