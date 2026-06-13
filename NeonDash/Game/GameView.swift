import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var state = GameState()
    @State private var scene = GameScene()

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                SpriteView(scene: configure(scene, for: proxy.size))
                    .ignoresSafeArea()
                HUDOverlay(state: state)
            }
        }
    }

    private func configure(_ scene: GameScene, for size: CGSize) -> GameScene {
        scene.state = state
        if scene.size != size {
            scene.size = size
            scene.scaleMode = .resizeFill
        }
        return scene
    }
}

#Preview {
    GameView()
}
