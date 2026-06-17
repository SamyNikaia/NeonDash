import SwiftUI

struct GameOverView: View {
    let score: Int
    let best: Int
    let isNewBest: Bool
    let onRestart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onRestart() }

            VStack(spacing: 28) {
                Text("GAME OVER")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 1, green: 0.17, blue: 0.84).opacity(0.8), radius: 14)

                VStack(spacing: 6) {
                    Text("\(score)")
                        .font(.system(size: 88, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.35), radius: 12)

                    if isNewBest {
                        Text("NEW BEST")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .tracking(5)
                            .foregroundStyle(Color(red: 1, green: 0.17, blue: 0.84))
                    } else {
                        Text("BEST  \(best)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Text("TAP TO RESTART")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 18)
            }

            VStack {
                Spacer()
                Button(action: onMenu) {
                    Text("MENU")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 36)
            }
        }
    }
}

#Preview {
    GameOverView(score: 42, best: 31, isNewBest: true, onRestart: {}, onMenu: {})
}
