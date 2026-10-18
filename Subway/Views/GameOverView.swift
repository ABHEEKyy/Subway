import SwiftUI

public struct GameOverView: View {
    @ObservedObject var gameState: GameState

    public init(gameState: GameState) {
        self.gameState = gameState
    }

    public var body: some View {
        ZStack {
            // Dark vignette background
            Color(hex: "#090D16").opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // High score badge or crash banner
                if gameState.isNewHighScore {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("NEW HIGH SCORE!")
                            .fontWeight(.black)
                        Image(systemName: "sparkles")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#FEF08A"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#F59E0B").opacity(0.3))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(hex: "#F59E0B"), lineWidth: 1.5))
                } else {
                    Text("RUN OVER")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(3)
                }

                // Final Score
                VStack(spacing: 4) {
                    Text("FINAL SCORE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)

                    Text("\(Int(gameState.score))")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                // Run Stats Card
                VStack(spacing: 14) {
                    HStack {
                        StatItem(
                            icon: "circle.fill",
                            iconColor: Color(hex: "#F59E0B"),
                            label: "COINS EARNED",
                            value: "+\(gameState.coinsThisRun)"
                        )
                        Divider().background(Color.white.opacity(0.2))
                        StatItem(
                            icon: "location.fill",
                            iconColor: Color(hex: "#38BDF8"),
                            label: "DISTANCE",
                            value: "\(Int(gameState.distanceMeters)) m"
                        )
                        Divider().background(Color.white.opacity(0.2))
                        StatItem(
                            icon: "shield.slash.fill",
                            iconColor: Color(hex: "#EC4899"),
                            label: "DODGED",
                            value: "\(gameState.obstaclesDodged)"
                        )
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 24)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        gameState.startGame()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20, weight: .bold))
                            Text("RUN AGAIN")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color(hex: "#22C55E").opacity(0.4), radius: 8, x: 0, y: 4)
                    }

                    HStack(spacing: 12) {
                        Button {
                            SoundManager.shared.playTap()
                            gameState.currentScreen = .shop
                        } label: {
                            HStack {
                                Image(systemName: "cart.fill")
                                Text("SHOP")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(Color(hex: "#38BDF8"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#38BDF8").opacity(0.3), lineWidth: 1))
                        }

                        Button {
                            SoundManager.shared.playTap()
                            gameState.currentScreen = .menu
                        } label: {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("MENU")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
