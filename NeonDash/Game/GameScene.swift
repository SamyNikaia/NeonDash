import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Types

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
        static let player: UInt32   = 1 << 0
        static let obstacle: UInt32 = 1 << 1
        static let coin: UInt32     = 1 << 2
        static let heart: UInt32    = 1 << 3
        static let rocket: UInt32   = 1 << 4
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
    }

    // MARK: - Constantes

    private let playerRadius: CGFloat = 14
    private let playerY: CGFloat = 160
    private let switchDuration: TimeInterval = 0.12

    private let baseSpawnInterval: TimeInterval = 0.9
    private let minSpawnInterval: TimeInterval = 0.40
    private let baseFallDuration: TimeInterval = 2.0
    private let minFallDuration: TimeInterval = 1.0
    private let rampScoreCeiling: Double = 80

    private let invincibilityDuration: TimeInterval = 1.0
    private let rocketDuration: TimeInterval = 6.0

    private let spawnActionKey = "spawn"
    private let rocketActionKey = "rocketTimer"

    // MARK: - État

    private let playerNode = SKNode()
    private var currentRail: Rail = .mid
    private var railXs: [CGFloat] = []
    private var isGameOver = false
    private var isInvincible = false

    private var trail: SKEmitterNode?
    private var backgroundNode: SKSpriteNode?
    private var currentPaletteIndex: Int = 0
    private var fireOverlay: SKSpriteNode?
    private var isOnFire: Bool = false
    private var rocketShield: SKNode?

    weak var state: GameState?

    // MARK: - Cycle de vie

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero
        railXs = [size.width * 0.22, size.width * 0.50, size.width * 0.78]

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        // Caméra dédiée — sert juste pour les screenshakes et le jitter en mode fire.
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

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        updatePaletteForScore()
        updateFireState()
    }

    // MARK: - Construction de la scène

    private func buildBackground() {
        currentPaletteIndex = 0
        let bg = makeBackgroundNode(for: currentPalettes()[0])
        addChild(bg)
        backgroundNode = bg
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

    private func buildPlayer() {
        currentRail = .mid
        playerNode.position = CGPoint(x: x(for: currentRail), y: playerY)
        playerNode.zPosition = 10

        let ballColor = state?.equippedBall.color ?? Theme.player
        playerNode.addChild(Theme.glowingCircle(radius: playerRadius, color: ballColor))

        let body = SKPhysicsBody(circleOfRadius: playerRadius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.obstacle
            | PhysicsCategory.coin
            | PhysicsCategory.heart
            | PhysicsCategory.rocket
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
        emitter.zPosition = -1
        return emitter
    }

    // Petite intro : la bille pop, puis on attend un demi-tour avant de faire
    // tomber des obstacles. Sinon le joueur se prend un truc avant même de capter.
    private func playIntro() {
        playerNode.setScale(0)
        playerNode.alpha = 0
        let pop = SKAction.group([
            .scale(to: 1.15, duration: 0.28),
            .fadeIn(withDuration: 0.28)
        ])
        pop.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        playerNode.run(.sequence([pop, settle]))
        run(.sequence([
            .wait(forDuration: 0.55),
            .run { [weak self] in self?.startSpawning() }
        ]))
    }

    // MARK: - Saisie

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver, let touch = touches.first else { return }
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

    private func x(for rail: Rail) -> CGFloat { railXs[rail.rawValue] }

    // MARK: - Difficulté

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

    // MARK: - Obstacles

    private func startSpawning() { scheduleNextSpawn() }

    // Boucle auto-récurrente : chaque cycle relit la vitesse courante,
    // ce qui permet à la difficulté de ramp en live sans tout réinitialiser.
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

    private func spawnObstacle() {
        let rail = Rail.random()

        if rollPaired() {
            // Pattern paire : deux barres séparées de 0.38s sur deux rails
            // différents, oblige à enchaîner deux switches rapides.
            spawnBar(rail: rail, variant: .standard)
            let second = Rail.random(excluding: rail)
            run(.sequence([
                .wait(forDuration: 0.38),
                .run { [weak self] in self?.spawnBar(rail: second, variant: .standard) }
            ]))
        } else {
            spawnBar(rail: rail, variant: pickVariant())
        }

        rollExtraPickups()
    }

    private func spawnBar(rail: Rail, variant: ObstacleVariant) {
        let railX = x(for: rail)
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

    private func pickVariant() -> ObstacleVariant {
        // Mix des variants qui s'accentue avec le score.
        let score = state?.score ?? 0
        let r = Double.random(in: 0...1)
        switch score {
        case 0..<15:  return .standard
        case 15..<35: return r < 0.78 ? .standard : (r < 0.90 ? .long : .fast)
        case 35..<60: return r < 0.55 ? .standard : (r < 0.78 ? .long : .fast)
        default:      return r < 0.42 ? .standard : (r < 0.70 ? .long : .fast)
        }
    }

    private func rollPaired() -> Bool {
        let score = state?.score ?? 0
        guard score >= 25 else { return false }
        let chance = min(0.10 + Double(score - 25) * 0.003, 0.28)
        return Double.random(in: 0...1) < chance
    }

    // MARK: - Pickups

    // Tous les pickups (pièce / cœur / fusée) suivent le même schéma : un
    // container qui tombe avec un visuel + un body en cercle. Cette méthode
    // centralise la plomberie pour éviter de recopier 3 fois la même chose.
    @discardableResult
    private func spawnPickup(
        rail: Rail,
        visual: SKNode,
        radius: CGFloat,
        category: UInt32,
        fallMultiplier: Double = 1.0,
        name: String? = nil
    ) -> SKNode {
        let node = SKNode()
        node.name = name
        node.position = CGPoint(x: x(for: rail), y: size.height + 40)
        node.zPosition = 6
        node.addChild(visual)

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = category
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        node.physicsBody = body

        addChild(node)

        let fall = SKAction.moveTo(y: -40, duration: currentFallDuration() * fallMultiplier)
        node.run(.sequence([fall, .removeFromParent()]))
        return node
    }

    // Les rolls pour les pickups bonus tombent après l'obstacle principal,
    // avec un petit décalage pour qu'ils ne se chevauchent pas visuellement.
    private func rollExtraPickups() {
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

        // Fusée plus généreuse en spawn pour que le joueur la voie effectivement
        // passer de temps en temps. Pas de spawn si on est déjà en fusée.
        if !(state?.isRocketActive ?? false), Double.random(in: 0...1) < 0.07 {
            let rocketRail = Rail.random()
            let delay = Double.random(in: 0.35...0.70)
            run(.sequence([
                .wait(forDuration: delay),
                .run { [weak self] in self?.spawnRocket(rail: rocketRail) }
            ]))
        }
    }

    private func spawnCoin(rail: Rail) {
        let visual = Theme.glowingCircle(radius: 9, color: Theme.coin)
        spawnPickup(
            rail: rail, visual: visual, radius: 11,
            category: PhysicsCategory.coin,
            fallMultiplier: 1.15, name: "coin"
        )
    }

    private func spawnHeart(rail: Rail) {
        let visual = SKNode()
        let glow = SKShapeNode(circleOfRadius: 18)
        glow.fillColor = Theme.heart.withAlphaComponent(0.30)
        glow.strokeColor = .clear
        glow.blendMode = .add
        visual.addChild(glow)
        visual.addChild(SKSpriteNode(
            texture: Theme.symbolTexture(systemName: "heart.fill", color: Theme.heart, pointSize: 22)
        ))
        spawnPickup(
            rail: rail, visual: visual, radius: 13,
            category: PhysicsCategory.heart,
            fallMultiplier: 1.2, name: "heart"
        )
    }

    private func spawnRocket(rail: Rail) {
        // Sprite plus gros + halo plus large que les autres pickups, et on
        // ajoute un pulse + une rotation pour que ça attire l'œil tout de suite.
        let visual = SKNode()
        let glow = SKShapeNode(circleOfRadius: 32)
        glow.fillColor = Theme.rocket.withAlphaComponent(0.50)
        glow.strokeColor = .clear
        glow.blendMode = .add
        visual.addChild(glow)
        let sprite = SKSpriteNode(
            texture: Theme.symbolTexture(systemName: "bolt.fill", color: Theme.rocket, pointSize: 38)
        )
        visual.addChild(sprite)
        sprite.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 1.2)))

        let pickup = spawnPickup(
            rail: rail, visual: visual, radius: 22,
            category: PhysicsCategory.rocket,
            fallMultiplier: 1.1, name: "rocket"
        )
        let pulse = SKAction.sequence([
            .scale(to: 1.18, duration: 0.42),
            .scale(to: 1.00, duration: 0.42)
        ])
        pickup.run(.repeatForever(pulse))
    }

    // MARK: - Collisions

    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }
        let bodies = [contact.bodyA, contact.bodyB]

        if let coin = bodies.first(where: { $0.categoryBitMask == PhysicsCategory.coin }) {
            collectCoin(coin.node)
        } else if let heart = bodies.first(where: { $0.categoryBitMask == PhysicsCategory.heart }) {
            collectHeart(heart.node)
        } else if let rocket = bodies.first(where: { $0.categoryBitMask == PhysicsCategory.rocket }) {
            collectRocket(rocket.node)
        } else if let obstacle = bodies.first(where: { $0.categoryBitMask == PhysicsCategory.obstacle }) {
            // En fusée, on plow à travers l'obstacle ; sinon dégât (sauf i-frames).
            if state?.isRocketActive ?? false {
                destroyObstacle(obstacle.node)
            } else if !isInvincible {
                takeDamage()
            }
        }
    }

    private func collectCoin(_ node: SKNode?) {
        guard let node else { return }
        node.physicsBody = nil
        state?.addCoins(1)
        Haptics.tap()
        AudioManager.shared.playCoin()
        node.run(.sequence([
            .group([.scale(to: 1.9, duration: 0.18), .fadeOut(withDuration: 0.18)]),
            .removeFromParent()
        ]))
    }

    private func collectHeart(_ node: SKNode?) {
        guard let node else { return }
        node.physicsBody = nil
        state?.addLife()
        Haptics.tap()
        AudioManager.shared.playCoin()
        node.run(.sequence([
            .group([.scale(to: 2.2, duration: 0.22), .fadeOut(withDuration: 0.22)]),
            .removeFromParent()
        ]))
    }

    private func collectRocket(_ node: SKNode?) {
        guard let node else { return }
        node.physicsBody = nil
        Haptics.crash()
        AudioManager.shared.playCoin()
        node.run(.sequence([
            .group([.scale(to: 2.6, duration: 0.20), .fadeOut(withDuration: 0.20)]),
            .removeFromParent()
        ]))
        activateRocket()
    }

    private func destroyObstacle(_ node: SKNode?) {
        guard let node else { return }
        node.physicsBody = nil
        state?.addPoint()
        Haptics.tap()
        node.run(.sequence([
            .group([.scale(to: 1.6, duration: 0.18), .fadeOut(withDuration: 0.18)]),
            .removeFromParent()
        ]))
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

    // MARK: - Invincibilité

    private func startInvincibility() {
        isInvincible = true
        let blink = SKAction.sequence([
            .fadeAlpha(to: 0.25, duration: 0.08),
            .fadeAlpha(to: 1.0, duration: 0.08)
        ])
        playerNode.run(.sequence([
            .repeat(blink, count: 6),
            .fadeAlpha(to: 1.0, duration: 0)
        ]))
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

    // MARK: - Mode Fire

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
        // Trail toujours en orange pour la chaleur, mais on bump le débit.
        trail?.particleColor = Theme.fire
        trail?.particleBirthRate = 200
        playerNode.run(.scale(to: 1.25, duration: 0.25))
        AudioManager.shared.enterFire()

        // Overlay rainbow cyclant qui prend la place de l'ancien tint orange.
        // Le pulse d'alpha tourne en parallèle pour garder un effet "vivant".
        let overlay = SKSpriteNode(color: .red, size: size)
        overlay.anchorPoint = .zero
        overlay.zPosition = -40
        overlay.blendMode = .add
        overlay.alpha = 0
        addChild(overlay)
        fireOverlay = overlay

        let cyclePeriod: TimeInterval = 2.2
        let hueCycle = SKAction.customAction(withDuration: cyclePeriod) { node, elapsed in
            let t = (Double(elapsed) / cyclePeriod).truncatingRemainder(dividingBy: 1.0)
            let color = SKColor(hue: CGFloat(t), saturation: 0.85, brightness: 1.0, alpha: 1)
            (node as? SKSpriteNode)?.color = color
        }
        overlay.run(.repeatForever(hueCycle), withKey: "rainbowCycle")

        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.30, duration: 0.40),
            .fadeAlpha(to: 0.15, duration: 0.40)
        ])
        overlay.run(.repeatForever(pulse), withKey: "firePulse")

        startFireShake()
    }

    private func exitFire() {
        isOnFire = false
        trail?.particleColor = state?.equippedBall.color ?? Theme.player
        trail?.particleBirthRate = 90
        playerNode.run(.scale(to: 1.0, duration: 0.25))
        fireOverlay?.removeAction(forKey: "firePulse")
        fireOverlay?.removeAction(forKey: "rainbowCycle")
        fireOverlay?.run(.sequence([.fadeOut(withDuration: 0.4), .removeFromParent()]))
        fireOverlay = nil
        stopFireShake()
        AudioManager.shared.exitFire()
    }

    // Mini jitter continu de la caméra pendant le fire (~4 px). Suffisant
    // pour que ça respire mais pas au point de gêner la lecture des obstacles.
    private func startFireShake() {
        guard let camera else { return }
        let baseX = size.width / 2
        let baseY = size.height / 2
        let jitter = SKAction.run { [weak camera] in
            guard let camera else { return }
            let dx = CGFloat.random(in: -4...4)
            let dy = CGFloat.random(in: -3...3)
            camera.position = CGPoint(x: baseX + dx, y: baseY + dy)
        }
        camera.run(.repeatForever(.sequence([jitter, .wait(forDuration: 0.05)])), withKey: "fireShake")
    }

    private func stopFireShake() {
        camera?.removeAction(forKey: "fireShake")
        camera?.run(.move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: 0.15))
    }

    // MARK: - Fusée

    private func activateRocket() {
        state?.isRocketActive = true
        isInvincible = true

        rocketShield?.removeFromParent()
        let shield = SKNode()
        let ring = SKShapeNode(circleOfRadius: 30)
        ring.strokeColor = Theme.rocket
        ring.lineWidth = 2.5
        ring.fillColor = Theme.rocket.withAlphaComponent(0.10)
        ring.glowWidth = 6
        ring.blendMode = .add
        shield.addChild(ring)
        let halo = SKShapeNode(circleOfRadius: 38)
        halo.fillColor = Theme.rocket.withAlphaComponent(0.18)
        halo.strokeColor = .clear
        halo.blendMode = .add
        shield.addChild(halo)
        shield.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 1.4)))
        playerNode.addChild(shield)
        rocketShield = shield

        trail?.particleColor = Theme.rocket
        trail?.particleBirthRate = 260

        removeAction(forKey: rocketActionKey)
        run(.sequence([
            .wait(forDuration: rocketDuration),
            .run { [weak self] in self?.deactivateRocket() }
        ]), withKey: rocketActionKey)
    }

    private func deactivateRocket() {
        state?.isRocketActive = false
        isInvincible = false
        rocketShield?.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
        rocketShield = nil

        // On rebascule le trail soit en mode fire (si toujours en feu),
        // soit sur la couleur de la skin équipée.
        if isOnFire {
            trail?.particleColor = Theme.fire
            trail?.particleBirthRate = 200
        } else {
            trail?.particleColor = state?.equippedBall.color ?? Theme.player
            trail?.particleBirthRate = 90
        }
    }

    // MARK: - Palette de fond

    private func currentPalettes() -> [Theme.BackgroundPalette] {
        state?.equippedBackground.palettes ?? Theme.palettes
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

    // Crossfade entre deux sprites de fond (le nouveau pop par-dessus,
    // l'ancien est viré une fois le fade fini).
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

    // MARK: - Effets caméra

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

    // MARK: - Game over / Restart

    private func finishGame() {
        isGameOver = true
        removeAction(forKey: spawnActionKey)
        removeAction(forKey: rocketActionKey)
        clearGameplayNodes(remove: false)
        trail?.particleBirthRate = 0
        playerNode.run(.fadeAlpha(to: 0.3, duration: 0.2))
        rocketShield?.removeFromParent()
        rocketShield = nil
        state?.isRocketActive = false
        AudioManager.shared.stopMusic()
        state?.endGame()
    }

    func restart() {
        isGameOver = false
        isInvincible = false
        removeAction(forKey: rocketActionKey)
        rocketShield?.removeFromParent()
        rocketShield = nil
        clearGameplayNodes(remove: true)

        currentRail = .mid
        playerNode.removeAllActions()
        playerNode.alpha = 1.0
        playerNode.position = CGPoint(x: x(for: currentRail), y: playerY)
        trail?.particleBirthRate = 90

        if currentPaletteIndex != 0 {
            transitionToPalette(currentPalettes()[0])
            currentPaletteIndex = 0
        }

        state?.reset()
        AudioManager.shared.startMainMusic()
        playIntro()
    }

    // Sweep des nœuds gameplay (obstacles + pickups). Si `remove` est faux on
    // se contente de figer les actions (utile à la mort pour laisser la scène
    // se fixer avant l'écran game over).
    private func clearGameplayNodes(remove: Bool) {
        let targets = children.filter {
            let cat = $0.physicsBody?.categoryBitMask
            return cat == PhysicsCategory.obstacle
                || cat == PhysicsCategory.coin
                || cat == PhysicsCategory.heart
                || cat == PhysicsCategory.rocket
        }
        for node in targets {
            if remove {
                node.removeFromParent()
            } else {
                node.removeAllActions()
            }
        }
    }
}
