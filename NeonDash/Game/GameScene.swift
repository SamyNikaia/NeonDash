import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    enum Rail {
        case left, right

        var opposite: Rail { self == .left ? .right : .left }
    }

    private enum PhysicsCategory {
        static let player: UInt32 = 1 << 0
        static let obstacle: UInt32 = 1 << 1
        static let coin: UInt32 = 1 << 2
    }

    private enum ObstacleVariant {
        case standard
        case long
        case fast

        var size: CGSize {
            switch self {
            case .standard, .fast: return CGSize(width: 72, height: 16)
            case .long: return CGSize(width: 72, height: 44)
            }
        }

        var color: SKColor {
            switch self {
            case .standard, .long: return Theme.obstacle
            case .fast: return Theme.obstacleFast
            }
        }

        var speedMultiplier: Double {
            switch self {
            case .standard, .long: return 1.0
            case .fast: return 1.7
            }
        }
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
    private var backgroundNode: SKSpriteNode?
    private var currentPaletteIndex: Int = 0

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
        currentPaletteIndex = 0
        let bg = makeBackgroundNode(for: Theme.palettes[0])
        addChild(bg)
        backgroundNode = bg
    }

    private func makeBackgroundNode(for palette: Theme.BackgroundPalette) -> SKSpriteNode {
        let texture = SKTexture.verticalGradient(top: palette.top, bottom: palette.bottom, size: size)
        let node = SKSpriteNode(texture: texture, size: size)
        node.anchorPoint = .zero
        node.zPosition = -100
        return node
    }

    private func updatePaletteForScore() {
        let score = state?.score ?? 0
        let newIndex = Theme.paletteThresholds
            .enumerated()
            .last(where: { $0.element <= score })?.offset ?? 0
        guard newIndex != currentPaletteIndex else { return }
        currentPaletteIndex = newIndex
        transitionToPalette(Theme.palettes[newIndex])
    }

    private func transitionToPalette(_ palette: Theme.BackgroundPalette) {
        let newBg = makeBackgroundNode(for: palette)
        newBg.zPosition = -99
        newBg.alpha = 0
        addChild(newBg)
        let old = backgroundNode
        backgroundNode = newBg
        newBg.run(.fadeIn(withDuration: 0.8)) {
            newBg.zPosition = -100
            old?.removeFromParent()
        }
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
        body.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.coin
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

    // MARK: - Per-frame

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        updatePaletteForScore()
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
        let rail: Rail = Bool.random() ? .left : .right

        if rollPaired() {
            spawnSingle(rail: rail, variant: .standard)
            run(.sequence([
                .wait(forDuration: 0.38),
                .run { [weak self] in
                    self?.spawnSingle(rail: rail.opposite, variant: .standard)
                }
            ]))
        } else {
            spawnSingle(rail: rail, variant: pickVariant())
        }

        if Double.random(in: 0...1) < 0.20 {
            let coinRail: Rail = Bool.random() ? .left : .right
            let delay = Double.random(in: 0.28...0.55)
            run(.sequence([
                .wait(forDuration: delay),
                .run { [weak self] in self?.spawnCoin(rail: coinRail) }
            ]))
        }
    }

    private func spawnCoin(rail: Rail) {
        let railX = (rail == .left) ? leftRailX : rightRailX
        let coin = SKNode()
        coin.name = "coin"
        coin.position = CGPoint(x: railX, y: size.height + 40)
        coin.zPosition = 6
        coin.addChild(Theme.glowingCircle(radius: 9, color: Theme.coin))

        let body = SKPhysicsBody(circleOfRadius: 11)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.coin
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        coin.physicsBody = body

        addChild(coin)

        let fall = SKAction.moveTo(y: -40, duration: currentFallDuration() * 1.15)
        coin.run(.sequence([fall, .removeFromParent()]))
    }

    private func pickVariant() -> ObstacleVariant {
        let score = state?.score ?? 0
        let r = Double.random(in: 0...1)
        switch score {
        case 0..<15: return .standard
        case 15..<35: return r < 0.78 ? .standard : (r < 0.90 ? .long : .fast)
        case 35..<60: return r < 0.55 ? .standard : (r < 0.78 ? .long : .fast)
        default: return r < 0.42 ? .standard : (r < 0.70 ? .long : .fast)
        }
    }

    private func rollPaired() -> Bool {
        let score = state?.score ?? 0
        guard score >= 25 else { return false }
        let chance = min(0.10 + Double(score - 25) * 0.003, 0.28)
        return Double.random(in: 0...1) < chance
    }

    private func spawnSingle(rail: Rail, variant: ObstacleVariant) {
        let railX = (rail == .left) ? leftRailX : rightRailX
        let barSize = variant.size

        let obstacle = SKNode()
        obstacle.position = CGPoint(x: railX, y: size.height + 60)
        obstacle.zPosition = 5
        obstacle.addChild(Theme.glowingBar(size: barSize, color: variant.color))

        let body = SKPhysicsBody(rectangleOf: barSize)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.obstacle
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        obstacle.physicsBody = body

        addChild(obstacle)

        let duration = currentFallDuration() / variant.speedMultiplier
        let fall = SKAction.moveTo(y: -60, duration: duration)
        let award = SKAction.run { [weak self] in
            guard let self, !self.isGameOver else { return }
            self.state?.addPoint()
        }
        obstacle.run(.sequence([fall, award, .removeFromParent()]))
    }

    // MARK: - Collision

    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }
        let bodies = [contact.bodyA, contact.bodyB]
        if let coinBody = bodies.first(where: { $0.categoryBitMask == PhysicsCategory.coin }) {
            collect(coinBody.node)
        } else {
            triggerGameOver()
        }
    }

    private func collect(_ node: SKNode?) {
        guard let node else { return }
        node.physicsBody = nil
        state?.addCoins(1)
        Haptics.tap()
        let pop = SKAction.group([
            .scale(to: 1.9, duration: 0.18),
            .fadeOut(withDuration: 0.18)
        ])
        node.run(.sequence([pop, .removeFromParent()]))
    }

    private func triggerGameOver() {
        isGameOver = true
        removeAction(forKey: spawnActionKey)
        children
            .filter {
                let cat = $0.physicsBody?.categoryBitMask
                return cat == PhysicsCategory.obstacle || cat == PhysicsCategory.coin
            }
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
            .filter {
                let cat = $0.physicsBody?.categoryBitMask
                return cat == PhysicsCategory.obstacle || cat == PhysicsCategory.coin
            }
            .forEach { $0.removeFromParent() }

        currentRail = .left
        playerNode.removeAllActions()
        playerNode.position = CGPoint(x: leftRailX, y: playerY)
        trail?.particleBirthRate = 90

        if currentPaletteIndex != 0 {
            transitionToPalette(Theme.palettes[0])
            currentPaletteIndex = 0
        }

        state?.reset()
        playIntro()
    }
}
