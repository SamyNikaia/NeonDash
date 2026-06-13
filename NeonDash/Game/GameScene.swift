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
    private let fallDuration: TimeInterval = 2.0
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

        buildBackground()
        buildRails()
        buildPlayer()
        startSpawning()
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
    }

    // MARK: - Obstacles

    private func startSpawning() {
        let spawn = SKAction.run { [weak self] in self?.spawnObstacle() }
        let wait = SKAction.wait(forDuration: baseSpawnInterval, withRange: 0.25)
        run(.repeatForever(.sequence([spawn, wait])), withKey: spawnActionKey)
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

        let fall = SKAction.moveTo(y: -60, duration: fallDuration)
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
    }
}
