import SwiftUI

public struct HUDView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var sound = SoundManager.shared

    public init(gameState: GameState) {
        self.gameState = gameState
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Header HUD Bar
                HStack(alignment: .top) {
                    // Pause Button
                    Button {
                        gameState.pauseGame()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }

                    Spacer()

                    // Center Stats: Distance & Multiplier
                    VStack(spacing: 4) {
                        Text("\(Int(gameState.distanceMeters)) m")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))

                        if gameState.currentMultiplier > 1.0 {
                            HStack(spacing: 3) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10, weight: .black))
                                Text(String(format: "%.0fX", gameState.currentMultiplier))
                                    .font(.system(size: 12, weight: .heavy))
                            }
                            .foregroundColor(Color(hex: "#38BDF8"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#0284C7").opacity(0.35))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(hex: "#38BDF8").opacity(0.5), lineWidth: 1))
                        }
                    }

                    Spacer()

                    // Right Side: Score & Coins
                    VStack(alignment: .trailing, spacing: 6) {
                        // Score
                        Text("\(Int(gameState.score))")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)

                        // Gold Coins
                        HStack(spacing: 5) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("\(gameState.coinsThisRun)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#FEF08A"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)

                // Active Power-ups Bar
                if !gameState.activePowerUps.isEmpty || gameState.hasShield {
                    HStack(spacing: 12) {
                        if gameState.hasShield {
                            PowerUpPill(
                                type: .shield,
                                remaining: 1.0,
                                maxDuration: 1.0,
                                isShield: true
                            )
                        }

                        ForEach(Array(gameState.activePowerUps.keys), id: \.self) { type in
                            let remaining = gameState.activePowerUps[type] ?? 0
                            let maxDur = gameState.powerUpMaxTimes[type] ?? 10
                            PowerUpPill(type: type, remaining: remaining, maxDuration: maxDur)
                        }
                    }
                    .padding(.top, 10)
                }

                Spacer()

                // Optional On-Screen Arrow Touch Controls (for ease of testing or preference)
                if gameState.showTouchControls {
                    HStack(spacing: 24) {
                        // Left / Right lane controls
                        HStack(spacing: 14) {
                            ControlButton(icon: "arrow.left") {
                                gameState.moveLeft()
                            }
                            ControlButton(icon: "arrow.right") {
                                gameState.moveRight()
                            }
                        }

                        Spacer()

                        // Jump / Slide controls
                        HStack(spacing: 14) {
                            ControlButton(icon: "arrow.up", label: "JUMP") {
                                gameState.jump()
                            }
                            ControlButton(icon: "arrow.down", label: "SLIDE") {
                                gameState.slide()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }

            // Pause Overlay Modal
            if gameState.isPaused {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 24) {
                    Text("GAME PAUSED")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)

                    VStack(spacing: 14) {
                        Button {
                            gameState.resumeGame()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("RESUME")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#22C55E"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            gameState.startGame()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("RESTART")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            gameState.currentScreen = .menu
                            gameState.isPaused = false
                        } label: {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("MAIN MENU")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .frame(maxWidth: 260)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 30)
            }
        }
    }
}

// MARK: - Active Power-up Pill
private struct PowerUpPill: View {
    let type: PowerUpType
    let remaining: Double
    let maxDuration: Double
    var isShield: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2.5)
                    .frame(width: 26, height: 26)

                Circle()
                    .trim(from: 0, to: isShield ? 1.0 : CGFloat(remaining / max(0.1, maxDuration)))
                    .stroke(type.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 26, height: 26)

                Image(systemName: type.iconName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(type.color)
            }

            if !isShield {
                Text(String(format: "%.1fs", remaining))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(type.color.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - On-screen touch button
private struct ControlButton: View {
    let icon: String
    var label: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                if let label = label {
                    Text(label)
                        .font(.system(size: 9, weight: .heavy))
                }
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(.ultraThinMaterial.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
        }
    }
}
