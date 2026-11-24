package md.alasdair.cute.chess

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Counts every line of legal play to a fixed depth and compares it with the published counts
 * for well-known positions (chessprogramming.org, "Perft Results"). A wrong castling, en
 * passant, promotion or pin rule changes the count.
 */
class PerftTest {
    @Test
    fun `opening position`() {
        assertEquals(8_902L, perft(positionFromFen(Position.OPENING_FEN), 3))
    }

    @Test
    fun `kiwipete, rich in castling, pins and en passant`() {
        val fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"
        assertEquals(97_862L, perft(positionFromFen(fen), 3))
    }

    @Test
    fun `position 3, with en passant that would expose the king along a rank`() {
        val fen = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"
        assertEquals(43_238L, perft(positionFromFen(fen), 4))
    }

    @Test
    fun `position 4, with promotions and castling under attack`() {
        val fen = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"
        assertEquals(9_467L, perft(positionFromFen(fen), 3))
    }

    private fun perft(position: Position, depth: Int): Long = if (depth == 0) {
        1
    } else {
        position.legalMoves().sumOf { perft(position.play(it), depth - 1) }
    }
}
