//
//  VenusMascot3D.swift
//  Venus
//
//  Created by Kaua on 27/03/26.
//

import SceneKit
import SwiftUI
import UIKit

struct VenusMascot3D: View {
    var mood: MoodType? = nil
    var size: CGFloat = 220

    var body: some View {
        VenusSceneKitView(
            scene: VenusMascot3DSceneFactory.makeScene(mood: mood),
            pointOfView: VenusMascot3DSceneFactory.makeCameraNode()
        )
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct VenusSceneKitView: UIViewRepresentable {
    let scene: SCNScene
    let pointOfView: SCNNode

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.pointOfView = pointOfView
        view.backgroundColor = .clear
        view.isOpaque = false
        view.rendersContinuously = true
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = scene
        uiView.pointOfView = pointOfView
    }
}

private enum VenusMascot3DSceneFactory {
    static func makeCameraNode() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 34
        camera.wantsHDR = true

        let node = SCNNode()
        node.camera = camera
        node.position = SCNVector3(0, 0.25, 7.2)
        return node
    }

    static func makeScene(mood: MoodType?) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear
        scene.lightingEnvironment.contents = makeEnvironmentMap()
        scene.lightingEnvironment.intensity = 1.25

        let root = scene.rootNode

        root.addChildNode(makeAmbientLight())
        root.addChildNode(makeKeyLight())
        root.addChildNode(makeFillLight())
        root.addChildNode(makeRimLight())

        let mascot = makeMascotNode(mood: mood)
        root.addChildNode(mascot)

