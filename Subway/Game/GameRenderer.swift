import SwiftUI

@MainActor
public struct GameRenderer {

    // MARK: - Perspective Projection
    public static func project(
        lanePos: Double,
        z: Double,
        elevation: Double = 0.0,
        in size: CGSize
    ) -> (point: CGPoint, scale: Double) {
        let centerX = size.width / 2.0
        let horizonY = size.height * 0.38
        let bottomY = size.height * 0.90

        // Clamp z to valid range
        let clampedZ = max(0.0, min(1.2, z))
        // Non-linear depth factor (t: 0 at horizon, 1 at bottom camera)
        let t = max(0.0, 1.0 - (clampedZ / 1.05))
        let perspectiveT = pow(t, 1.6)

        let screenY = horizonY + perspectiveT * (bottomY - horizonY)
        let scale = max(0.12, pow(t, 1.35))
        let laneWidth = size.width * 0.34 * scale
        let screenX = centerX + (lanePos * laneWidth)

        // Elevation offset (higher = moves up on screen)
        let elevationOffset = elevation * 90.0 * scale
        let finalPoint = CGPoint(x: screenX, y: screenY - elevationOffset)

        return (finalPoint, scale)
    }

    // MARK: - Draw Environment & Tunnel
    public static func drawTunnel(context: inout GraphicsContext, size: CGSize, trackOffset: Double) {
        let centerX = size.width / 2.0
        let horizonY = size.height * 0.38

        // Deep tunnel gradient background
        let bgRect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(bgRect),
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: "#05070D"),
                    Color(hex: "#0B1120"),
                    Color(hex: "#020408")
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // Overhead Tunnel Arches with depth
        for i in 0..<8 {
            let z = (Double(i) * 0.14 - trackOffset * 0.14).truncatingRemainder(dividingBy: 1.0)
            let positiveZ = z < 0 ? z + 1.0 : z
            let (_, scale) = project(lanePos: 0, z: positiveZ, elevation: 0, in: size)

            let archWidth = size.width * (0.45 + scale * 0.75)
            let archHeight = (size.height * 0.5) * scale
            let archRect = CGRect(
                x: centerX - archWidth / 2.0,
                y: horizonY - archHeight * 0.75,
                width: archWidth,
                height: archHeight
            )

            var archPath = Path()
            archPath.addEllipse(in: archRect)
            context.stroke(
                archPath,
                with: .color(Color(hex: "#1E293B").opacity(scale * 0.65)),
                lineWidth: max(1.0, 3.0 * scale)
            )

            // Overhead Fluorescent Lights
            let lightWidth = 36.0 * scale
            let lightHeight = 5.0 * scale
            let lightRect = CGRect(
                x: centerX - lightWidth / 2.0,
                y: horizonY - archHeight * 0.65,
                width: lightWidth,
                height: lightHeight
            )
            context.fill(Path(lightRect), with: .color(Color(hex: "#38BDF8").opacity(scale * 0.8)))
        }

        // Horizon fog / light glow
        let horizonGlow = Path(ellipseIn: CGRect(
            x: centerX - 60,
            y: horizonY - 20,
            width: 120,
            height: 40
        ))
        context.fill(horizonGlow, with: .color(Color(hex: "#0284C7").opacity(0.2)))

