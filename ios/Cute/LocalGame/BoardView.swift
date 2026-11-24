import SwiftUI

/// The 8 × 8 play surface, drawn with the side to move at the bottom.
struct BoardView: View {
    let game: LocalGame

    /// Rows top to bottom, each left to right, for the side whose pieces sit at the bottom.
    private var rows: [[Square]] {
        let ranks: [Int] = game.position.sideToMove == .white ? Array((0..<8).reversed()) : Array(0..<8)
        let files: [Int] = game.position.sideToMove == .white ? Array(0..<8) : Array((0..<8).reversed())
        return ranks.map { rank in files.map { Square(file: $0, rank: rank)! } }
    }

    var body: some View {
        let destinations = game.legalDestinations
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(rows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { square in
                        SquareView(
                            square: square,
                            piece: game.position[square],
                            isSelected: game.selection == square,
                            isDestination: destinations.contains(square)
                        ) {
                            game.tap(square)
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Chessboard"))
        .accessibilityIdentifier("board")
    }
}

private struct SquareView: View {
    let square: Square
    let piece: Piece?
    let isSelected: Bool
    let isDestination: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                ZStack {
                    Rectangle().fill(Color(square.isLight ? "LightSquare" : "DarkSquare"))
                    if let piece {
                        PieceGlyph(piece: piece, size: side * 0.92)
                    }
                    if isDestination {
                        DestinationMarker(isCapture: piece != nil, side: side)
                    }
                    if isSelected {
                        Rectangle()
                            .strokeBorder(Color("SelectionRing"), lineWidth: max(3, side * 0.08))
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(BoardText.squareLabel(square, occupant: piece)))
        .accessibilityValue(accessibilityState)
        .accessibilityIdentifier("square-\(square.coordinate)")
    }

    private var accessibilityState: Text {
        if isSelected { return Text("Selected") }
        if isDestination { return Text("Legal destination") }
        return Text(verbatim: "")
    }
}

/// A piece drawn from the Unicode chess glyphs: filled for Black, filled white with an outline for White.
/// Drawn as a graphic that scales with the board, not as text; the square's label names the piece.
private struct PieceGlyph: View {
    let piece: Piece
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let fill = Text(verbatim: glyph(filled: true))
                .font(.system(size: size))
                .foregroundStyle(Color(piece.color == .white ? "WhitePiece" : "BlackPiece"))
            context.draw(fill, at: center)
            if piece.color == .white {
                let outline = Text(verbatim: glyph(filled: false))
                    .font(.system(size: size))
                    .foregroundStyle(Color("BlackPiece"))
                context.draw(outline, at: center)
            }
        }
        .accessibilityHidden(true)
    }

    private func glyph(filled: Bool) -> String {
        let scalar: UInt32 = switch piece.kind {
        case .king: 0x2654
        case .queen: 0x2655
        case .rook: 0x2656
        case .bishop: 0x2657
        case .knight: 0x2658
        case .pawn: 0x2659
        }
        // The filled glyphs follow the outline ones; U+FE0E keeps the pawn from showing as an emoji.
        return String(UnicodeScalar(scalar + (filled ? 6 : 0))!) + "\u{FE0E}"
    }
}

/// A dot on an empty legal destination, or a dashed ring around a piece that can be captured,
/// so a destination never relies on colour alone.
private struct DestinationMarker: View {
    let isCapture: Bool
    let side: CGFloat

    var body: some View {
        if isCapture {
            Circle()
                .strokeBorder(Color("SelectionRing"), style: StrokeStyle(lineWidth: max(3, side * 0.07), dash: [side * 0.12]))
                .padding(side * 0.04)
        } else {
            Circle()
                .fill(Color("SelectionRing"))
                .frame(width: side * 0.3, height: side * 0.3)
        }
    }
}
