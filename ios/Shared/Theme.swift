import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt64(s, radix: 16) ?? 0xA78BFA
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum Theme {
    static let bg = Color(hex: "#09090B")
    static let surface = Color(hex: "#141417")
    static let surface2 = Color(hex: "#1D1D21")
    static let line = Color(hex: "#26262C")
    static let muted = Color(hex: "#8D8D96")
    static let accent = Color(hex: "#8B7CF6")
    static let accentHex = "#8B7CF6"
    static let danger = Color(hex: "#F0616D")
    static let ok = Color(hex: "#34D399")

    static let palette: [String] = [
        "#A3E635", "#5ED0EA", "#F5C142", "#A78BFA", "#5FD39A", "#F472B6", "#F07178",
        "#5AA9F5", "#F59E4A", "#5ED6C0", "#818CF8", "#E879F9", "#FACC15", "#94A3B8",
    ]

    static let emojis: [String] = (
        "🏃 🚶 🚴 🏋️ 🧘 🤸 🏊 ⚽ 💧 🥗 🍎 🥛 💊 😴 🛏️ 🦷 🧴 📖 📗 📚 ✍️ 📝 🧠 💻 🗣️ 🎸 🎨 📷 " +
        "🎯 💰 🧹 🌱 🕌 📿 🤲 🌙 ☀️ ❤️ 🙏 👨‍👩‍👧 📞 ⏰ 📵 🚭 🍬 ☕ 🍔 🥤 🎮 📺 🛒 💸 🍕 🚫"
    ).split(separator: " ").map(String.init)
}