        // Draw Subway Tracks and Sleepers (ties)
        drawTracks(context: &context, size: size, trackOffset: trackOffset)
    }

    // MARK: - Draw Subway Tracks
    private static func drawTracks(context: inout GraphicsContext, size: CGSize, trackOffset: Double) {
        // Draw Track Sleepers (wooden/concrete cross-ties)
        for i in 0..<22 {
            let z = (Double(i) * 0.048 - trackOffset * 0.048).truncatingRemainder(dividingBy: 1.0)
            let positiveZ = z < 0 ? z + 1.0 : z
            let (leftP, scale) = project(lanePos: -1.35, z: positiveZ, elevation: 0, in: size)
            let (rightP, _) = project(lanePos: 1.35, z: positiveZ, elevation: 0, in: size)

            var tiePath = Path()
            tiePath.move(to: leftP)
            tiePath.addLine(to: rightP)
            context.stroke(
                tiePath,
                with: .color(Color(hex: "#334155").opacity(scale * 0.85)),
                lineWidth: max(1.2, 5.5 * scale)
            )
        }

        // Draw Steel Rails for each of the 3 lanes
        let lanes: [Double] = [-1.0, 0.0, 1.0]
        for lane in lanes {
            let railOffset = 0.28
            for side in [-railOffset, railOffset] {
                let railLane = lane + side
                let (topP, _) = project(lanePos: railLane, z: 1.0, elevation: 0, in: size)
                let (botP, _) = project(lanePos: railLane, z: 0.0, elevation: 0, in: size)

                var railPath = Path()
                railPath.move(to: topP)
                railPath.addLine(to: botP)

                // Rail shadow/base
                context.stroke(railPath, with: .color(Color(hex: "#0F172A")), lineWidth: 4.5)
                // Gleaming steel head
                context.stroke(railPath, with: .color(Color(hex: "#94A3B8")), lineWidth: 2.0)
                // Electric neon reflection
                context.stroke(railPath, with: .color(Color(hex: "#38BDF8").opacity(0.35)), lineWidth: 1.0)
            }
        }
    }

    // MARK: - Draw Obstacles
    public static func drawObstacle(
        context: inout GraphicsContext,
        obstacle: TrackObstacle,
        size: CGSize
    ) {
        let (pos, scale) = project(lanePos: Double(obstacle.lane), z: obstacle.z, elevation: 0, in: size)

        switch obstacle.type {
        case .train:
            drawTrain(context: &context, pos: pos, scale: scale, isMoving: obstacle.isMovingTrain)
        case .hurdleLow:
            drawHurdle(context: &context, pos: pos, scale: scale)
        case .barrierHigh:
            drawHighBarrier(context: &context, pos: pos, scale: scale)
        case .trackBlock:
            drawConcreteBlock(context: &context, pos: pos, scale: scale)
        }
    }

    private static func drawTrain(context: inout GraphicsContext, pos: CGPoint, scale: Double, isMoving: Bool) {
        let width = 74.0 * scale
        let height = 96.0 * scale
        let trainRect = CGRect(x: pos.x - width / 2.0, y: pos.y - height, width: width, height: height)

        // Train Front Body
        var bodyPath = Path()
        bodyPath.addRoundedRect(in: trainRect, cornerSize: CGSize(width: 8 * scale, height: 8 * scale))
        context.fill(
            bodyPath,
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: "#475569"),
                    Color(hex: "#1E293B"),
                    Color(hex: "#0F172A")
                ]),
                startPoint: CGPoint(x: trainRect.minX, y: trainRect.minY),
                endPoint: CGPoint(x: trainRect.minX, y: trainRect.maxY)
            )
        )
        context.stroke(bodyPath, with: .color(Color(hex: "#94A3B8")), lineWidth: 1.5 * scale)

        // Metro Red/Blue Accent Stripe
        let stripeHeight = 12.0 * scale
        let stripeRect = CGRect(x: trainRect.minX, y: trainRect.minY + height * 0.48, width: width, height: stripeHeight)
        context.fill(Path(stripeRect), with: .color(Color(hex: "#EF4444")))

        // Front Windshield
        let windshieldWidth = width * 0.78
        let windshieldHeight = height * 0.28
        let windshieldRect = CGRect(
            x: pos.x - windshieldWidth / 2.0,
            y: trainRect.minY + 12 * scale,
            width: windshieldWidth,
            height: windshieldHeight
        )
        context.fill(Path(roundedRect: windshieldRect, cornerRadius: 4 * scale), with: .color(Color(hex: "#0EA5E9").opacity(0.85)))

        // Twin Blazing Headlights
        let lightSize = 12.0 * scale
        let leftLightRect = CGRect(x: trainRect.minX + 8 * scale, y: trainRect.maxY - 22 * scale, width: lightSize, height: lightSize)
        let rightLightRect = CGRect(x: trainRect.maxX - 8 * scale - lightSize, y: trainRect.maxY - 22 * scale, width: lightSize, height: lightSize)

        context.fill(Path(ellipseIn: leftLightRect), with: .color(Color(hex: "#FEF08A")))
        context.fill(Path(ellipseIn: rightLightRect), with: .color(Color(hex: "#FEF08A")))

        // Headlight Beams illuminating track ahead
        var beamPath = Path()
        beamPath.move(to: CGPoint(x: leftLightRect.midX, y: leftLightRect.midY))
        beamPath.addLine(to: CGPoint(x: pos.x - width * 0.9, y: pos.y + 40 * scale))
        beamPath.addLine(to: CGPoint(x: pos.x + width * 0.9, y: pos.y + 40 * scale))
        beamPath.addLine(to: CGPoint(x: rightLightRect.midX, y: rightLightRect.midY))
        beamPath.closeSubpath()
        context.fill(beamPath, with: .color(Color(hex: "#FEF08A").opacity(0.18)))
    }

    private static func drawHurdle(context: inout GraphicsContext, pos: CGPoint, scale: Double) {
        let width = 64.0 * scale
        let height = 28.0 * scale
        let hurdleRect = CGRect(x: pos.x - width / 2.0, y: pos.y - height, width: width, height: height)

        // Barrier Board
        let boardPath = Path(roundedRect: hurdleRect, cornerRadius: 3 * scale)
        context.fill(boardPath, with: .color(Color(hex: "#F59E0B")))
        context.stroke(boardPath, with: .color(Color(hex: "#000000")), lineWidth: 1.5 * scale)

        // Diagonal Warning Stripes
        for s in 0..<5 {
            let sx = hurdleRect.minX + Double(s) * (width / 5.0)
            var stripe = Path()
            stripe.move(to: CGPoint(x: sx, y: hurdleRect.maxY))
            stripe.addLine(to: CGPoint(x: sx + 8 * scale, y: hurdleRect.minY))
            stripe.addLine(to: CGPoint(x: sx + 14 * scale, y: hurdleRect.minY))
            stripe.addLine(to: CGPoint(x: sx + 6 * scale, y: hurdleRect.maxY))
            stripe.closeSubpath()
            context.fill(stripe, with: .color(Color(hex: "#111827")))
        }

        // Flashing Warning Beacons on top
        let beaconRadius = 5.0 * scale
        let leftBeacon = CGRect(x: hurdleRect.minX + 4 * scale, y: hurdleRect.minY - beaconRadius * 1.5, width: beaconRadius * 2, height: beaconRadius * 2)
        let rightBeacon = CGRect(x: hurdleRect.maxX - 4 * scale - beaconRadius * 2, y: hurdleRect.minY - beaconRadius * 1.5, width: beaconRadius * 2, height: beaconRadius * 2)
        context.fill(Path(ellipseIn: leftBeacon), with: .color(Color(hex: "#EF4444")))
        context.fill(Path(ellipseIn: rightBeacon), with: .color(Color(hex: "#EF4444")))
    }

    private static func drawHighBarrier(context: inout GraphicsContext, pos: CGPoint, scale: Double) {
        let width = 68.0 * scale
        let barHeight = 16.0 * scale
        let poleHeight = 72.0 * scale

        // Support Side Poles
        let leftPole = CGRect(x: pos.x - width / 2.0, y: pos.y - poleHeight, width: 4 * scale, height: poleHeight)
        let rightPole = CGRect(x: pos.x + width / 2.0 - 4 * scale, y: pos.y - poleHeight, width: 4 * scale, height: poleHeight)
        context.fill(Path(leftPole), with: .color(Color(hex: "#64748B")))
        context.fill(Path(rightPole), with: .color(Color(hex: "#64748B")))

        // Overhead High Clearance Beam (can slide under)
        let topBar = CGRect(x: pos.x - width / 2.0, y: pos.y - poleHeight, width: width, height: barHeight)
        let barPath = Path(roundedRect: topBar, cornerRadius: 2 * scale)
        context.fill(barPath, with: .color(Color(hex: "#EAB308")))
        context.stroke(barPath, with: .color(Color(hex: "#000000")), lineWidth: 1.2 * scale)

        // Hanging Caution Signs
        let signWidth = 14.0 * scale
        let signHeight = 16.0 * scale
        let signRect = CGRect(x: pos.x - signWidth / 2.0, y: topBar.maxY, width: signWidth, height: signHeight)
        context.fill(Path(signRect), with: .color(Color(hex: "#EF4444")))
    }

    private static func drawConcreteBlock(context: inout GraphicsContext, pos: CGPoint, scale: Double) {
        let width = 58.0 * scale
        let height = 36.0 * scale
        let blockRect = CGRect(x: pos.x - width / 2.0, y: pos.y - height, width: width, height: height)

        let path = Path(roundedRect: blockRect, cornerRadius: 4 * scale)
        context.fill(path, with: .color(Color(hex: "#475569")))
        context.stroke(path, with: .color(Color(hex: "#94A3B8")), lineWidth: 1.2 * scale)

        // Orange Traffic Cone on top
        var cone = Path()
        cone.move(to: CGPoint(x: pos.x, y: blockRect.minY - 18 * scale))
        cone.addLine(to: CGPoint(x: pos.x + 8 * scale, y: blockRect.minY))
        cone.addLine(to: CGPoint(x: pos.x - 8 * scale, y: blockRect.minY))
        cone.closeSubpath()
        context.fill(cone, with: .color(Color(hex: "#F97316")))
    }

    // MARK: - Draw Coins
    public static func drawCoin(
        context: inout GraphicsContext,
        coin: TrackCoin,
        size: CGSize,
        time: Double
    ) {
        let (pos, scale) = project(lanePos: Double(coin.lane), z: coin.z, elevation: coin.elevation, in: size)
        let coinSize = 22.0 * scale

        // Spinning effect using width scaling
        let spinPhase = sin(time * 6.0 + coin.z * 10.0)
        let currentWidth = max(4.0 * scale, coinSize * abs(spinPhase))

        let coinRect = CGRect(
            x: pos.x - currentWidth / 2.0,
            y: pos.y - coinSize,
            width: currentWidth,
            height: coinSize
        )

        // Gold Glow
        let glowRect = coinRect.insetBy(dx: -4 * scale, dy: -4 * scale)
        context.fill(Path(ellipseIn: glowRect), with: .color(Color(hex: "#F59E0B").opacity(0.35)))

        // Coin Face
        var coinPath = Path()
        coinPath.addEllipse(in: coinRect)
        context.fill(
            coinPath,
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: "#FEF08A"),
                    Color(hex: "#F59E0B"),
                    Color(hex: "#D97706")
                ]),
                startPoint: CGPoint(x: coinRect.minX, y: coinRect.minY),
                endPoint: CGPoint(x: coinRect.maxX, y: coinRect.maxY)
            )
        )
        context.stroke(coinPath, with: .color(Color(hex: "#FFFBEB")), lineWidth: 1.0 * scale)
    }

    // MARK: - Draw Power-Ups
    public static func drawPowerUp(
        context: inout GraphicsContext,
        powerup: TrackPowerUp,
        size: CGSize,
        time: Double
    ) {
        let bobbing = sin(time * 4.0) * 0.15
        let (pos, scale) = project(lanePos: Double(powerup.lane), z: powerup.z, elevation: 0.35 + bobbing, in: size)

        let crateSize = 34.0 * scale
        let crateRect = CGRect(x: pos.x - crateSize / 2.0, y: pos.y - crateSize, width: crateSize, height: crateSize)

        // Floating Outer Glow
        let glowRect = crateRect.insetBy(dx: -8 * scale, dy: -8 * scale)
        context.fill(Path(ellipseIn: glowRect), with: .color(powerup.type.color.opacity(0.4)))

        // Hologram Crate Box
        var boxPath = Path()
        boxPath.addRoundedRect(in: crateRect, cornerSize: CGSize(width: 8 * scale, height: 8 * scale))
        context.fill(boxPath, with: .color(powerup.type.color.opacity(0.85)))
        context.stroke(boxPath, with: .color(Color.white), lineWidth: 1.5 * scale)

        // Inner Power-Up Emblem
        let innerSize = crateSize * 0.5
        let innerRect = CGRect(x: pos.x - innerSize / 2.0, y: pos.y - crateSize / 2.0 - innerSize / 2.0, width: innerSize, height: innerSize)
        context.fill(Path(ellipseIn: innerRect), with: .color(Color.white.opacity(0.9)))
    }

    // MARK: - Draw Player Character
    public static func drawPlayer(
        context: inout GraphicsContext,
        gameState: GameState,
        size: CGSize,
        time: Double
    ) {
        let char = gameState.selectedCharacter
        let (pos, scale) = project(
            lanePos: gameState.currentLanePos,
            z: 0.08,
            elevation: gameState.playerAction == .jumping ? gameState.jumpProgress * 1.5 : (gameState.playerAction == .jetpackFlying ? 2.4 : 0.0),
            in: size
        )

        let charWidth = 46.0 * scale
        let charHeight = 72.0 * scale
        let playerY = pos.y

        // Jetpack Exhaust Trails
        if gameState.playerAction == .jetpackFlying {
            for side in [-1.0, 1.0] {
                let thrusterX = pos.x + side * (charWidth * 0.4)
                let thrusterY = playerY - charHeight * 0.4
                var flame = Path()
                flame.move(to: CGPoint(x: thrusterX - 4 * scale, y: thrusterY))
                flame.addLine(to: CGPoint(x: thrusterX + 4 * scale, y: thrusterY))
                flame.addLine(to: CGPoint(x: thrusterX, y: thrusterY + 28 * scale + sin(time * 30) * 6 * scale))
                flame.closeSubpath()
                context.fill(flame, with: .color(Color(hex: "#F97316")))
            }
        }

        // Magnet Aura Effect
        if gameState.activePowerUps[.magnet] != nil {
            let auraRadius = charWidth * 1.4
            let auraRect = CGRect(x: pos.x - auraRadius, y: playerY - charHeight * 0.7 - auraRadius, width: auraRadius * 2, height: auraRadius * 2)
            context.stroke(
                Path(ellipseIn: auraRect),
                with: .color(Color(hex: "#F43F5E").opacity(0.45 + sin(time * 12) * 0.2)),
                lineWidth: 2.0 * scale
            )
        }

        // Character Shadow on track
        let shadowWidth = charWidth * (gameState.playerAction == .jumping ? 0.6 : 1.1)
        let shadowRect = CGRect(x: pos.x - shadowWidth / 2.0, y: pos.y - 6 * scale, width: shadowWidth, height: 10 * scale)
        context.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.45)))

        if gameState.playerAction == .sliding {
            // Sliding / Rolling posture (low profile)
            let slideHeight = charHeight * 0.45
            let slideRect = CGRect(x: pos.x - charWidth / 2.0, y: playerY - slideHeight, width: charWidth, height: slideHeight)
            context.fill(Path(roundedRect: slideRect, cornerRadius: 8 * scale), with: .color(char.outfitColor))
            context.stroke(Path(roundedRect: slideRect, cornerRadius: 8 * scale), with: .color(char.accentColor), lineWidth: 2 * scale)

            // Slide friction sparks
            for _ in 0..<3 {
                let sparkX = pos.x + Double.random(in: -charWidth...charWidth) * 0.5
                let sparkRect = CGRect(x: sparkX, y: playerY - 3 * scale, width: 3 * scale, height: 3 * scale)
                context.fill(Path(sparkRect), with: .color(Color(hex: "#FDE047")))
            }
        } else {
            // Running / Jumping posture
            let runCycle = sin(time * 14.0 * (gameState.speed / 0.45))
            let legSwing = runCycle * 14.0 * scale

            // Running Legs
            let legWidth = 7.0 * scale
            let legHeight = 26.0 * scale

            // Left leg
            let leftLegRect = CGRect(x: pos.x - 12 * scale, y: playerY - legHeight + legSwing, width: legWidth, height: legHeight)
            context.fill(Path(roundedRect: leftLegRect, cornerRadius: 3 * scale), with: .color(Color(hex: "#1E293B")))

            // Right leg
            let rightLegRect = CGRect(x: pos.x + 5 * scale, y: playerY - legHeight - legSwing, width: legWidth, height: legHeight)
            context.fill(Path(roundedRect: rightLegRect, cornerRadius: 3 * scale), with: .color(Color(hex: "#1E293B")))

            // Super Sneakers glow
            if gameState.activePowerUps[.sneakers] != nil {
                let bootGlow = CGRect(x: pos.x - 16 * scale, y: playerY - 10 * scale, width: 32 * scale, height: 12 * scale)
                context.fill(Path(ellipseIn: bootGlow), with: .color(Color(hex: "#22C55E").opacity(0.6)))
            }

            // Torso / Jacket
            let torsoHeight = 28.0 * scale
            let torsoRect = CGRect(x: pos.x - 16 * scale, y: playerY - legHeight - torsoHeight, width: 32 * scale, height: torsoHeight)
            let torsoPath = Path(roundedRect: torsoRect, cornerRadius: 6 * scale)
            context.fill(torsoPath, with: .color(char.outfitColor))
            context.stroke(torsoPath, with: .color(char.accentColor), lineWidth: 2 * scale)

            // Runner Head & Cap
            let headSize = 20.0 * scale
            let headRect = CGRect(x: pos.x - headSize / 2.0, y: torsoRect.minY - headSize + 4 * scale, width: headSize, height: headSize)
            context.fill(Path(ellipseIn: headRect), with: .color(Color(hex: "#FBBF24")))

            // Skater Cap with backwards brim
            let capRect = CGRect(x: pos.x - headSize / 2.0 - 2 * scale, y: headRect.minY - 2 * scale, width: headSize + 4 * scale, height: headSize * 0.55)
            context.fill(Path(roundedRect: capRect, cornerRadius: 4 * scale), with: .color(char.accentColor))
        }

        // Energy Shield Bubble
        if gameState.hasShield {
            let shieldRadius = charWidth * 1.25
            let shieldCenter = CGPoint(x: pos.x, y: playerY - charHeight * 0.5)
            let shieldRect = CGRect(x: shieldCenter.x - shieldRadius, y: shieldCenter.y - shieldRadius, width: shieldRadius * 2, height: shieldRadius * 2)

            var shieldPath = Path()
            shieldPath.addEllipse(in: shieldRect)
            context.fill(shieldPath, with: .color(Color(hex: "#A855F7").opacity(0.25 + sin(gameState.shieldPulse) * 0.08)))
            context.stroke(shieldPath, with: .color(Color(hex: "#C084FC")), lineWidth: 2.5 * scale)
        }
    }
}
