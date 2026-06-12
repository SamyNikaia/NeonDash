import SwiftUI
import SpriteKit

struct GameView: View {
    @State private var scene = GameScene()

    var body: some View {
        GeometryReader { proxy in
            SpriteView(scene: configure(scene, for: proxy.size))
                .ignoresSafeArea()
        }
    }

    private func configure(_ scene: GameScene, for size: CGSize) -> GameScene {
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
