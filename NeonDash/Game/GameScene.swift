import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    enum Rail: Int, CaseIterable {
        case left = 0, mid = 1, right = 2

        func shifted(_ delta: Int) -> Rail {
            let new = max(0, min(Rail.allCases.count - 1, rawValue + delta))
            return Rail(rawValue: new) ?? self
        }

        static func random(excluding excluded: Rail? = nil) -> Rail {
            Rail.allCases.filter { $0 != excluded }.randomElement()!
        }
    }

    private enum PhysicsCategory {
        static let player: UInt32 = 1 << 0
        static let obstacle: UInt32 = 1 << 1
        static let coin: UInt32 = 1 << 2
        static let heart: UInt32 = 1 << 3
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
            case .fast: return 1.35
            }
        }

        var isRainbow: Bool { self == .fast }
    }

    private let playerRadius: CGFloat = 14
    private let playerNode = SKNode()
    private var currentRail: Rail = .mid
    private var railXs: [CGFloat] = []
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
    private var fireOverlay: SKSpriteNode?
    private var isOnFire: Bool = false
    private var isInvincible: Bool = false
    private let invincibilityDuration: TimeInterval = 1.0

    weak var state: GameState?

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero
        railXs = [size.width * 0.22, size.width * 0.50, size.width * 0.78]

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
        AudioManager.shared.startMainMusic()
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

    private func currentPalettes() -> [Theme.BackgroundPalette] {
        state?.equippedBackground.palettes ?? Theme.palettes
    }

    private func buildBackground() {
        currentPaletteIndex = 0
        let bg = makeBackgroundNode(for: currentPalettes()[0])
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
        transitionToPalette(currentPalettes()[newIndex])
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
        for x in railXs {
            let rail = SKShapeNode(rect: CGRect(x: x - 1, y: 0, width: 2, height: size.height))
            rail.fillColor = Theme.rail.withAlphaComponent(0.30)
            rail.strokeColor = .clear
            rail.zPosition = 1
            rail.blendMode = .add
            addChild(rail)
        }
    }

    private func x(for rail: Rail) -> CGFloat {
        railXs[rail.rawValue]
    }

    private func buildPlayer() {
        currentRail = .mid
        playerNode.position = CGPoint(x: x(for: currentRail), y: playerY)
        playerNode.zPosition = 10

        let ballColor = state?.equippedBall.color ?? Theme.player
        let visual = Theme.glowingCircle(radius: playerRadius, color: ballColor)
        playerNode.addChild(visual)

        let body = SKPhysicsBody(circleOfRadius: playerRadius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.coin | PhysicsCategory.heart
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
        emitter.particleColor = state?.equippedBall.color ?? Theme.player
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
        updateFireState()
    }

    private func updateFireState() {
        let shouldFire = state?.isOnFire ?? false
        if shouldFire && !isOnFire {
            enterFire()
        } else if !shouldFire && isOnFire {
            exitFire()
        }
    }

    private func enterFire() {
        isOnFire = true
        trail?.particleColor = Theme.fire
        trail?.particleBirthRate = 160
        playerNode.run(.scale(to: 1.25, duration: 0.25))
        AudioManager.shared.enterFire()

        let overlay = SKSpriteNode(color: Theme.fire, size: size)
        overlay.anchorPoint = .zero
        overlay.zPosition = -40
        overlay.blendMode = .add
        overlay.alpha = 0
        addChild(overlay)
        fireOverlay = overlay

        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.18, duration: 0.7),
            .fadeAlpha(to: 0.08, duration: 0.7)
        ])
        overlay.run(.repeatForever(pulse), withKey: "firePulse")
    }

    private func exitFire() {
        isOnFire = false
        trail?.particleColor = state?.equippedBall.color ?? Theme.player
        trail?.particleBirthRate = 90
        playerNode.run(.scale(to: 1.0, duration: 0.25))
        fireOverlay?.removeAction(forKey: "firePulse")
        fireOverlay?.run(.sequence([.fadeOut(withDuration: 0.4), .removeFromParent()]))
        fireOverlay = nil
        AudioManager.shared.exitFire()
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        guard let touch = touches.first else { return }
        let direction = touch.location(in: self).x < size.width / 2 ? -1 : 1
        switchRail(direction: direction)
    }

    private func switchRail(direction: Int) {
        let target = currentRail.shifted(direction)
        guard target != currentRail else { return }
        currentRail = target
        let move = SKAction.moveTo(x: x(for: currentRail), duration: switchDuration)
        move.timingMode = .easeOut
        playerNode.run(move)
        Haptics.tap()
        AudioManager.shared.playSwitch()
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
        let rail = Rail.random()

        if rollPaired() {
            spawnSingle(rail: rail, variant: .standard)
            let second = Rail.random(excluding: rail)
            run(.sequence([
                .wait(forDuration: 0.38),
                .run { [weak self] in
                    self?.spawnSingle(rail: second, variant: .standard)
                }
            ]))
        } else {
            spawnSingle(rail: rail, variant: pickVariant())
        }

        if Double.random(in: 0...1) < 0.20 {
            let coinRail = Rail.random()
            let delay = Double.random(in: 0.28...0.55)
            run(.sequence([
                .wait(forDuration: delay),
                .run { [weak self] in self?.spawnCoin(rail: coinRail) }
            ]))
        }

        if let state, state.lives < GameState.maxLives, Double.random(in: 0...1) < 0.04 {
            let heartRail = Rail.random()
            let delay = Double.random(in: 0.30...0.65)
            run(.sequence([
                .wait(forDuration: delay),
                .run { [weak self] in self?.spawnHeart(rail: heartRail) }
            ]))
        }
    }

    private func spawnHeart(rail: Rail) {
        let railX = x(for: rail)
        let heart = SKNode()
        heart.name = "heart"
        heart.position = CGPoint(x: railX, y: size.height + 40)
        heart.zPosition = 6

        let glow = SKShapeNode(circleOfRadius: 18)
        glow.fillColor = Theme.heart.withAlphaComponent(0.30)
        glow.strokeColor = .clear
        glow.blendMode = .add
        heart.addChild(glow)

        let sprite = SKSpriteNode(texture: makeHeartTexture(color: Theme.heart, pointSize: 22))
        heart.addChild(sprite)

        let body = SKPhysicsBody(circleOfRadius: 13)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.heart
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        heart.physicsBody = body

        addChild(heart)

        let fall = SKAction.moveTo(y: -40, duration: currentFallDuration() * 1.2)
        heart.run(.sequence([fall, .removeFromParent()]))
    }

    private func applyRainbowCycle(to node: SKNode, period: TimeInterval) {
        let shapes = node.children.compactMap { $0 as? SKShapeNode }
        let alphas = shapes.map { CGFloat($0.fillColor.cgColor.alpha) }
        let cycle = SKAction.customAction(withDuration: period) { _, elapsed in
            let t = (Double(elapsed) / period).truncatingRemainder(dividingBy: 1.0)
            let color = SKColor(hue: CGFloat(t), saturation: 1.0, brightness: 1.0, alpha: 1)
            for (shape, alpha) in zip(shapes, alphas) {
                shape.fillColor = color.withAlphaComponent(alpha)
            }
        }
        node.run(.repeatForever(cycle), withKey: "rainbow")
    }

    private func makeHeartTexture(color: SKColor, pointSize: CGFloat) -> SKTexture {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .black)
        if let image = UIImage(systemName: "heart.fill", withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal) {
            return SKTexture(image: image)
        }
        return SKTexture.radialDot(radius: pointSize / 2, color: color)
    }

    private func spawnCoin(rail: Rail) {
        let railX = x(for: rail)
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
        let railX = x(for: rail)
        let barSize = variant.size

        let obstacle = SKNode()
        obstacle.position = CGPoint(x: railX, y: size.height + 60)
        obstacle.zPosition = 5
        let bar = Theme.glowingBar(size: barSize, color: variant.color)
        obstacle.addChild(bar)
        if variant.isRainbow {
            applyRainbowCycle(to: bar, period: 0.85)
        }

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
            collectCoin(coinBody.node)
        } else if let heartBody = bodies.first(where: { $0.categoryBitMask == PhysicsCategory.heart }) {
            collectHeart(heartBody.node)
        } else if !isInvincible {
            takeDamage()
        }
    }

    private func collectCoin(_ node: SKNode?) {
        guard let node else { return }
        node.physicsBody = nil
        state?.addCoins(1)
        Haptics.tap()
        AudioManager.shared.playCoin()
        let pop = SKAction.group([
            .scale(to: 1.9, duration: 0.18),
            .fadeOut(withDuration: 0.18)
        ])
        node.run(.sequence([pop, .removeFromParent()]))
    }

    private func collectHeart(_ node: SKNode?) {
        guard let node else { return }
        node.physicsBody = nil
        state?.addLife()
        Haptics.tap()
        AudioManager.shared.playCoin()
        let pop = SKAction.group([
            .scale(to: 2.2, duration: 0.22),
            .fadeOut(withDuration: 0.22)
        ])
        node.run(.sequence([pop, .removeFromParent()]))
    }

    private func takeDamage() {
        guard let state else { return }
        let stillAlive = state.loseLife()
        if isOnFire { exitFire() }
        Haptics.crash()
        AudioManager.shared.playCrash()
        shakeScreen(intensity: stillAlive ? 14 : 22)

        if stillAlive {
            startInvincibility()
            flashDamage()
        } else {
            finishGame()
        }
    }

    private func startInvincibility() {
        isInvincible = true
        let blink = SKAction.sequence([
            .fadeAlpha(to: 0.25, duration: 0.08),
            .fadeAlpha(to: 1.0, duration: 0.08)
        ])
        let blinks = SKAction.repeat(blink, count: 6)
        let restore = SKAction.fadeAlpha(to: 1.0, duration: 0)
        playerNode.run(.sequence([blinks, restore]))

        run(.sequence([
            .wait(forDuration: invincibilityDuration),
            .run { [weak self] in self?.isInvincible = false }
        ]))
    }

    private func flashDamage() {
        let flash = SKSpriteNode(color: Theme.heart, size: size)
        flash.anchorPoint = .zero
        flash.alpha = 0
        flash.blendMode = .add
        flash.zPosition = -30
        addChild(flash)
        flash.run(.sequence([
            .fadeAlpha(to: 0.28, duration: 0.08),
            .fadeOut(withDuration: 0.35),
            .removeFromParent()
        ]))
    }

    private func finishGame() {
        isGameOver = true
        removeAction(forKey: spawnActionKey)
        children
            .filter {
                let cat = $0.physicsBody?.categoryBitMask
                return cat == PhysicsCategory.obstacle
                    || cat == PhysicsCategory.coin
                    || cat == PhysicsCategory.heart
            }
            .forEach { $0.removeAllActions() }
        trail?.particleBirthRate = 0
        playerNode.run(.fadeAlpha(to: 0.3, duration: 0.2))
        AudioManager.shared.stopMusic()
        state?.endGame()
    }

    // MARK: - Restart

    func restart() {
        isGameOver = false
        isInvincible = false
        children
            .filter {
                let cat = $0.physicsBody?.categoryBitMask
                return cat == PhysicsCategory.obstacle
                    || cat == PhysicsCategory.coin
                    || cat == PhysicsCategory.heart
            }
            .forEach { $0.removeFromParent() }

        currentRail = .mid
        playerNode.removeAllActions()
        playerNode.alpha = 1.0
        playerNode.position = CGPoint(x: x(for: currentRail), y: playerY)
        trail?.particleBirthRate = 90

        if currentPaletteIndex != 0 {
            transitionToPalette(Theme.palettes[0])
            currentPaletteIndex = 0
        }

        state?.reset()
        AudioManager.shared.startMainMusic()
        playIntro()
    }
}
