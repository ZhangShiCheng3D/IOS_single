//
//  PuzzleSceneController.swift
//  LumenPuzzle
//
//  解谜场景的 SceneKit 构建与运行核心。
//  职责：
//   1. 根据 Level 定义搭建 3D 场景（地台、障碍、目标、可移动光源、相机机位）。
//   2. 提供"移动光源"接口，并将屏幕坐标投影到光源所在水平面。
//   3. 用 hitTestWithSegment 做光线遮挡判定，更新每个目标的"被照亮"状态。
//   4. 提供相机环绕（旋转视角）能力。
//
//  渲染美学：暖金色点光源 + 实时阴影，深色地台与哑光障碍，
//  形成 Monument Valley 式的静谧、克制画面。
//

import SceneKit
import UIKit

@MainActor
final class PuzzleSceneController {

    /// 用于 hitTest 过滤的分类掩码：仅障碍物参与遮挡判定。
    private static let obstacleCategory: Int = 1 << 1

    let scene = SCNScene()
    let level: Level

    /// 光源根节点（携带 SCNLight，并有一个发光小球作为视觉表现）。
    private let lightNode = SCNNode()
    /// 相机机位（pivot 在原点，旋转 pivot 即环绕场景）。
    private let cameraPivot = SCNNode()
    let cameraNode = SCNNode()

    /// 每个目标对应的视觉节点与定义。
    private struct TargetEntry {
        let target: LightTarget
        let core: SCNNode      // 发光核心（球）
        let ring: SCNNode      // 地面光环
    }
    private var targetEntries: [TargetEntry] = []

    /// 已点亮目标的 id 集合（latching：一旦点亮即保持，便于"逐一扫亮"的玩法且保证可解）。
    private(set) var litTargetIDs: Set<UUID> = []

    /// 相机环绕角度（绕 Y）。
    private var orbitYaw: Float = 0
    /// 相机俯仰角度（绕 X）。
    private var orbitPitch: Float = -0.62

    init(level: Level) {
        self.level = level
        buildScene()
    }

    // MARK: - 场景搭建

    private func buildScene() {
        scene.background.contents = UIColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1)

