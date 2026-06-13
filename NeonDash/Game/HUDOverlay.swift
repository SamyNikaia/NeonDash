import SwiftUI

struct HUDOverlay: View {
    @ObservedObject var state: GameState

    var body: some View {
        VStack(spacing: 4) {
            Text("BEST  \(state.best)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.45))

            Text("\(state.score)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.4), radius: 8)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HUDOverlay(state: {
            let s = GameState()
            s.addPoint(); s.addPoint(); s.addPoint()
            return s
        }())
    }
}
