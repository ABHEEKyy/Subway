import SwiftUI

public struct CharacterModel: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let title: String
    public let bio: String
    public let cost: Int
    public let icon: String
    public let outfitColorHex: String
    public let accentColorHex: String
    public let perkTitle: String
    public let perkDescription: String
    public let jumpMultiplier: Double
    public let magnetMultiplier: Double
    public let multiplierBonus: Double
    public let startsWithShield: Bool

    public var outfitColor: Color {
        Color(hex: outfitColorHex)
    }

    public var accentColor: Color {
        Color(hex: accentColorHex)
    }

    public static let allCharacters: [CharacterModel] = [
        CharacterModel(
            id: "jack",
            name: "Jack",
            title: "Street Cruiser",
            bio: "The subway legend who knows every bend and rail in the metro system.",
            cost: 0,
            icon: "figure.run",
            outfitColorHex: "#2563EB",
            accentColorHex: "#F59E0B",
            perkTitle: "Balanced Agility",
            perkDescription: "Quick lane shifts and standard high jump capability.",
            jumpMultiplier: 1.0,
            magnetMultiplier: 1.0,
            multiplierBonus: 1.0,
            startsWithShield: false
        ),
        CharacterModel(
            id: "tricky",
            name: "Tricky",
            title: "Track Acrobat",
            bio: "Fastest reflexes on the transit lines with custom magnetized sneakers.",
            cost: 500,
            icon: "figure.walk.motion",
            outfitColorHex: "#EC4899",
            accentColorHex: "#38BDF8",
            perkTitle: "Coin Attractor",
            perkDescription: "+35% wider coin collection radius on all tracks.",
            jumpMultiplier: 1.05,
            magnetMultiplier: 1.35,
            multiplierBonus: 1.0,
            startsWithShield: false
        ),
        CharacterModel(
            id: "fresh",
            name: "Fresh",
            title: "Metro Beatmaker",
            bio: "Carries the heavy boombox rhythm that doubles your momentum score.",
            cost: 1200,
            icon: "headphones",
            outfitColorHex: "#10B981",
            accentColorHex: "#FBBF24",
            perkTitle: "Rhythm Multiplier",
            perkDescription: "All score multipliers give +50% extra score boost.",
            jumpMultiplier: 1.0,
            magnetMultiplier: 1.1,
            multiplierBonus: 1.5,
            startsWithShield: false
        ),
        CharacterModel(
            id: "spike",
            name: "Spike",
            title: "Punk Rebel",
            bio: "Tough as steel rails, starts every subway run with an armored shield.",
            cost: 2500,
            icon: "shield.checkered",
            outfitColorHex: "#8B5CF6",
            accentColorHex: "#EF4444",
            perkTitle: "Armored Start",
            perkDescription: "Automatically starts every run protected with a free energy shield.",
            jumpMultiplier: 1.0,
            magnetMultiplier: 1.0,
            multiplierBonus: 1.0,
            startsWithShield: true
        ),
        CharacterModel(
            id: "yutani",
            name: "Yutani",
            title: "Cyber Tech Prodigy",
            bio: "Equipped with gravity-defying boots and experimental jetpack thrusters.",
            cost: 5000,
            icon: "sparkles",
            outfitColorHex: "#06B6D4",
            accentColorHex: "#A855F7",
            perkTitle: "Super Lift & Turbo",
            perkDescription: "+25% higher jumps and extended jetpack skyway duration.",
            jumpMultiplier: 1.25,
            magnetMultiplier: 1.25,
            multiplierBonus: 1.25,
            startsWithShield: false
        )
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