        buildPlatform()
        buildObstacles()
        buildTargets()
        buildMovableLight()
        buildAmbientFill()
        buildCamera()
        // 注意：不在此处评估照亮状态，避免光源初始位置"白送"点亮，
        // 目标的 latching 只应由玩家拖动触发。
    }

    private func buildPlatform() {
        let box = SCNBox(
            width: CGFloat(level.platformSize.x),
            height: CGFloat(level.platformSize.y),
            length: CGFloat(level.platformSize.z),
            chamferRadius: 0.4
        )
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 1)
        material.roughness.contents = 0.9
        material.metalness.contents = 0.0
        box.materials = [material]

        let node = SCNNode(geometry: box)
        node.position = SCNVector3(0, -Float(level.platformSize.y) / 2, 0)
        node.castsShadow = false
        scene.rootNode.addChildNode(node)
    }

    private func buildObstacles() {
        for obstacle in level.obstacles {
            let box = SCNBox(
                width: CGFloat(obstacle.size.x),
                height: CGFloat(obstacle.size.y),
                length: CGFloat(obstacle.size.z),
                chamferRadius: 0.12
            )
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(red: 0.20, green: 0.22, blue: 0.30, alpha: 1)
            material.roughness.contents = 0.8
            material.metalness.contents = 0.1
            box.materials = [material]

            let node = SCNNode(geometry: box)
            node.position = obstacle.position
            node.eulerAngles.y = obstacle.rotationY
            node.categoryBitMask = Self.obstacleCategory
            node.castsShadow = true
            scene.rootNode.addChildNode(node)
        }
    }

    private func buildTargets() {
        for target in level.targets {
            // 地面光环（视觉提示目标所在）。
            let ringGeo = SCNTorus(ringRadius: 0.9, pipeRadius: 0.07)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = UIColor.white
            ringMat.emission.contents = UIColor(white: 0.4, alpha: 1)
            ringGeo.materials = [ringMat]
            let ring = SCNNode(geometry: ringGeo)
            ring.position = SCNVector3(target.position.x, 0.05, target.position.z)
            ring.castsShadow = false
            scene.rootNode.addChildNode(ring)

            // 发光核心球。
            let coreGeo = SCNSphere(radius: 0.45)
            let coreMat = SCNMaterial()
            coreMat.diffuse.contents = UIColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1)
            coreMat.emission.contents = UIColor(white: 0.05, alpha: 1)
            coreGeo.materials = [coreMat]
            let core = SCNNode(geometry: coreGeo)
            core.position = target.position
            core.castsShadow = false
            scene.rootNode.addChildNode(core)

            targetEntries.append(TargetEntry(target: target, core: core, ring: ring))
        }
    }

    private func buildMovableLight() {
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: 1)
        light.intensity = 1500
        light.castsShadow = true
        light.shadowMode = .deferred
        light.shadowRadius = 6
        light.shadowColor = UIColor(white: 0, alpha: 0.55)
        light.attenuationStartDistance = 2
        light.attenuationEndDistance = 26
        lightNode.light = light
        lightNode.position = level.lightBounds.clamp(level.lightStart)

        // 视觉：一个暖色发光小球，代表玩家正在拖动的光。
        let bulbGeo = SCNSphere(radius: 0.55)
        let bulbMat = SCNMaterial()
        bulbMat.diffuse.contents = UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1)
        bulbMat.emission.contents = UIColor(red: 1.0, green: 0.88, blue: 0.6, alpha: 1)
        bulbGeo.materials = [bulbMat]
        let bulb = SCNNode(geometry: bulbGeo)
        bulb.castsShadow = false
        lightNode.addChildNode(bulb)

        // 柔和脉动动画，让光源显得"活着"。
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.12, duration: 1.1),
            SCNAction.scale(to: 1.0, duration: 1.1)
        ])
        bulb.runAction(SCNAction.repeatForever(pulse))

        scene.rootNode.addChildNode(lightNode)
    }

    private func buildAmbientFill() {
        // 极弱环境光，避免阴影区纯黑，保留画面层次但仍依赖主光解谜。
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1)
        ambient.intensity = 220
        let node = SCNNode()
        node.light = ambient
        scene.rootNode.addChildNode(node)
    }

    private func buildCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 48
        camera.wantsHDR = true
        camera.bloomIntensity = 0.6
        camera.bloomThreshold = 0.7
        camera.bloomBlurRadius = 12
        camera.zNear = 0.1
        camera.zFar = 200
        cameraNode.camera = camera

        // 相机距离随地台大小自适应。
        let radius = max(level.platformSize.x, level.platformSize.z)
        cameraNode.position = SCNVector3(0, 0, radius * 1.5)

        cameraPivot.addChildNode(cameraNode)
        cameraPivot.position = SCNVector3(0, 1.5, 0)
        applyOrbit()
        scene.rootNode.addChildNode(cameraPivot)
    }

    // MARK: - 光源移动

    /// 将光源移动到给定的世界平面坐标（自动夹取到允许范围）。
    func moveLight(toPlanePoint point: SCNVector3) {
        lightNode.position = level.lightBounds.clamp(point)
        evaluateLitState()
    }

    // MARK: - 照亮判定

    /// 判定结果（供 ViewModel 使用）。
    struct EvaluationResult {
        let litCount: Int
        let totalCount: Int
        var isSolved: Bool { litCount == totalCount && totalCount > 0 }
    }

    /// 重新评估所有目标的照亮状态，并更新视觉。返回结果。
    /// 采用 latching：目标一旦被照亮即保持点亮，玩家可逐一扫亮所有目标。
    @discardableResult
    func evaluateLitState() -> EvaluationResult {
        for entry in targetEntries where !litTargetIDs.contains(entry.target.id) {
            if isTargetLit(entry.target) {
                litTargetIDs.insert(entry.target.id)
                illuminate(entry)
            }
        }
        return EvaluationResult(litCount: litTargetIDs.count, totalCount: targetEntries.count)
    }

    /// 单个目标是否被照亮：距离达标 且 光线到目标之间无障碍遮挡。
    private func isTargetLit(_ target: LightTarget) -> Bool {
        let from = lightNode.position
        let to = target.position

        // 距离衰减：太远则视为光太弱。
        guard from.distance(to: to) <= target.maxLitDistance else { return false }

        // 遮挡判定：仅对障碍物分类做线段命中测试。
        let hits = scene.rootNode.hitTestWithSegment(
            from: from,
            to: to,
            options: [
                SCNHitTestOption.categoryBitMask.rawValue: Self.obstacleCategory,
                SCNHitTestOption.searchMode.rawValue: SCNHitTestSearchMode.any.rawValue
            ]
        )
        return hits.isEmpty
    }

    /// 点亮一个目标：金光绽放（emission 渐变 + 轻微放大脉冲）。
    private func illuminate(_ entry: TargetEntry) {
        let coreMat = entry.core.geometry?.firstMaterial
        let ringMat = entry.ring.geometry?.firstMaterial

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.35
        coreMat?.emission.contents = UIColor(red: 1.0, green: 0.84, blue: 0.45, alpha: 1)
        ringMat?.emission.contents = UIColor(red: 1.0, green: 0.78, blue: 0.4, alpha: 1)
        SCNTransaction.commit()

        // 点亮瞬间的呼吸脉冲。
        let pop = SCNAction.sequence([
            SCNAction.scale(to: 1.25, duration: 0.18),
            SCNAction.scale(to: 1.0, duration: 0.22)
        ])
        entry.core.runAction(pop)
    }

    // MARK: - 相机环绕

    /// 以增量方式旋转相机（弧度）。pitch 被夹取避免翻转。
    func orbit(deltaYaw: Float, deltaPitch: Float) {
        orbitYaw += deltaYaw
        orbitPitch = min(max(orbitPitch + deltaPitch, -1.45), -0.12)
        applyOrbit()
    }

    private func applyOrbit() {
        cameraPivot.eulerAngles = SCNVector3(orbitPitch, orbitYaw, 0)
    }

    /// 通关时的庆祝动画：所有目标向上轻跳并增强辉光，光源短暂放大。
    func playCompletionFlourish() {
        for entry in targetEntries {
            let up = SCNAction.moveBy(x: 0, y: 0.6, z: 0, duration: 0.3)
            up.timingMode = .easeOut
            let down = SCNAction.moveBy(x: 0, y: -0.6, z: 0, duration: 0.4)
            down.timingMode = .easeInEaseOut
            entry.core.runAction(SCNAction.sequence([up, down]))
        }
    }
}
