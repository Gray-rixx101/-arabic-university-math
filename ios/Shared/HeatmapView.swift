import SwiftUI

/// خريطة حرارية على طريقة GitHub: كل عمود أسبوع، وكل مربع يوم.
/// في الواجهة العربية تكون الأسابيع الأقدم على اليمين واليوم الحالي على اليسار.
struct HeatmapView: View {
    var habit: Habit?
    var firstWeekday = 1
    var cellSize: CGFloat = 10.5
    var spacing: CGFloat = 3
    var end: Date = Day.today
    var showMonths = false
    /// عدد أسابيع ثابت (لعرض سنة كاملة). إن كان nil يُحسب العدد من العرض المتاح.
    var fixedWeeks: Int?
    var tint: Color?
    var aggregate: ((Date) -> Double)?

    @Environment(\.layoutDirection) private var direction

    private var monthsHeight: CGFloat { showMonths ? 14 : 0 }
    private var gridHeight: CGFloat { 7 * cellSize + 6 * spacing }

    var body: some View {
        let canvas = Canvas { ctx, size in draw(&ctx, size) }
        if let weeks = fixedWeeks {
            let w = CGFloat(weeks) * cellSize + CGFloat(weeks - 1) * spacing
            canvas.aspectRatio(w / (gridHeight + monthsHeight), contentMode: .fit)
        } else {
            canvas.frame(height: gridHeight + monthsHeight)
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        var cell = (size.height - monthsHeight - 6 * spacing) / 7
        let weeks: Int
        if let fw = fixedWeeks {
            weeks = max(1, fw)
            cell = min(cell, (size.width - CGFloat(weeks - 1) * spacing) / CGFloat(weeks))
        } else {
            weeks = max(1, Int((size.width + spacing) / (cell + spacing)))
        }
        guard cell > 0 else { return }
        let totalW = CGFloat(weeks) * cell + CGFloat(weeks - 1) * spacing
        let inset = max(0, (size.width - totalW) / 2)
        let rtl = direction == .rightToLeft
        let today = Day.today
        let first = Day.add(-(weeks - 1) * 7, Day.startOfWeek(end, first: firstWeekday))
        let base = tint ?? habit?.color ?? Theme.accent

        func x(_ col: Int) -> CGFloat {
            rtl
                ? size.width - inset - CGFloat(col + 1) * cell - CGFloat(col) * spacing
                : inset + CGFloat(col) * (cell + spacing)
        }

        if showMonths && weeks > 3 {
            let minGap = max(4, Int((Double(weeks) / 8).rounded(.up)))
            var last = Day.month(first)
            var lastCol = -minGap
            for w in 1..<(weeks - 2) {
                let m = Day.month(Day.add(w * 7, first))
                guard m != last else { continue }
                last = m
                guard w - lastCol >= minGap else { continue }
                lastCol = w
                let label = Text(Day.months[m - 1]).font(.system(size: 9)).foregroundColor(Theme.muted)
                ctx.draw(label, at: CGPoint(x: rtl ? x(w) + cell : x(w), y: 6), anchor: rtl ? .trailing : .leading)
            }
        }

        for w in 0..<weeks {
            for r in 0..<7 {
                let d = Day.add(w * 7 + r, first)
                if d > today { continue }
                let rect = CGRect(x: x(w), y: monthsHeight + CGFloat(r) * (cell + spacing), width: cell, height: cell)
                let radius = cell * 0.26
                ctx.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color(for: d, base: base, today: today)))
                if d == today {
                    ctx.stroke(Path(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75), cornerRadius: radius),
                               with: .color(.white.opacity(0.85)), lineWidth: 1.5)
                }
            }
        }
    }

    private func color(for d: Date, base: Color, today: Date) -> Color {
        if let aggregate {
            let f = aggregate(d)
            return f > 0 ? base.opacity(0.3 + 0.7 * f) : base.opacity(0.13)
        }
        guard let habit else { return base.opacity(0.13) }
        switch habit.status(on: d, today: today) {
        case .done: return base
        case .partial(let f): return base.opacity(0.3 + 0.5 * f)
        case .slip: return Theme.danger.opacity(0.45)
        case .off: return base.opacity(0.06)
        default: return base.opacity(0.13)
        }
    }
}

/// حلقة تقدّم للعادات ذات الهدف العددي
struct ProgressRing: View {
    var fraction: Double
    var color: Color
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, fraction)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct EmojiTile: View {
    var emoji: String
    var color: Color
    var size: CGFloat = 42

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).stroke(.white.opacity(0.05)))
    }
}
