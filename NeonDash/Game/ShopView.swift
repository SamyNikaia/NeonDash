import SwiftUI

struct ShopView: View {
    @ObservedObject var state: GameState
    let onBack: () -> Void

    enum Tab: String, CaseIterable {
        case balls = "BALLS"
        case backgrounds = "BACKGROUNDS"
    }

    @State private var selectedTab: Tab = .balls

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.03, blue: 0.20), .black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                header
                tabBar
                ScrollView {
                    contentForTab
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 32)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 40, height: 40)
                    .background(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.leading, 18)

            Spacer()

            Text("SHOP")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .tracking(6)
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.25))
                    .frame(width: 11, height: 11)
                    .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.25).opacity(0.7), radius: 4)
                Text("\(state.coins)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            .padding(.trailing, 18)
        }
        .padding(.top, 16)
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTab == tab ? Color.white.opacity(0.10) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
    }

    @ViewBuilder
    private var contentForTab: some View {
        switch selectedTab {
        case .balls:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(SkinCatalog.ballSkins) { skin in
                    BallSkinCard(
                        skin: skin,
                        isUnlocked: state.unlockedBalls.contains(skin.id),
                        isEquipped: state.equippedBallId == skin.id,
                        canAfford: state.coins >= skin.cost,
                        onTap: { handleBallTap(skin) }
                    )
                }
            }
        case .backgrounds:
            VStack(spacing: 14) {
                ForEach(SkinCatalog.backgroundSkins) { skin in
                    BackgroundSkinCard(
                        skin: skin,
                        isUnlocked: state.unlockedBackgrounds.contains(skin.id),
                        isEquipped: state.equippedBackgroundId == skin.id,
                        canAfford: state.coins >= skin.cost,
                        onTap: { handleBackgroundTap(skin) }
                    )
                }
            }
        }
    }

    private func handleBallTap(_ skin: BallSkin) {
        if state.unlockedBalls.contains(skin.id) {
            state.equipBall(skin.id)
        } else if state.coins >= skin.cost {
            state.purchaseBall(skin.id)
        }
    }

    private func handleBackgroundTap(_ skin: BackgroundSkin) {
        if state.unlockedBackgrounds.contains(skin.id) {
            state.equipBackground(skin.id)
        } else if state.coins >= skin.cost {
            state.purchaseBackground(skin.id)
        }
    }
}

private struct BallSkinCard: View {
    let skin: BallSkin
    let isUnlocked: Bool
    let isEquipped: Bool
    let canAfford: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(skin.color).opacity(0.22))
                        .frame(width: 84, height: 84)
                    Circle()
                        .fill(Color(skin.color))
                        .frame(width: 34, height: 34)
                        .shadow(color: Color(skin.color).opacity(0.8), radius: 12)
                }
                .frame(maxWidth: .infinity)

                Text(skin.name)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.85))

                statusLabel
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isEquipped ? 0.10 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEquipped ? Color(skin.color) : Color.white.opacity(0.08), lineWidth: isEquipped ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked && !canAfford)
        .opacity(!isUnlocked && !canAfford ? 0.45 : 1)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if isEquipped {
            Text("EQUIPPED")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color(skin.color))
        } else if isUnlocked {
            Text("EQUIP")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.65))
        } else {
            HStack(spacing: 4) {
                Circle().fill(Color(red: 1, green: 0.85, blue: 0.25)).frame(width: 7, height: 7)
                Text("\(skin.cost)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(canAfford ? .white : .white.opacity(0.45))
            }
        }
    }
}

private struct BackgroundSkinCard: View {
    let skin: BackgroundSkin
    let isUnlocked: Bool
    let isEquipped: Bool
    let canAfford: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                paletteStrip
                    .frame(width: 80, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 6) {
                    Text(skin.name)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white)
                    statusLabel
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isEquipped ? 0.10 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEquipped ? accentForBg : Color.white.opacity(0.08), lineWidth: isEquipped ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked && !canAfford)
        .opacity(!isUnlocked && !canAfford ? 0.45 : 1)
    }

    private var paletteStrip: some View {
        HStack(spacing: 0) {
            ForEach(0..<skin.palettes.count, id: \.self) { i in
                LinearGradient(
                    colors: [Color(skin.palettes[i].top), Color(skin.palettes[i].bottom)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
    }

    private var accentForBg: Color {
        guard let mid = skin.palettes.last?.top else { return .white }
        return Color(mid)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if isEquipped {
            Text("EQUIPPED")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(accentForBg)
        } else if isUnlocked {
            Text("EQUIP")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.65))
        } else {
            HStack(spacing: 4) {
                Circle().fill(Color(red: 1, green: 0.85, blue: 0.25)).frame(width: 8, height: 8)
                Text("\(skin.cost)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(canAfford ? .white : .white.opacity(0.45))
            }
        }
    }
}

#Preview {
    ShopView(state: {
        let s = GameState()
        s.addCoins(150)
        return s
    }(), onBack: {})
}
