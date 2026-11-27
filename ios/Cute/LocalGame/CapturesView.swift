import SwiftUI

/// One colour's captures, at that colour's edge of the board: the opponent's pieces it has taken, grouped by kind
/// with a count from 2 up, and directly after them the material lead when this colour is ahead (product owner, on
/// #39). Pieces are shown as icons and read by VoiceOver as text; the lead is never in points.
struct CapturesView: View {
    let side: PieceColor
    let captures: Captures
    let lead: MaterialLead?

    @ScaledMetric(relativeTo: .subheadline) private var tileSize = 26

    /// "Captured by {side}:", a tile for each kind, and any lead, wrapping onto more lines as text grows. VoiceOver
    /// reads the whole collection on the heading, and the lead on its own.
    var body: some View {
        let groups = captures.groups(by: side)
        FlowLayout(spacing: 8) {
            Text(groups.isEmpty ? BoardText.captures(captures, by: side) : BoardText.capturesHeading(side))
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityLabel(BoardText.captures(captures, by: side))
                .accessibilityIdentifier("captures-\(side.rawValue)")
            ForEach(groups, id: \.kind) { group in
                CaptureTile(piece: Piece(color: side.opponent, kind: group.kind), count: group.count, size: tileSize)
                    .accessibilityHidden(true)
            }
            if let lead, lead.side == side {
                Text(BoardText.advantage(lead, spoken: false))
                    .font(.headline)
                    .monospacedDigit()
                    .accessibilityLabel(BoardText.advantage(lead, spoken: true))
                    .accessibilityIdentifier("advantage")
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("captures-row-\(side.rawValue)")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

/// One kind of captured piece on a board-coloured tile, with ×N beside it from 2 up; a single piece is its icon
/// alone. A white piece sits on a dark-square tile and a black piece on a light one, so each stands out from its
/// tile in light and dark appearance.
private struct CaptureTile: View {
    let piece: Piece
    let count: Int
    let size: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            // A chess glyph fills about three quarters of its font size, so draw it larger than the tile's side
            // for the piece to fill the tile.
            PieceGlyph(piece: piece, size: size * 1.15)
                .frame(width: size, height: size)
                .background(Color(piece.color == .white ? "DarkSquare" : "LightSquare"), in: .rect(cornerRadius: 4))
            if count > 1 {
                Text(BoardText.shownCount(count))
                    .monospacedDigit()
            }
        }
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
