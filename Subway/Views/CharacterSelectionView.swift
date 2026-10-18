import SwiftUI

public struct CharacterSelectionView: View {
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

                    Text("RUNNERS")
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

                // Character Cards ScrollView
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(CharacterModel.allCharacters) { character in
                            CharacterCard(character: character, gameState: gameState)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Character Card
private struct CharacterCard: View {
    let character: CharacterModel
    @ObservedObject var gameState: GameState

    var isSelected: Bool {
        gameState.selectedCharacterId == character.id
    }

    var isUnlocked: Bool {
        gameState.unlockedCharacterIds.contains(character.id)
    }

    var canAfford: Bool {
        gameState.totalCoins >= character.cost
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                // Character Icon Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(character.outfitColor.opacity(0.2))
                        .frame(width: 58, height: 58)
                    Image(systemName: character.icon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(character.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(character.name)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("• \(character.title)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Text(character.bio)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()
            }

            // Perk Box
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(character.accentColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text(character.perkTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(character.accentColor)
                    Text(character.perkDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding(10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Action Button
            HStack {
                Spacer()

                if isSelected {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("EQUIPPED")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#22C55E"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#22C55E").opacity(0.18))
                    .clipShape(Capsule())
                } else if isUnlocked {
                    Button {
                        gameState.selectCharacter(character)
                    } label: {
                        Text("EQUIP")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#38BDF8"))
                            .clipShape(Capsule())
                    }
                } else {
                    Button {
                        _ = gameState.unlockCharacter(character)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("\(character.cost) COINS")
                                .font(.system(size: 13, weight: .heavy))
                        }
                        .foregroundColor(canAfford ? .black : .white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(canAfford ? Color(hex: "#FEF08A") : Color.white.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .disabled(!canAfford)
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color(hex: "#22C55E") : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
        )
    }
}
