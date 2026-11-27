import SwiftUI

/// One colour's captures, at that colour's edge of the board: the opponent's pieces it has taken, grouped by kind
/// with a count, and beside them the material lead when this colour is ahead. Pieces are shown as icons and read
/// by VoiceOver as text; the lead is never in points.
struct CapturesView: View {
    let side: PieceColor
    let captures: Captures
    let lead: MaterialLead?

    @ScaledMetric(relativeTo: .subheadline) private var tileSize = 22

    var body: some View {
        HStack(spacing: 12) {
            collection
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityLabel(BoardText.captures(captures, by: side))
                .accessibilityIdentifier("captures-\(side.rawValue)")
            if let lead, lead.side == side {
                Text(BoardText.advantage(lead, spoken: false))
                    .font(.headline)
                    .monospacedDigit()
                    .accessibilityLabel(BoardText.advantage(lead, spoken: true))
                    .accessibilityIdentifier("advantage")
            }
        }
        .padding(.horizontal)
    }

    /// "Captured by {side}:" and a tile for each kind with its count, wrapping onto more lines as text grows.
    private var collection: some View {
        let groups = captures.groups(by: side)
        return FlowLayout(spacing: 8) {
            Text(groups.isEmpty ? BoardText.captures(captures, by: side) : BoardText.capturesHeading(side))
            ForEach(groups, id: \.kind) { group in
                HStack(spacing: 2) {
                    PieceGlyph(piece: Piece(color: side.opponent, kind: group.kind), size: tileSize * 0.9)
                        .frame(width: tileSize, height: tileSize)
                        .background(Color("LightSquare"), in: .rect(cornerRadius: 4))
                    Text(BoardText.shownCount(group.count))
                        .monospacedDigit()
                }
            }
        }
        .font(.subheadline)
    }
}

/// Lays its subviews out left to right, each line's centred vertically, wrapping onto a new line when the next
/// doesn't fit. A subview wider than a line on its own, such as long text, is offered the line's width.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(of: subviews, width: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrangement(of: subviews, width: bounds.width)
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                          proposal: ProposedViewSize(frame.size))
        }
    }

    private func arrangement(of subviews: Subviews, width: CGFloat) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var line: [Int] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0

        func endLine() {
            for index in line {
                frames[index].origin.y = y + (lineHeight - frames[index].height) / 2
            }
            y += lineHeight + spacing
            line = []
            x = 0
            lineHeight = 0
        }

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)
            if size.width > width {
                size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            }
            if !line.isEmpty, x + size.width > width { endLine() }
            line.append(frames.count)
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widest = max(widest, x - spacing)
        }
        if !line.isEmpty { endLine() }
        return (frames, CGSize(width: widest, height: max(0, y - spacing)))
    }
}
