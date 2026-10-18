import Foundation

public enum MissionType: String, Codable, Sendable {
    case coinsInRun
    case scoreInRun
    case dodgeObstacles
    case powerupsUsed
    case totalCoins
}

public struct Mission: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let targetValue: Int
    public var currentValue: Int
    public let rewardCoins: Int
    public var isClaimed: Bool
    public let type: MissionType

    public var isCompleted: Bool {
        currentValue >= targetValue
    }

    public var progress: Double {
        guard targetValue > 0 else { return 1.0 }
        return min(1.0, Double(currentValue) / Double(targetValue))
    }

    public static let defaultMissions: [Mission] = [
        Mission(
            id: "m_first_run",
            title: "First Steps",
            description: "Score 500 points in a single metro sprint.",
            targetValue: 500,
            currentValue: 0,
            rewardCoins: 100,
            isClaimed: false,
            type: .scoreInRun
        ),
        Mission(
            id: "m_coin_grabber",
            title: "Gold Rush",
            description: "Collect 50 gold coins in one run.",
            targetValue: 50,
            currentValue: 0,
            rewardCoins: 150,
            isClaimed: false,
            type: .coinsInRun
        ),
        Mission(
            id: "m_train_dodger",
            title: "Express Dodger",
            description: "Dodge 10 oncoming subway trains or hurdles.",
            targetValue: 10,
            currentValue: 0,
            rewardCoins: 200,
            isClaimed: false,
            type: .dodgeObstacles
        ),
        Mission(
            id: "m_powerup_master",
            title: "Charged Up",
            description: "Grab 3 power-up crates across your runs.",
            targetValue: 3,
            currentValue: 0,
            rewardCoins: 250,
            isClaimed: false,
            type: .powerupsUsed
        ),
        Mission(
            id: "m_high_roller",
            title: "Subway Legend",
            description: "Score 3,000 points in a single legendary run.",
            targetValue: 3000,
            currentValue: 0,
            rewardCoins: 500,
            isClaimed: false,
            type: .scoreInRun
        )
    ]
}
