import SwiftUI

public struct ShopView: View {
    @ObservedObject var gameState: GameState

    public init(gameState: GameState) {
        self.gameState = gameState
    }

    public var body: some View {
        ZStack {
            Color(hex: "#090D16").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar
                HStack {
                    Button {
                        SoundManager.shared.playTap()
                        gameState.currentScreen = .menu
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Menu")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#38BDF8"))
                    }

                    Spacer()

                    Text("UPGRADES")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)

                    Spacer()

                    // Coin Balance
                    HStack(spacing: 5) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#F59E0B"))
                        Text("\(gameState.totalCoins)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#FEF08A"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)

                // Scrollable Upgrades List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(PowerUpType.allCases) { type in
                            UpgradeCard(type: type, gameState: gameState)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Upgrade Card
private struct UpgradeCard: View {
    let type: PowerUpType
    @ObservedObject var gameState: GameState

    var currentLevel: Int {
        gameState.level(for: type)
    }

    var cost: Int {
        type.upgradeCost(forLevel: currentLevel)
    }

    var isMax: Bool {
        currentLevel >= 5
    }

    var canAfford: Bool {
        gameState.totalCoins >= cost && !isMax
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(type.color.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: type.iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(type.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.displayName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(type.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(2)
                }

                Spacer()
            }

            // Level Progress Pips & Upgrade Button
            HStack {
                // Level Indicator Pips
                HStack(spacing: 5) {
                    ForEach(1...5, id: \.self) { lvl in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(lvl <= currentLevel ? type.color : Color.white.opacity(0.15))
                            .frame(width: 22, height: 8)
                    }
                }

                Spacer()

                // Button
                Button {
                    _ = gameState.upgradePowerUp(type)
                } label: {
                    if isMax {
                        Text("MAXED")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("\(cost)")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(canAfford ? .black : .white.opacity(0.4))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(canAfford ? Color(hex: "#FEF08A") : Color.white.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                .disabled(!canAfford)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
