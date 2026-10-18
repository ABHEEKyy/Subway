import SwiftUI

public enum PowerUpType: String, CaseIterable, Identifiable, Codable {
    case magnet
    case multiplier2x
    case sneakers
    case shield
    case jetpack

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .magnet: return "Coin Magnet"
        case .multiplier2x: return "2X Multiplier"
        case .sneakers: return "Super Sneakers"
        case .shield: return "Energy Shield"
        case .jetpack: return "Turbo Jetpack"
        }
    }

    public var iconName: String {
        switch self {
        case .magnet: return "magnet"
        case .multiplier2x: return "bolt.fill"
        case .sneakers: return "shoeprints.fill"
        case .shield: return "shield.lefthalf.filled"
        case .jetpack: return "flame.fill"
        }
    }

    public var color: Color {
        switch self {
        case .magnet: return Color(red: 0.95, green: 0.25, blue: 0.35) // Neon Red/Pink
        case .multiplier2x: return Color(red: 0.2, green: 0.85, blue: 1.0) // Electric Cyan
        case .sneakers: return Color(red: 0.3, green: 0.95, blue: 0.45) // Neon Green
        case .shield: return Color(red: 0.65, green: 0.4, blue: 1.0) // Electric Purple
        case .jetpack: return Color(red: 1.0, green: 0.6, blue: 0.0) // Fiery Orange
        }
    }

    public var description: String {
        switch self {
        case .magnet: return "Attracts all subway coins automatically from every track."
        case .multiplier2x: return "Doubles your score accumulation rate while running."
        case .sneakers: return "Enables super high spring jumps to leap clean over obstacles."
        case .shield: return "Surrounds you with an energy barrier that absorbs 1 collision."
        case .jetpack: return "Launches you onto the overhead high-line skyway full of coins."
        }
    }

    public var baseDuration: Double {
        switch self {
        case .magnet: return 10.0
        case .multiplier2x: return 12.0
        case .sneakers: return 10.0
        case .shield: return 15.0
        case .jetpack: return 8.0
        }
    }

    public func duration(forLevel level: Int) -> Double {
        return baseDuration + Double(level - 1) * 2.5
    }

    public func upgradeCost(forLevel currentLevel: Int) -> Int {
        guard currentLevel < 5 else { return 0 }
        return 200 * currentLevel
    }
}
