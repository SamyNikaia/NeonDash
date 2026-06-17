import SwiftUI

struct ContentView: View {
    @StateObject private var flow = AppFlow()
    @StateObject private var state = GameState()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch flow.screen {
            case .menu:
                MenuView(state: state, onPlay: flow.play, onShop: flow.openShop)
                    .transition(.opacity)
            case .playing:
                GameView(state: state, onExit: flow.backToMenu)
                    .transition(.opacity)
            case .shop:
                ShopPlaceholderView(onBack: flow.backToMenu)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: flow.screen)
    }
}

private struct ShopPlaceholderView: View {
    let onBack: () -> Void
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("SHOP")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(.white)
                Text("Bientôt")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                Button(action: onBack) {
                    Text("BACK")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ContentView()
}
