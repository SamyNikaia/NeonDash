import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    enum Rail {
        case left, right
    }

    private enum PhysicsCategory {
        static let player: UInt32 = 1 << 0
        static let obstacle: UInt32 = 1 << 1
    }

    private let player = SKShapeNode(circleOfRadius: 18)
    private var currentRail: Rail = .left
    private var leftRailX: CGFloat = 0
    private var rightRailX: CGFloat = 0
    private let playerY: CGFloat = 140
    private let switchDuration: TimeInterval = 0.12

    private let spawnActionKey = "spawn"
    private let baseSpawnInterval: TimeInterval = 0.9
    private let fallDuration: TimeInterval = 2.0
    private var isGameOver = false

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero
        leftRailX = size.width * 0.32
        rightRailX = size.width * 0.68

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        buildRails()
        buildPlayer()
        startSpawning()
    }

    private func buildRails() {
        for x in [leftRailX, rightRailX] {
            let rail = SKShapeNode(rect: CGRect(x: x - 1, y: 0, width: 2, height: size.height))
            rail.fillColor = SKColor.white.withAlphaComponent(0.12)
            rail.strokeColor = .clear
            rail.zPosition = 1
            addChild(rail)
        }
    }

    private func buildPlayer() {
        player.fillColor = .white
        player.strokeColor = .clear
        player.position = CGPoint(x: leftRailX, y: playerY)
        player.zPosition = 10

        let body = SKPhysicsBody(circleOfRadius: 18)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.obstacle
        body.collisionBitMask = 0
        player.physicsBody = body

        addChild(player)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        switchRail()
    }

    private func switchRail() {
        currentRail = (currentRail == .left) ? .right : .left
        let targetX = (currentRail == .left) ? leftRailX : rightRailX
        let move = SKAction.moveTo(x: targetX, duration: switchDuration)
        move.timingMode = .easeOut
        player.run(move)
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

        let obstacle = SKShapeNode(rectOf: CGSize(width: 64, height: 18), cornerRadius: 4)
        obstacle.fillColor = .white
        obstacle.strokeColor = .clear
        obstacle.position = CGPoint(x: railX, y: size.height + 40)
        obstacle.zPosition = 5

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 64, height: 18))
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.obstacle
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        obstacle.physicsBody = body

        addChild(obstacle)

        let fall = SKAction.moveTo(y: -40, duration: fallDuration)
        obstacle.run(.sequence([fall, .removeFromParent()]))
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
        player.run(.fadeAlpha(to: 0.3, duration: 0.2))
    }
}
