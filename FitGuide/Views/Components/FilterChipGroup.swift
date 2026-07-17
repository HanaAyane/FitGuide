import SwiftUI

struct ChipItem: Hashable, Identifiable {
    let value: String
    let zhLabel: String
    let enLabel: String
    var id: String { value }
}

struct FilterChipGroup: View {
    let title: String
    let subtitle: String
    let items: [ChipItem]
    @Binding var selection: Set<String>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)
                Spacer()
                if !selection.isEmpty {
                    Button {
                        selection.removeAll()
                    } label: {
                        Text("清除")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            FlowLayout(spacing: Spacing.s.rawValue, lineSpacing: Spacing.s.rawValue) {
                ForEach(items) { item in
                    chip(item)
                }
            }
        }
    }

    @ViewBuilder
    private func chip(_ item: ChipItem) -> some View {
        let selected = selection.contains(item.value)
        Button {
            if selected { selection.remove(item.value) }
            else { selection.insert(item.value) }
        } label: {
            VStack(spacing: 0) {
                Text(item.zhLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(selected ? Color.accentColor : .textPrimary)
                Text(item.enLabel)
                    .font(.system(size: 9).smallCaps())
                    .foregroundColor(.textSecondary)
                    .opacity(selected ? 1 : 0.7)
            }
            .padding(.horizontal, Spacing.m.rawValue)
            .padding(.vertical, Spacing.s.rawValue)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Radii.chip.rawValue)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: Radii.chip.rawValue)
                        .strokeBorder(
                            LinearGradient(
                                colors: selected
                                    ? [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.2)]
                                    : [Color.white.opacity(0.12), Color.white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(selected ? 1.03 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: selected)
        }
        .buttonStyle(.plain)
    }
}

/// 自适应换行布局：宽度不够时自动折到下一行，无需横向滚动
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x - spacing, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}