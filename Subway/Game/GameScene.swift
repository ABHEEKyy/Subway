import SwiftUI

public struct GameSceneView: View {
    @ObservedObject var gameState: GameState
    @State private var dragStart: CGPoint? = nil
    @State private var lastTickDate = Date()

    public init(gameState: GameState) {
        self.gameState = gameState
    }

    public var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate

                    // 1. Draw 3D Tunnel & Tracks
                    GameRenderer.drawTunnel(
                        context: &context,
                        size: size,
                        trackOffset: gameState.trackOffset
                    )

                    // 2. Draw Obstacles (sorted back-to-front by depth z)
                    let sortedObstacles = gameState.obstacles.sorted(by: { $0.z > $1.z })
                    for obs in sortedObstacles {
                        GameRenderer.drawObstacle(context: &context, obstacle: obs, size: size)
                    }

                    // 3. Draw Coins
                    let sortedCoins = gameState.coins.sorted(by: { $0.z > $1.z })
                    for coin in sortedCoins {
                        GameRenderer.drawCoin(context: &context, coin: coin, size: size, time: time)
                    }

                    // 4. Draw Power-Ups
                    for pu in gameState.powerups {
                        GameRenderer.drawPowerUp(context: &context, powerup: pu, size: size, time: time)
                    }

                    // 5. Draw Player Character
                    GameRenderer.drawPlayer(
                        context: &context,
                        gameState: gameState,
                        size: size,
                        time: time
                    )
                }
                .onChange(of: timeline.date) { _, newDate in
                    let dt = newDate.timeIntervalSince(lastTickDate)
                    lastTickDate = newDate
                    gameState.tick(deltaTime: dt)
                }
            }
            .contentShape(Rectangle())
            // Gestures: High-precision swipe detection
            .gesture(
                DragGesture(minimumDistance: 15)
                    .onEnded { value in
                        handleSwipe(translation: value.translation)
                    }
            )
            // Keyboard arrows for Mac / iOS Simulator pairing
            .focusable()
            .onKeyPress(.leftArrow) {
                gameState.moveLeft()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                gameState.moveRight()
                return .handled
            }
            .onKeyPress(.upArrow) {
                gameState.jump()
                return .handled
            }
            .onKeyPress(.downArrow) {
                gameState.slide()
                return .handled
            }
        }
        .ignoresSafeArea()
    }

    private func handleSwipe(translation: CGSize) {
        let horizontal = translation.width
        let vertical = translation.height

        if abs(horizontal) > abs(vertical) {
            // Horizontal swipe
            if horizontal < -25 {
                gameState.moveLeft()
            } else if horizontal > 25 {
                gameState.moveRight()
            }
        } else {
            // Vertical swipe
            if vertical < -25 {
                gameState.jump()
            } else if vertical > 25 {
                gameState.slide()
            }
        }
    }
}
