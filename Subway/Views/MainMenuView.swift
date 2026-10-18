import SwiftUI

public struct MainMenuView: View {
    @ObservedObject var gameState: GameState
    @State private var pulsePlayButton = false

    public init(gameState: GameState) {
        self.gameState = gameState
    }

    public var body: some View {
        ZStack {
            // Background metro gradient
            LinearGradient(
                colors: [
                    Color(hex: "#090D16"),
                    Color(hex: "#0F172A"),
                    Color(hex: "#020617")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Diagonal track neon ambient lines
            VStack(spacing: 40) {
                ForEach(0..<6) { _ in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#38BDF8").opacity(0.12),
                                    Color(hex: "#818CF8").opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5)
                        .rotationEffect(.degrees(-15))
                }
            }
            .offset(y: 40)
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Top Info Bar
                HStack {
                    // High Score Trophy
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Color(hex: "#F59E0B"))
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("BEST")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(gameState.highScore)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))

                    Spacer()

                    // Coin Purse
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(Color(hex: "#F59E0B"))
                            .font(.system(size: 13))
                        Text("\(gameState.totalCoins)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#FEF08A"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)

                Spacer()

                // Game Title Logo
                VStack(spacing: 4) {
                    Text("SUBWAY")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#E0F2FE"), Color(hex: "#38BDF8")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: "#0284C7").opacity(0.6), radius: 10, x: 0, y: 5)
                        .tracking(3)

                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color(hex: "#F59E0B"))
                            .frame(width: 32, height: 3)

                        Text("RUSH")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "#F59E0B"))
                            .tracking(6)

                        Rectangle()
                            .fill(Color(hex: "#F59E0B"))
                            .frame(width: 32, height: 3)
                    }
                }

                // Active Character Showcase Card
                let char = gameState.selectedCharacter
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(char.outfitColor.opacity(0.2))
                                .frame(width: 52, height: 52)
                            Image(systemName: char.icon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(char.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(char.name)
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("• \(char.title)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Text(char.perkDescription)
                                .font(.system(size: 12))
                                .foregroundColor(char.accentColor)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(char.accentColor.opacity(0.35), lineWidth: 1))
                .padding(.horizontal, 24)

                Spacer()

                // Big "TAP TO RUN" Play Button
                Button {
                    gameState.startGame()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 26, weight: .bold))
                        Text("TAP TO RUN")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .tracking(2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#22C55E"), Color(hex: "#15803D")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color(hex: "#22C55E").opacity(0.4), radius: pulsePlayButton ? 16 : 8, x: 0, y: 6)
                    .scaleEffect(pulsePlayButton ? 1.02 : 0.98)
                }
                .padding(.horizontal, 24)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        pulsePlayButton = true
                    }
                }

                // Bottom Navigation Row
                HStack(spacing: 16) {
                    MenuNavButton(icon: "person.crop.circle.fill", label: "RUNNERS") {
                        gameState.currentScreen = .characters
                    }
                    MenuNavButton(icon: "cart.fill", label: "UPGRADES") {
                        gameState.currentScreen = .shop
                    }
                    MenuNavButton(icon: "flag.checkered", label: "MISSIONS") {
                        gameState.currentScreen = .missions
                    }
                    MenuNavButton(icon: "gearshape.fill", label: "SETTINGS") {
                        gameState.currentScreen = .settings
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}

// MARK: - Menu Nav Button
private struct MenuNavButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            SoundManager.shared.playTap()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "#38BDF8"))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }
}
