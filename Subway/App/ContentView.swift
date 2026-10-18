import SwiftUI

public struct ContentView: View {
    @StateObject private var gameState = GameState.shared

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch gameState.currentScreen {
            case .menu:
                MainMenuView(gameState: gameState)
                    .transition(.opacity)

            case .playing:
                ZStack {
                    GameSceneView(gameState: gameState)
                    HUDView(gameState: gameState)
                }
                .transition(.opacity)

            case .gameOver:
                ZStack {
                    GameSceneView(gameState: gameState)
                    GameOverView(gameState: gameState)
                }
                .transition(.opacity)

            case .shop:
                ShopView(gameState: gameState)
                    .transition(.move(edge: .trailing))

            case .characters:
                CharacterSelectionView(gameState: gameState)
                    .transition(.move(edge: .trailing))

            case .missions:
                MissionsView(gameState: gameState)
                    .transition(.move(edge: .trailing))

            case .settings:
                SettingsView(gameState: gameState)
                    .transition(.move(edge: .trailing))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: gameState.currentScreen)
    }
}
