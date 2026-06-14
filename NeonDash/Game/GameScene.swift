import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    enum Rail {
        case left, right
    }

    private enum PhysicsCategory {
        static let player: UInt32 = 1 << 0
        static let obstacle: UInt32 = 1 << 1
    }

    private let playerRadius: CGFloat = 14
    private let playerNode = SKNode()
    private var currentRail: Rail = .left
    private var leftRailX: CGFloat = 0
    private var rightRailX: CGFloat = 0
    private let playerY: CGFloat = 160
    private let switchDuration: TimeInterval = 0.12

    private let spawnActionKey = "spawn"
    private let baseSpawnInterval: TimeInterval = 0.9
    private let minSpawnInterval: TimeInterval = 0.40
    private let baseFallDuration: TimeInterval = 2.0
    private let minFallDuration: TimeInterval = 1.0
    private let rampScoreCeiling: Double = 80
    private var isGameOver = false

    private var trail: SKEmitterNode?

    weak var state: GameState?

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero
        leftRailX = size.width * 0.32
        rightRailX = size.width * 0.68

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        let cam = SKCameraNode()
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cam)
        camera = cam

        buildBackground()
        buildRails()
        buildPlayer()

        Haptics.prepare()
        playIntro()
    }

    private func playIntro() {
        playerNode.setScale(0)
        playerNode.alpha = 0
        let pop = SKAction.group([
            .scale(to: 1.15, duration: 0.28),
            .fadeIn(withDuration: 0.28)
        ])
        pop.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        let startSpawn = SKAction.run { [weak self] in self?.startSpawning() }
        playerNode.run(.sequence([pop, settle]))
        run(.sequence([.wait(forDuration: 0.55), startSpawn]))
    }

    // MARK: - World

    private func buildBackground() {
        let texture = SKTexture.verticalGradient(top: Theme.backgroundTop, bottom: Theme.backgroundBottom, size: size)
        let bg = SKSpriteNode(texture: texture, size: size)
        bg.anchorPoint = .zero
        bg.zPosition = -100
        addChild(bg)
    }

    private func buildRails() {
        for x in [leftRailX, rightRailX] {
            let rail = SKShapeNode(rect: CGRect(x: x - 1, y: 0, width: 2, height: size.height))
            rail.fillColor = Theme.rail.withAlphaComponent(0.35)
            rail.strokeColor = .clear
            rail.zPosition = 1
            rail.blendMode = .add
            addChild(rail)
        }
    }

    private func buildPlayer() {
        playerNode.position = CGPoint(x: leftRailX, y: playerY)
        playerNode.zPosition = 10

        let visual = Theme.glowingCircle(radius: playerRadius, color: Theme.player)
        playerNode.addChild(visual)

        let body = SKPhysicsBody(circleOfRadius: playerRadius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.obstacle
        body.collisionBitMask = 0
        playerNode.physicsBody = body

        let emitter = makeTrail()
        playerNode.addChild(emitter)
        trail = emitter

        addChild(playerNode)
    }

    private func makeTrail() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture.radialDot(radius: 8, color: .white)
        emitter.particleColor = Theme.player
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.particleBirthRate = 90
        emitter.particleLifetime = 0.45
        emitter.particleScale = 0.45
        emitter.particleScaleSpeed = -1.2
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -2.4
        emitter.position = CGPoint(x: 0, y: 0)
        emitter.zPosition = -1
        return emitter
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        switchRail()
    }

    private func switchRail() {
        currentRail = (currentRail == .left) ? .right : .left
        let targetX = (currentRail == .left) ? leftRailX : rightRailX
        let move = SKAction.moveTo(x: targetX, duration: switchDuration)
        move.timingMode = .easeOut
        playerNode.run(move)
        Haptics.tap()
    }

    private func shakeScreen(intensity: CGFloat = 22) {
        guard let camera else { return }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        var actions: [SKAction] = []
        for _ in 0..<6 {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            let step = SKAction.move(to: CGPoint(x: center.x + dx, y: center.y + dy), duration: 0.04)
            step.timingMode = .easeOut
            actions.append(step)
        }
        actions.append(.move(to: center, duration: 0.06))
        camera.run(.sequence(actions))
    }

    // MARK: - Obstacles

    private func startSpawning() {
        scheduleNextSpawn()
    }

    private func scheduleNextSpawn() {
        guard !isGameOver else { return }
        let interval = currentSpawnInterval()
        let wait = SKAction.wait(forDuration: interval, withRange: interval * 0.25)
        let spawnAndChain = SKAction.run { [weak self] in
            guard let self, !self.isGameOver else { return }
            self.spawnObstacle()
            self.scheduleNextSpawn()
        }
        run(.sequence([wait, spawnAndChain]), withKey: spawnActionKey)
    }

    private func difficultyT() -> Double {
        let score = Double(state?.score ?? 0)
        return min(score / rampScoreCeiling, 1.0)
    }

    private func currentSpawnInterval() -> TimeInterval {
        let t = difficultyT()
        return baseSpawnInterval - (baseSpawnInterval - minSpawnInterval) * t
    }

    private func currentFallDuration() -> TimeInterval {
        let t = difficultyT()
        return baseFallDuration - (baseFallDuration - minFallDuration) * t
    }

    private func spawnObstacle() {
        let onLeft = Bool.random()
        let railX = onLeft ? leftRailX : rightRailX
        let barSize = CGSize(width: 72, height: 16)

        let obstacle = SKNode()
        obstacle.position = CGPoint(x: railX, y: size.height + 60)
        obstacle.zPosition = 5
        obstacle.addChild(Theme.glowingBar(size: barSize, color: Theme.obstacle))

        let body = SKPhysicsBody(rectangleOf: barSize)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.obstacle
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        obstacle.physicsBody = body

        addChild(obstacle)

        let fall = SKAction.moveTo(y: -60, duration: currentFallDuration())
        let award = SKAction.run { [weak self] in
            guard let self, !self.isGameOver else { return }
            self.state?.addPoint()
        }
        obstacle.run(.sequence([fall, award, .removeFromParent()]))
    }

    // MARK: - Collision

    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }
        triggerGameOver()
    }

    private func triggerGameOver() {
        isGameOver = true
        removeAction(forKey: spawnActionKey)
        children
            .filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.obstacle }
            .forEach { $0.removeAllActions() }
        trail?.particleBirthRate = 0
        playerNode.run(.fadeAlpha(to: 0.3, duration: 0.2))
        Haptics.crash()
        shakeScreen()
        state?.endGame()
    }

    // MARK: - Restart

    func restart() {
        isGameOver = false
        children
            .filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.obstacle }
            .forEach { $0.removeFromParent() }

        currentRail = .left
        playerNode.removeAllActions()
        playerNode.position = CGPoint(x: leftRailX, y: playerY)
        trail?.particleBirthRate = 90

        state?.reset()
        playIntro()
    }
}
