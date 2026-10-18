import SwiftUI

public struct MissionsView: View {
    @ObservedObject var gameState: GameState

    public init(gameState: GameState) {
        self.gameState = gameState
    }

    public var body: some View {
        ZStack {
            Color(hex: "#090D16").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
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

                    Text("MISSIONS")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)

                    Spacer()

                    // Coins
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

                // Missions List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(gameState.missions) { mission in
                            MissionCard(mission: mission, gameState: gameState)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Mission Card
private struct MissionCard: View {
    let mission: Mission
    @ObservedObject var gameState: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(mission.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Reward Badge
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#F59E0B"))
                    Text("+\(mission.rewardCoins)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "#FEF08A"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "#F59E0B").opacity(0.2))
                .clipShape(Capsule())
            }

            // Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#38BDF8"), Color(hex: "#22C55E")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(mission.progress), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(min(mission.currentValue, mission.targetValue)) / \(mission.targetValue)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                }
            }

            // Claim Button
            HStack {
                Spacer()

                if mission.isClaimed {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                        Text("COMPLETED")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                } else if mission.isCompleted {
                    Button {
                        gameState.claimMissionReward(mission)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill")
                            Text("CLAIM REWARD")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#FEF08A"))
                        .clipShape(Capsule())
                    }
                } else {
                    Text("IN PROGRESS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
