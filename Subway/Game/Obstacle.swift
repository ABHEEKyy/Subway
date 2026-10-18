import Foundation
import SwiftUI

public enum ObstacleType: String, CaseIterable, Sendable {
    case train
    case hurdleLow
    case barrierHigh
    case trackBlock

    public var requiresJump: Bool {
        self == .hurdleLow
    }

    public var requiresSlide: Bool {
        self == .barrierHigh
    }

    public var lengthZ: Double {
        switch self {
        case .train: return 0.28
        case .hurdleLow: return 0.05
        case .barrierHigh: return 0.06
        case .trackBlock: return 0.08
        }
    }
}

public struct TrackObstacle: Identifiable, Sendable {
    public let id = UUID()
    public var lane: Int // -1 (Left), 0 (Center), 1 (Right)
    public var z: Double // 1.0 (horizon) down to 0.0 (player camera)
    public let type: ObstacleType
    public var speed: Double // relative speed
    public var hasCollided: Bool = false
    public var isCleared: Bool = false
    public var isMovingTrain: Bool = false
}

public struct TrackCoin: Identifiable, Sendable {
    public let id = UUID()
    public var lane: Int
    public var z: Double
    public var elevation: Double // 0.0 ground, 1.0 jump height, 1.8 train roof
    public var isCollected: Bool = false
}

public struct TrackPowerUp: Identifiable, Sendable {
    public let id = UUID()
    public var lane: Int
    public var z: Double
    public var type: PowerUpType
    public var elevation: Double = 0.0
    public var isCollected: Bool = false
}
