import SwiftUI

public struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var sound = SoundManager.shared
    @State private var showResetAlert = false

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
                        sound.playTap()
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

                    Text("SETTINGS")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)

                    Spacer()

                    Color.clear.frame(width: 50, height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        // Game Preferences
                        VStack(spacing: 0) {
                            ToggleRow(
                                icon: "speaker.wave.2.fill",
                                title: "Sound Effects",
                                isOn: $sound.isSoundEnabled
                            )
                            Divider().background(Color.white.opacity(0.1))
                            ToggleRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "Haptic Feedback",
                                isOn: $sound.isHapticsEnabled
                            )
                            Divider().background(Color.white.opacity(0.1))
                            ToggleRow(
                                icon: "hand.tap.fill",
                                title: "On-Screen Touch Buttons",
                                isOn: $gameState.showTouchControls
                            )
                        }
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))

                        // How To Play Guide
                        VStack(alignment: .leading, spacing: 14) {
                            Text("HOW TO PLAY")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)

                            VStack(spacing: 12) {
                                ControlGuideRow(
                                    icon: "arrow.left.and.right",
                                    actionName: "Swipe Left / Right",
                                    description: "Switch between the 3 subway tracks"
                                )
                                ControlGuideRow(
                                    icon: "arrow.up",
                                    actionName: "Swipe Up",
                                    description: "Jump over hurdles, barriers & coin arcs"
                                )
                                ControlGuideRow(
                                    icon: "arrow.down",
                                    actionName: "Swipe Down",
                                    description: "Slide under overhead warning pipes"
                                )
                                ControlGuideRow(
                                    icon: "keyboard",
                                    actionName: "Arrow Keys",
                                    description: "Supported on Mac, iPad & Simulator"
                                )
                            }
                        }
                        .padding(18)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))

                        // Reset Progress Button
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Reset Game Progress")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#EF4444"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#EF4444").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#EF4444").opacity(0.3), lineWidth: 1))
                        }
                        .alert("Reset Progress?", isPresented: $showResetAlert) {
                            Button("Cancel", role: .cancel) {}
                            Button("Reset Everything", role: .destructive) {
                                gameState.totalCoins = 0
                                gameState.highScore = 0
                                gameState.selectedCharacterId = "jack"
                                gameState.unlockedCharacterIds = ["jack"]
                                gameState.missions = Mission.defaultMissions
                            }
                        } message: {
                            Text("This will reset your High Score, Coins, and unlocked characters back to defaults.")
                        }

                        // Version Footnote
                        VStack(spacing: 4) {
                            Text("Subway Rush • Version 1.0.0")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                            Text("Built natively with SwiftUI for iOS")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Toggle Row
private struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#38BDF8"))
                .frame(width: 28)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "#22C55E"))
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Control Guide Row
private struct ControlGuideRow: View {
    let icon: String
    let actionName: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#F59E0B"))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(actionName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()
        }
    }
}
