package md.alasdair.cute.localgame

import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import md.alasdair.cute.R
import md.alasdair.cute.chess.Piece
import md.alasdair.cute.chess.PieceType
import md.alasdair.cute.chess.Position
import md.alasdair.cute.chess.Side
import md.alasdair.cute.chess.Square
import md.alasdair.cute.ui.theme.CuteTheme
import md.alasdair.cute.ui.theme.LocalBoardColors

/**
 * The 64 squares, drawn with [bottomSide]'s pieces nearest the player. Each square is one
 * accessible button named by its coordinate and occupant; selection and legal destinations are
 * marked by shape as well as colour. When [enabled] is false the board can't be played.
 */
@Composable
fun ChessBoard(
    position: Position,
    bottomSide: Side,
    selection: Square?,
    destinations: Set<Square>,
    enabled: Boolean,
    onSquareTapped: (Square) -> Unit,
    modifier: Modifier = Modifier
) {
    val ranks = if (bottomSide == Side.White) (7 downTo 0) else (0..7)
    val files = if (bottomSide == Side.White) (0..7) else (7 downTo 0)
    BoxWithConstraints(modifier.aspectRatio(1f).testTag("board")) {
        val squareSize = maxWidth / 8
        Column(Modifier.fillMaxSize()) {
            for (rank in ranks) {
                Row(Modifier.fillMaxWidth().weight(1f)) {
                    for (file in files) {
                        val square = Square(file, rank)
                        BoardSquare(
                            square = square,
                            piece = position[square],
                            selected = square == selection,
                            destination = square in destinations,
                            enabled = enabled,
                            size = squareSize,
                            onClick = { onSquareTapped(square) },
                            modifier = Modifier.weight(1f).fillMaxSize()
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun BoardSquare(
    square: Square,
    piece: Piece?,
    selected: Boolean,
    destination: Boolean,
    enabled: Boolean,
    size: Dp,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalBoardColors.current
    val occupant =
        piece?.let { stringResource(it.nameRes) } ?: stringResource(R.string.square_empty)
    val label = stringResource(R.string.square, square.name, occupant)
    val state = when {
        selected -> stringResource(R.string.square_selected)
        destination -> stringResource(R.string.legal_destination)
        else -> null
    }
    Box(
        modifier
            .background(if (square.isLight) colors.lightSquare else colors.darkSquare)
            .then(if (selected) Modifier.border(size / 12, colors.marker) else Modifier)
            .testTag("square-${square.name}")
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .semantics(mergeDescendants = true) {
                contentDescription = label
                if (state != null) stateDescription = state
            },
        contentAlignment = Alignment.Center
    ) {
        if (piece != null) PieceGlyph(piece, size)
        if (destination) {
            val marker = if (piece == null) {
                Modifier.size(size / 3).background(colors.marker, CircleShape)
            } else {
                Modifier.fillMaxSize().border(size / 14, colors.marker, CircleShape)
            }
            Box(marker)
        }
    }
}

/**
 * A piece drawn from the Unicode chess symbols. White pieces are the filled shape in the white
 * fill under the outlined shape in ink; black pieces are the filled shape in ink. The glyph is
 * sized to its square, not to the font scale, because it is a picture of the piece: the square's
 * description carries its meaning.
 */
@Composable
private fun PieceGlyph(piece: Piece, squareSize: Dp) {
    val colors = LocalBoardColors.current
    // Dp.toSp divides out the font scale, so the glyph keeps its size in the square.
    val fontSize = with(LocalDensity.current) { (squareSize * 0.78f).toSp() }
    val style =
        TextStyle(
            fontSize = fontSize,
            lineHeight = TextUnit.Unspecified,
            textAlign = TextAlign.Center
        )
    val hidden = Modifier.clearAndSetSemantics {}
    if (piece.side == Side.White) {
        Text(piece.filled, style = style, color = colors.pieceFillWhite, modifier = hidden)
        Text(piece.outline, style = style, color = colors.pieceInk, modifier = hidden)
    } else {
        Text(piece.filled, style = style, color = colors.pieceFillBlack, modifier = hidden)
    }
}

/** U+FE0E asks for the text form, so that no symbol is drawn as an emoji. */
private const val TEXT_STYLE = "︎"

private val Piece.filled: String
    get() = when (type) {
        PieceType.King -> "♚"
        PieceType.Queen -> "♛"
        PieceType.Rook -> "♜"
        PieceType.Bishop -> "♝"
        PieceType.Knight -> "♞"
        PieceType.Pawn -> "♟"
    } + TEXT_STYLE

private val Piece.outline: String
    get() = when (type) {
        PieceType.King -> "♔"
        PieceType.Queen -> "♕"
        PieceType.Rook -> "♖"
        PieceType.Bishop -> "♗"
        PieceType.Knight -> "♘"
        PieceType.Pawn -> "♙"
    } + TEXT_STYLE

@get:StringRes
private val Piece.nameRes: Int
    get() = when (side) {
        Side.White -> when (type) {
            PieceType.King -> R.string.white_king
            PieceType.Queen -> R.string.white_queen
            PieceType.Rook -> R.string.white_rook
            PieceType.Bishop -> R.string.white_bishop
            PieceType.Knight -> R.string.white_knight
            PieceType.Pawn -> R.string.white_pawn
        }
        Side.Black -> when (type) {
            PieceType.King -> R.string.black_king
            PieceType.Queen -> R.string.black_queen
            PieceType.Rook -> R.string.black_rook
            PieceType.Bishop -> R.string.black_bishop
            PieceType.Knight -> R.string.black_knight
            PieceType.Pawn -> R.string.black_pawn
        }
    }

@Preview(widthDp = 360)
@Composable
private fun ChessBoardPreview() {
    CuteTheme {
        ChessBoard(
            position = Position.Opening,
            bottomSide = Side.White,
            selection = Square.of("g1"),
            destinations = setOf(Square.of("f3"), Square.of("h3")),
            enabled = true,
            onSquareTapped = {}
        )
    }
}
