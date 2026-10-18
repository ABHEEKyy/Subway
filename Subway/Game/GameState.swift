import SwiftUI
import Combine

public enum GameScreen {
    case menu
    case playing
    case gameOver
    case shop
    case characters
    case missions
    case settings
}

public enum PlayerActionState {
    case running
    case jumping
    case sliding
    case jetpackFlying
    case crashed
}

@MainActor
public final class GameState: ObservableObject {
    public static let shared = GameState()

    // MARK: - Navigation
    @Published public var currentScreen: GameScreen = .menu
    @Published public var isPaused: Bool = false

    // MARK: - Persistent Player Data
    @Published public var totalCoins: Int {
        didSet { UserDefaults.standard.set(totalCoins, forKey: "subway_total_coins") }
    }
    @Published public var highScore: Int {
        didSet { UserDefaults.standard.set(highScore, forKey: "subway_high_score") }
    }
    @Published public var selectedCharacterId: String {
        didSet { UserDefaults.standard.set(selectedCharacterId, forKey: "subway_selected_char") }
    }
    @Published public var unlockedCharacterIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(unlockedCharacterIds), forKey: "subway_unlocked_chars")
        }
    }
    @Published public var powerUpLevels: [String: Int] {
        didSet {
            UserDefaults.standard.set(powerUpLevels, forKey: "subway_pu_levels")
        }
    }
    @Published public var missions: [Mission] {
        didSet {
            if let data = try? JSONEncoder().encode(missions) {
                UserDefaults.standard.set(data, forKey: "subway_missions")
            }
        }
    }
    @Published public var showTouchControls: Bool {
        didSet {
            UserDefaults.standard.set(showTouchControls, forKey: "subway_touch_controls")
        }
    }

    // MARK: - Current Run State
    @Published public var score: Double = 0
    @Published public var coinsThisRun: Int = 0
    @Published public var distanceMeters: Double = 0
    @Published public var isNewHighScore: Bool = false
    @Published public var obstaclesDodged: Int = 0
    @Published public var powerupsUsedThisRun: Int = 0

    // Lanes: -1 (Left), 0 (Center), +1 (Right)
    @Published public var targetLane: Int = 0
    @Published public var currentLanePos: Double = 0.0

    // Player action states
    @Published public var playerAction: PlayerActionState = .running
    @Published public var jumpProgress: Double = 0.0 // 0 to 1
    @Published public var slideProgress: Double = 0.0 // 0 to 1
    @Published public var jetpackProgress: Double = 0.0 // 0 to 1
    @Published public var hasShield: Bool = false
    @Published public var shieldPulse: Double = 0.0

    // Active power-ups: type -> remaining seconds
    @Published public var activePowerUps: [PowerUpType: Double] = [:]
    @Published public var powerUpMaxTimes: [PowerUpType: Double] = [:]

    // Track Objects
    @Published public var obstacles: [TrackObstacle] = []
    @Published public var coins: [TrackCoin] = []
    @Published public var powerups: [TrackPowerUp] = []

    // Tunnel Environment
    @Published public var trackOffset: Double = 0.0
    @Published public var speed: Double = 0.42

    // Internal timers & generation
    private var nextSpawnZ: Double = 1.0
    private var lastSpawnZ: Double = 1.0
    private var runTime: Double = 0.0
    private var jumpVelocity: Double = 0.0
    private var playerElevation: Double = 0.0

    public init() {
        self.totalCoins = UserDefaults.standard.integer(forKey: "subway_total_coins")
        self.highScore = UserDefaults.standard.integer(forKey: "subway_high_score")
        self.selectedCharacterId = UserDefaults.standard.string(forKey: "subway_selected_char") ?? "jack"
        self.showTouchControls = UserDefaults.standard.object(forKey: "subway_touch_controls") as? Bool ?? true

        let savedUnlocked = UserDefaults.standard.stringArray(forKey: "subway_unlocked_chars") ?? ["jack"]
        self.unlockedCharacterIds = Set(savedUnlocked)

        let savedLevels = UserDefaults.standard.dictionary(forKey: "subway_pu_levels") as? [String: Int] ?? [:]
        var defaultLevels: [String: Int] = [:]
        for type in PowerUpType.allCases {
            defaultLevels[type.rawValue] = savedLevels[type.rawValue] ?? 1
        }
        self.powerUpLevels = defaultLevels

        if let data = UserDefaults.standard.data(forKey: "subway_missions"),
           let loaded = try? JSONDecoder().decode([Mission].self, from: data) {
            self.missions = loaded
        } else {
            self.missions = Mission.defaultMissions
        }
    }

    public var selectedCharacter: CharacterModel {
        CharacterModel.allCharacters.first { $0.id == selectedCharacterId } ?? CharacterModel.allCharacters[0]
    }

    public func level(for powerUp: PowerUpType) -> Int {
        powerUpLevels[powerUp.rawValue] ?? 1
    }

    public var currentMultiplier: Double {
        var mult = 1.0 * selectedCharacter.multiplierBonus
        if activePowerUps[.multiplier2x] != nil {
            mult *= 2.0
        }
        return mult
    }

    // MARK: - Game Lifecycle
    public func startGame() {
        SoundManager.shared.playTap()
        SoundManager.shared.resetCoinStreak()

        score = 0
        coinsThisRun = 0
        distanceMeters = 0
        isNewHighScore = false
        obstaclesDodged = 0
        powerupsUsedThisRun = 0

        targetLane = 0
        currentLanePos = 0.0
        playerAction = .running
        jumpProgress = 0.0
        slideProgress = 0.0
        jetpackProgress = 0.0
        playerElevation = 0.0

        activePowerUps.removeAll()
        powerUpMaxTimes.removeAll()

        hasShield = selectedCharacter.startsWithShield
        speed = 0.45
        runTime = 0.0
        trackOffset = 0.0

        obstacles.removeAll()
        coins.removeAll()
        powerups.removeAll()

        // Seed initial tracks with coins and obstacles
        seedInitialTrack()

        isPaused = false
        currentScreen = .playing
    }

    public func pauseGame() {
        guard currentScreen == .playing else { return }
        isPaused = true
        SoundManager.shared.playTap()
    }

    public func resumeGame() {
        isPaused = false
        SoundManager.shared.playTap()
    }

    public func endGame() {
        playerAction = .crashed
        SoundManager.shared.playCrash()

        let finalScoreInt = Int(score)
        if finalScoreInt > highScore {
            highScore = finalScoreInt
            isNewHighScore = true
        }

        totalCoins += coinsThisRun

        // Update missions
        updateMissionsOnEndRun()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.currentScreen = .gameOver
        }
    }

    // MARK: - Controls
    public func moveLeft() {
        guard currentScreen == .playing, !isPaused, playerAction != .crashed else { return }
        if targetLane > -1 {
            targetLane -= 1
            SoundManager.shared.playLaneChange()
        }
    }

    public func moveRight() {
        guard currentScreen == .playing, !isPaused, playerAction != .crashed else { return }
        if targetLane < 1 {
            targetLane += 1
            SoundManager.shared.playLaneChange()
        }
    }

    public func jump() {
        guard currentScreen == .playing, !isPaused, playerAction != .crashed else { return }
        guard playerAction != .jumping && playerAction != .jetpackFlying else { return }

        playerAction = .jumping
        jumpProgress = 0.0
        slideProgress = 0.0
        SoundManager.shared.playJump()
    }

    public func slide() {
        guard currentScreen == .playing, !isPaused, playerAction != .crashed else { return }
        guard playerAction != .jetpackFlying else { return }

        // Fast drop if jumping
        if playerAction == .jumping {
            jumpProgress = 1.0
        }

        playerAction = .sliding
        slideProgress = 0.0
        SoundManager.shared.playSlide()
    }

    // MARK: - Main Game Loop Tick
    public func tick(deltaTime: Double) {
        guard currentScreen == .playing, !isPaused, playerAction != .crashed else { return }

        let dt = min(deltaTime, 0.05)
        runTime += dt

        // Accelerate speed gradually
        speed = min(0.92, 0.45 + (runTime * 0.005))

        // Distance & Score
        let frameDistance = speed * dt * 45.0
        distanceMeters += frameDistance
        score += frameDistance * currentMultiplier * 1.5

        // Track animation offset
        trackOffset = (trackOffset + speed * dt * 2.8).truncatingRemainder(dividingBy: 1.0)

        // Smooth lane transition
        let laneDifference = Double(targetLane) - currentLanePos
        currentLanePos += laneDifference * min(1.0, dt * 18.0)

        // Jump animation physics
        if playerAction == .jumping {
            let jumpSpeed = (activePowerUps[.sneakers] != nil ? 1.6 : 2.1) * (1.0 / selectedCharacter.jumpMultiplier)
            jumpProgress += dt * jumpSpeed
            if jumpProgress >= 1.0 {
                jumpProgress = 0.0
                playerAction = .running
                playerElevation = 0.0
            } else {
                // Parabolic arc: sin(progress * pi)
                let arc = sin(jumpProgress * .pi)
                let peakHeight = activePowerUps[.sneakers] != nil ? 1.85 : 1.2
                playerElevation = arc * peakHeight
            }
        }

        // Slide animation
        if playerAction == .sliding {
            slideProgress += dt * 2.4
            if slideProgress >= 1.0 {
                slideProgress = 0.0
                playerAction = .running
            }
        }

        // Jetpack mode
        if let jetpackTime = activePowerUps[.jetpack], jetpackTime > 0 {
            playerAction = .jetpackFlying
            playerElevation = 2.4
        } else if playerAction == .jetpackFlying {
            playerAction = .running
            playerElevation = 0.0
        }

        // Shield pulse animation
        if hasShield {
            shieldPulse = (shieldPulse + dt * 3.0).truncatingRemainder(dividingBy: .pi * 2)
        }

        // Update active powerups
        var expired: [PowerUpType] = []
        for (type, remaining) in activePowerUps {
            let newTime = remaining - dt
            if newTime <= 0 {
                expired.append(type)
            } else {
                activePowerUps[type] = newTime
            }
        }
        for type in expired {
            activePowerUps.removeValue(forKey: type)
        }

        // Advance objects on track
        advanceTrackObjects(dt: dt)

        // Magnet attraction
        applyCoinMagnet(dt: dt)

        // Collision detection
        checkCollisions()

        // Spawning new hazards and rewards
        spawnStep(dt: dt)
    }

    // MARK: - Object Advancement
    private func advanceTrackObjects(dt: Double) {
        // Move obstacles
        for i in obstacles.indices {
            let moveRate = speed * (obstacles[i].isMovingTrain ? 1.35 : 1.0)
            obstacles[i].z -= dt * moveRate

            // Check if cleared player without hit
            if !obstacles[i].isCleared && obstacles[i].z < 0.05 {
                obstacles[i].isCleared = true
                obstaclesDodged += 1
            }
        }
        obstacles.removeAll { $0.z < -0.15 }

        // Move coins
        for i in coins.indices {
            coins[i].z -= dt * speed
        }
        coins.removeAll { $0.z < -0.15 || $0.isCollected }

        // Move powerups
        for i in powerups.indices {
            powerups[i].z -= dt * speed
        }
        powerups.removeAll { $0.z < -0.15 || $0.isCollected }
    }

    // MARK: - Magnet Pull
    private func applyCoinMagnet(dt: Double) {
        let hasMagnet = activePowerUps[.magnet] != nil

        for i in coins.indices {
            guard !coins[i].isCollected else { continue }
            let dz = abs(coins[i].z - 0.08)
            let dx = abs(Double(coins[i].lane) - currentLanePos)

            if hasMagnet && coins[i].z < 0.65 {
                // Pull smoothly towards player
                coins[i].lane = targetLane
                coins[i].z -= dt * 0.4
            }

            // Pickup reach
            if dz < 0.08 && dx < 0.65 {
                collectCoin(at: i)
            }
        }
    }

    private func collectCoin(at index: Int) {
        guard index < coins.count, !coins[index].isCollected else { return }
        coins[index].isCollected = true
        coinsThisRun += 1
        score += 25 * currentMultiplier
        SoundManager.shared.playCoin()
    }

    // MARK: - Collision Checking
    private func checkCollisions() {
        guard playerAction != .crashed else { return }

        // Check powerup crates
        for i in powerups.indices {
            guard !powerups[i].isCollected else { continue }
            let dz = abs(powerups[i].z - 0.08)
            let dx = abs(Double(powerups[i].lane) - currentLanePos)
            if dz < 0.09 && dx < 0.55 {
                activatePowerUp(powerups[i].type)
                powerups[i].isCollected = true
            }
        }

        // When flying on skyway, immune to ground obstacles!
        if playerAction == .jetpackFlying {
            return
        }

        // Check obstacles
        for i in obstacles.indices {
            guard !obstacles[i].hasCollided else { continue }
            let obs = obstacles[i]
            let dz = obs.z - 0.06
            let inDepth = dz > -0.06 && dz < obs.type.lengthZ
            let inLane = abs(Double(obs.lane) - currentLanePos) < 0.52

            if inDepth && inLane {
                // Check if jumping over low hurdle
                if obs.type == .hurdleLow && playerElevation > 0.55 {
                    continue // Cleared with jump!
                }

                // Check if sliding under high barrier
                if obs.type == .barrierHigh && playerAction == .sliding {
                    continue // Cleared with slide!
                }

                // Collision occurred!
                obstacles[i].hasCollided = true

                if hasShield {
                    // Shield absorbs impact!
                    hasShield = false
                    SoundManager.shared.playShieldBreak()
                    // Knock obstacle away
                    obstacles[i].z = -0.2
                } else {
                    endGame()
                    return
                }
            }
        }
    }

    public func activatePowerUp(_ type: PowerUpType) {
        powerupsUsedThisRun += 1
        SoundManager.shared.playPowerUp()

        if type == .shield {
            hasShield = true
            return
        }

        let lvl = level(for: type)
        let dur = type.duration(forLevel: lvl)
        activePowerUps[type] = dur
        powerUpMaxTimes[type] = dur

        if type == .jetpack {
            // Spawn skyway coins ahead
            spawnSkywayCoins()
        }
    }

    // MARK: - Procedural Track Generator
    private func seedInitialTrack() {
        var z = 0.5
        for _ in 0..<6 {
            spawnTrackSegment(atZ: z)
            z += 0.35
        }
        lastSpawnZ = z
    }

    private func spawnStep(dt: Double) {
        lastSpawnZ -= dt * speed
        if lastSpawnZ < 1.15 {
            spawnTrackSegment(atZ: lastSpawnZ + 0.38)
            lastSpawnZ += 0.38
        }
    }

    private func spawnTrackSegment(atZ z: Double) {
        let pattern = Int.random(in: 0...6)
        let randomLane = Int.random(in: -1...1)
        let otherLanes = [-1, 0, 1].filter { $0 != randomLane }
        let secondLane = otherLanes.randomElement() ?? 0

        switch pattern {
        case 0:
            // Single oncoming or parked train
            let isMoving = Bool.random()
            obstacles.append(TrackObstacle(lane: randomLane, z: z, type: .train, speed: isMoving ? 0.2 : 0.0, isMovingTrain: isMoving))
            // Coins in other lane
            spawnCoinRow(lane: secondLane, startZ: z, count: 4)

        case 1:
            // Low hurdle with coins arc jumping over it
            obstacles.append(TrackObstacle(lane: randomLane, z: z, type: .hurdleLow, speed: 0.0))
            spawnCoinArc(lane: randomLane, startZ: z - 0.05)

        case 2:
            // High warning sign requiring slide
            obstacles.append(TrackObstacle(lane: randomLane, z: z, type: .barrierHigh, speed: 0.0))
            spawnCoinRow(lane: randomLane, startZ: z - 0.06, count: 3)

        case 3:
            // Two obstacles, one free escape lane
            obstacles.append(TrackObstacle(lane: randomLane, z: z, type: .hurdleLow, speed: 0.0))
            obstacles.append(TrackObstacle(lane: secondLane, z: z + 0.12, type: .train, speed: 0.0))
            let freeLane = ([-1, 0, 1].filter { $0 != randomLane && $0 != secondLane }).first ?? 0
            spawnCoinRow(lane: freeLane, startZ: z, count: 4)

        case 4:
            // Power-up chance
            let puType = PowerUpType.allCases.randomElement() ?? .magnet
            powerups.append(TrackPowerUp(lane: randomLane, z: z, type: puType))
            spawnCoinRow(lane: secondLane, startZ: z, count: 3)

        default:
            // Pure coin strip & light hurdle
            spawnCoinRow(lane: randomLane, startZ: z, count: 5)
            if Bool.random() {
                obstacles.append(TrackObstacle(lane: secondLane, z: z + 0.15, type: .trackBlock, speed: 0.0))
            }
        }
    }

    private func spawnCoinRow(lane: Int, startZ: Double, count: Int) {
        for i in 0..<count {
            coins.append(TrackCoin(lane: lane, z: startZ + Double(i) * 0.06, elevation: 0.0))
        }
    }

    private func spawnCoinArc(lane: Int, startZ: Double) {
        let count = 5
        for i in 0..<count {
            let progress = Double(i) / Double(count - 1)
            let elev = sin(progress * .pi) * 1.25
            coins.append(TrackCoin(lane: lane, z: startZ + Double(i) * 0.05, elevation: elev))
        }
    }

    private func spawnSkywayCoins() {
        for i in 0..<18 {
            let lane = (i % 3) - 1
            coins.append(TrackCoin(lane: lane, z: 0.8 + Double(i) * 0.08, elevation: 2.4))
        }
    }

    // MARK: - Missions & Unlocks
    private func updateMissionsOnEndRun() {
        for i in missions.indices {
            guard !missions[i].isClaimed else { continue }
            switch missions[i].type {
            case .scoreInRun:
                if Int(score) > missions[i].currentValue {
                    missions[i].currentValue = Int(score)
                }
            case .coinsInRun:
                if coinsThisRun > missions[i].currentValue {
                    missions[i].currentValue = coinsThisRun
                }
            case .dodgeObstacles:
                missions[i].currentValue += obstaclesDodged
            case .powerupsUsed:
                missions[i].currentValue += powerupsUsedThisRun
            case .totalCoins:
                missions[i].currentValue = totalCoins
            }
        }
    }

    public func claimMissionReward(_ mission: Mission) {
        guard let index = missions.firstIndex(where: { $0.id == mission.id }),
              missions[index].isCompleted,
              !missions[index].isClaimed else { return }

        missions[index].isClaimed = true
        totalCoins += mission.rewardCoins
        SoundManager.shared.playPowerUp()
    }

    public func unlockCharacter(_ character: CharacterModel) -> Bool {
        guard totalCoins >= character.cost, !unlockedCharacterIds.contains(character.id) else {
            return false
        }
        totalCoins -= character.cost
        unlockedCharacterIds.insert(character.id)
        selectedCharacterId = character.id
        SoundManager.shared.playPowerUp()
        return true
    }

    public func selectCharacter(_ character: CharacterModel) {
        guard unlockedCharacterIds.contains(character.id) else { return }
        selectedCharacterId = character.id
        SoundManager.shared.playTap()
    }

    public func upgradePowerUp(_ type: PowerUpType) -> Bool {
        let currentLvl = level(for: type)
        guard currentLvl < 5 else { return false }
        let cost = type.upgradeCost(forLevel: currentLvl)
        guard totalCoins >= cost else { return false }

        totalCoins -= cost
        powerUpLevels[type.rawValue] = currentLvl + 1
        SoundManager.shared.playPowerUp()
        return true
    }
}
