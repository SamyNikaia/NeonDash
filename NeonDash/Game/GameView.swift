import SwiftUI
import SpriteKit

struct GameView: View {
    @ObservedObject var state: GameState
    let onExit: () -> Void

    @State private var scene = GameScene()

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                SpriteView(scene: configure(scene, for: proxy.size))
                    .ignoresSafeArea()

                HUDOverlay(state: state)
                    .opacity(state.isGameOver ? 0 : 1)

                if state.isGameOver {
                    GameOverView(
                        score: state.score,
                        best: state.best,
                        isNewBest: state.isNewBest,
                        onRestart: { scene.restart() },
                        onMenu: {
                            AudioManager.shared.stopMusic()
                            onExit()
                        }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: state.isGameOver)
            .onAppear {
                state.reset()
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