        return scene
    }

    private static func makeAmbientLight() -> SCNNode {
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 520
        light.color = UIColor(white: 1, alpha: 1)

        let node = SCNNode()
        node.light = light
        return node
    }

    private static func makeKeyLight() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1200
        light.attenuationStartDistance = 8
        light.attenuationEndDistance = 18
        light.color = UIColor(white: 1, alpha: 1)

        let node = SCNNode()
        node.light = light
        node.position = SCNVector3(2.2, 2.4, 6.0)
        return node
    }

    private static func makeFillLight() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 620
        light.attenuationStartDistance = 8
        light.attenuationEndDistance = 18
        light.color = UIColor(white: 0.95, alpha: 1)

        let node = SCNNode()
        node.light = light
        node.position = SCNVector3(-3.0, -1.4, 7.4)
        return node
    }

    private static func makeRimLight() -> SCNNode {
        let light = SCNLight()
        light.type = .directional
        light.intensity = 820
        light.color = UIColor(white: 1, alpha: 1)

        let node = SCNNode()
        node.light = light
        node.eulerAngles = SCNVector3(Float(-32.0 * .pi / 180.0), Float(42.0 * .pi / 180.0), 0)
        return node
    }

    private static func makeMascotNode(mood: MoodType?) -> SCNNode {
        let container = SCNNode()

        let highlightColor = UIColor(Color(hex: (mood?.orbColors.light ?? "D6FFB9")))
        let baseColor = UIColor(Color(hex: (mood?.orbColors.mid ?? "9BF66F")))
        let deepColor = UIColor(Color(hex: (mood?.orbColors.deep ?? "59D85A")))
        let faceInk = UIColor(Color(hex: (mood?.faceColorHex ?? "27603F")))

        // Inner core (emissive)
        let coreSphere = SCNSphere(radius: 1.35)
        coreSphere.segmentCount = 96
        let core = SCNNode(geometry: coreSphere)
        core.geometry?.materials = [makeCoreMaterial(base: baseColor, highlight: highlightColor, deep: deepColor)]
        core.position = SCNVector3(0, -0.05, 0)
        core.scale = SCNVector3(1.0, 0.98, 1.0)
        container.addChildNode(core)

        // Outer glass shell
        let shellSphere = SCNSphere(radius: 1.55)
        shellSphere.segmentCount = 96
        let shell = SCNNode(geometry: shellSphere)
        shell.geometry?.materials = [makeGlassShellMaterial(tint: highlightColor)]
        shell.position = SCNVector3(0, -0.05, 0)
        container.addChildNode(shell)

        // Subtle aura glow
        let auraSphere = SCNSphere(radius: 1.75)
        auraSphere.segmentCount = 64
        let aura = SCNNode(geometry: auraSphere)
        aura.geometry?.materials = [makeAuraMaterial(tint: baseColor)]
        aura.position = SCNVector3(0, -0.05, 0)
        container.addChildNode(aura)

        // Face (glossy eyes + smile)
        let leftEye = SCNNode(geometry: SCNSphere(radius: 0.16))
        leftEye.geometry?.materials = [makeEyeMaterial(ink: faceInk)]
        leftEye.position = SCNVector3(-0.48, 0.18, 1.28)
        container.addChildNode(leftEye)

        let rightEye = SCNNode(geometry: SCNSphere(radius: 0.16))
        rightEye.geometry?.materials = [makeEyeMaterial(ink: faceInk)]
        rightEye.position = SCNVector3(0.48, 0.18, 1.28)
        container.addChildNode(rightEye)

        let mouth = SCNNode(geometry: SCNTorus(ringRadius: 0.30, pipeRadius: 0.05))
        mouth.geometry?.materials = [makeInkMaterial(color: faceInk.withAlphaComponent(0.92))]
        mouth.position = SCNVector3(0.0, -0.22, 1.28)
        mouth.eulerAngles = SCNVector3(Float(90.0 * .pi / 180.0), 0.0, 0.0)
        mouth.scale = SCNVector3(1.0, 0.6, 1.0)
        container.addChildNode(mouth)

        // Crown ring + prism gem (glass)
        let crownTorus = SCNTorus(ringRadius: 1.02, pipeRadius: 0.06)
        let crown = SCNNode(geometry: crownTorus)
        crown.geometry?.materials = [makeGlassCrownMaterial(tint: highlightColor)]
        crown.position = SCNVector3(0.0, 1.15, 0.0)
        crown.eulerAngles = SCNVector3(Float(78.0 * .pi / 180.0), 0.0, 0.0)
        container.addChildNode(crown)

        let gem = SCNNode(geometry: SCNBox(width: 0.62, height: 0.62, length: 0.62, chamferRadius: 0.12))
        gem.geometry?.materials = [makeGemMaterial(tint: baseColor)]
        gem.position = SCNVector3(0.0, 1.95, 0.25)
        gem.eulerAngles = SCNVector3(Float(20.0 * .pi / 180.0), Float(28.0 * .pi / 180.0), Float(12.0 * .pi / 180.0))
        container.addChildNode(gem)

        // Animations
        let bob = SCNAction.sequence([
            .moveBy(x: 0, y: 0.12, z: 0, duration: 1.85),
            .moveBy(x: 0, y: -0.12, z: 0, duration: 1.85)
        ])
        container.runAction(.repeatForever(bob))

        let rotate = SCNAction.repeatForever(.rotateBy(x: 0, y: CGFloat(2 * Double.pi), z: 0, duration: 10.0))
        gem.runAction(rotate)

        let slowTurn = SCNAction.repeatForever(.rotateBy(x: 0, y: CGFloat(2 * Double.pi), z: 0, duration: 30.0))
        container.runAction(slowTurn)

        return container
    }

    private static func makeCoreMaterial(base: UIColor, highlight: UIColor, deep: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = makeVerticalGradientImage(top: highlight, mid: base, bottom: deep)
        material.metalness.contents = 0.02
        material.roughness.contents = 0.32
        material.clearCoat.contents = 0.55
        material.clearCoatRoughness.contents = 0.18
        material.emission.contents = deep.withAlphaComponent(0.26)
        material.emission.intensity = 0.9
        return material
    }

    private static func makeInkMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        material.metalness.contents = 0.0
        material.roughness.contents = 0.35
        return material
    }

    private static func makeEyeMaterial(ink: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = ink
        material.metalness.contents = 0.0
        material.roughness.contents = 0.08
        material.clearCoat.contents = 1.0
        material.clearCoatRoughness.contents = 0.06
        material.specular.contents = UIColor(white: 1.0, alpha: 0.55)
        return material
    }

    private static func makeGlassShellMaterial(tint: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = tint.withAlphaComponent(0.10)
        material.metalness.contents = 0.0
        material.roughness.contents = 0.06
        material.clearCoat.contents = 1.0
        material.clearCoatRoughness.contents = 0.08
        material.transparency = 0.35
        material.fresnelExponent = 2.2
        material.specular.contents = UIColor(white: 1.0, alpha: 0.85)
        material.blendMode = .alpha
        material.isDoubleSided = true
        return material
    }

    private static func makeGlassCrownMaterial(tint: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = tint.withAlphaComponent(0.16)
        material.emission.contents = tint.withAlphaComponent(0.18)
        material.emission.intensity = 0.6
        material.metalness.contents = 0.02
        material.roughness.contents = 0.10
        material.clearCoat.contents = 1.0
        material.clearCoatRoughness.contents = 0.12
        material.transparency = 0.5
        material.fresnelExponent = 2.4
        material.specular.contents = UIColor(white: 1.0, alpha: 0.85)
        material.blendMode = .alpha
        material.isDoubleSided = true
        return material
    }

    private static func makeAuraMaterial(tint: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor.clear
        material.emission.contents = tint.withAlphaComponent(0.18)
        material.emission.intensity = 1.1
        material.transparency = 0.18
        material.roughness.contents = 1.0
        material.blendMode = .add
        material.isDoubleSided = true
        return material
    }

    private static func makeGemMaterial(tint: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = tint.withAlphaComponent(0.32)
        material.emission.contents = tint.withAlphaComponent(0.22)
        material.metalness.contents = 0.08
        material.roughness.contents = 0.12
        material.transparency = 0.82
        material.fresnelExponent = 2.2
        material.blendMode = .alpha
        material.isDoubleSided = true
        return material
    }

    private static func makeEnvironmentMap() -> UIImage {
        let size = CGSize(width: 512, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            let colors = [
                UIColor(white: 0.12, alpha: 1).cgColor,
                UIColor(white: 0.04, alpha: 1).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])

            // Soft light blobs (fake HDR highlights)
            cg.setBlendMode(.screen)
            drawBlob(in: cg, center: CGPoint(x: size.width * 0.25, y: size.height * 0.32), radius: 170, color: UIColor(white: 1.0, alpha: 0.22))
            drawBlob(in: cg, center: CGPoint(x: size.width * 0.78, y: size.height * 0.18), radius: 140, color: UIColor(white: 1.0, alpha: 0.18))
            drawBlob(in: cg, center: CGPoint(x: size.width * 0.62, y: size.height * 0.70), radius: 220, color: UIColor(white: 0.85, alpha: 0.10))
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
        VenusMascot3D(mood: .happy, size: 220)
        VenusMascot3D(mood: .calm, size: 220)
    }
    .padding()
    .background(VenusTheme.backgroundGradient)
}
