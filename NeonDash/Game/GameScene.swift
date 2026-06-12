import SpriteKit

final class GameScene: SKScene {

    enum Rail {
        case left, right
    }

    private let player = SKShapeNode(circleOfRadius: 18)
    private var currentRail: Rail = .left
    private var leftRailX: CGFloat = 0
    private var rightRailX: CGFloat = 0
    private let playerY: CGFloat = 140
    private let switchDuration: TimeInterval = 0.12

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero
        leftRailX = size.width * 0.32
        rightRailX = size.width * 0.68

        buildRails()
        buildPlayer()
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
        addChild(player)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switchRail()
    }

    private func switchRail() {
        currentRail = (currentRail == .left) ? .right : .left
        let targetX = (currentRail == .left) ? leftRailX : rightRailX
        let move = SKAction.moveTo(x: targetX, duration: switchDuration)
        move.timingMode = .easeOut
        player.run(move)
    }
}
