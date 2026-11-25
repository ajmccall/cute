package md.alasdair.cute.localgame

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import md.alasdair.cute.R
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.PieceType
import md.alasdair.cute.chess.Position
import md.alasdair.cute.chess.Side
import md.alasdair.cute.chess.Square
import md.alasdair.cute.localgame.data.GameRecord
import md.alasdair.cute.ui.theme.CuteTheme

/** The Board destination: the app's root, which launch opens. */
@Composable
fun BoardRoute(viewModel: LocalGameViewModel = hiltViewModel()) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    BoardScreen(
        state = state,
        actions = BoardActions(
            onSquareTapped = viewModel::onSquareTapped,
            onPromotionChosen = viewModel::onPromotionChosen,
            onPromotionCancelled = viewModel::onPromotionCancelled,
            onNewGame = viewModel::onNewGameRequested,
            onResign = viewModel::onResignRequested,
            onAgreeDraw = viewModel::onDrawRequested,
            onOfferDouble = viewModel::onOfferDoubleRequested,
            onTake = viewModel::onDoubleTaken,
            onDecline = viewModel::onDoubleDeclined,
            onConfirm = viewModel::onConfirmed,
            onCancel = viewModel::onCancelled,
            onRetry = viewModel::onRetry
        )
    )
}

class BoardActions(
    val onSquareTapped: (Square) -> Unit = {},
    val onPromotionChosen: (PieceType) -> Unit = {},
    val onPromotionCancelled: () -> Unit = {},
    val onNewGame: () -> Unit = {},
    val onResign: () -> Unit = {},
    val onAgreeDraw: () -> Unit = {},
    val onOfferDouble: () -> Unit = {},
    val onTake: () -> Unit = {},
    val onDecline: () -> Unit = {},
    val onConfirm: () -> Unit = {},
    val onCancel: () -> Unit = {},
    val onRetry: () -> Unit = {}
)

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun BoardScreen(state: LocalGameUiState, actions: BoardActions, modifier: Modifier = Modifier) {
    Surface(modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .safeDrawingPadding()
                .padding(vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            val game = state.game
            if (state.failure != null) {
                FailureNotice(state.failure, actions.onRetry)
            }
            if (game != null) {
                GameStatus(game, state.inCheck)
                if (game.result == null && !game.doublePending) StakeSummary(game)
                ChessBoard(
                    position = game.position,
                    bottomSide = state.bottomSide,
                    selection = state.selection,
                    destinations = state.destinations,
                    enabled = game.result == null && !game.doublePending,
                    onSquareTapped = actions.onSquareTapped,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            if (game?.doublePending == true) {
                // While a double awaits its answer, Take and Decline are the only game actions.
                DoubleResponse(game, actions)
            } else if (!state.loading) {
                FlowRow(
                    Modifier.padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(
                        8.dp,
                        Alignment.CenterHorizontally
                    ),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(onClick = actions.onNewGame) {
                        Text(stringResource(R.string.new_game))
                    }
                    if (game != null && game.result == null) {
                        OutlinedButton(onClick = actions.onResign) {
                            Text(stringResource(R.string.resign))
                        }
                        OutlinedButton(onClick = actions.onAgreeDraw) {
                            Text(stringResource(R.string.agree_draw))
                        }
                        OutlinedButton(
                            onClick = actions.onOfferDouble,
                            enabled = state.canOfferDouble
                        ) {
                            Text(stringResource(R.string.offer_double))
                        }
                    }
                }
            }
        }
        state.confirmation?.let { ConfirmDialog(it, state, actions) }
        if (state.promotion != null) PromotionDialog(actions)
    }
}

@Composable
private fun FailureNotice(failure: Failure, onRetry: () -> Unit) {
    Surface(
        color = MaterialTheme.colorScheme.errorContainer,
        shape = MaterialTheme.shapes.medium,
        modifier = Modifier.padding(horizontal = 16.dp).fillMaxWidth()
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = stringResource(
                    if (failure == Failure.Read) R.string.read_failure else R.string.write_failure
                ),
                color = MaterialTheme.colorScheme.onErrorContainer,
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.semantics { liveRegion = LiveRegionMode.Assertive }
            )
            Button(onClick = onRetry, modifier = Modifier.align(Alignment.End)) {
                Text(stringResource(R.string.retry))
            }
        }
    }
}

/**
 * The game's result, or whose turn or check it is, announced as it changes. A finished game
 * with a stake also shows each player's award, spoken with "half a point" for ½ point.
 */
@Composable
private fun GameStatus(game: GameRecord, inCheck: Boolean) {
    val headline = statusText(game, inCheck)
    val award = game.result?.let { result -> game.stake?.let { award(result, it) } }
    val spoken = award?.let { stringResource(R.string.status_with_award, headline, it.spoken) }
    Column(
        Modifier
            .padding(horizontal = 16.dp)
            .testTag("status")
            .semantics(mergeDescendants = true) {
                heading()
                liveRegion = LiveRegionMode.Polite
                if (spoken != null) contentDescription = spoken
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(headline, style = MaterialTheme.typography.headlineSmall)
        if (award != null) Text(award.shown, style = MaterialTheme.typography.titleMedium)
    }
}

/** What a finished game awards: as shown, and as a screen reader speaks it. */
private class Award(val shown: String, val spoken: String)

@Composable
private fun award(result: GameResult, stake: Int): Award {
    val winner = result.winner
    if (winner != null) {
        val text = stringResource(R.string.win_award, sideName(winner), points(stake))
        return Award(text, text)
    }
    return if (stake == 1) {
        Award(
            shown = stringResource(R.string.draw_award, stringResource(R.string.half_point)),
            spoken = stringResource(
                R.string.draw_award,
                stringResource(R.string.half_point_spoken)
            )
        )
    } else {
        val text = stringResource(R.string.draw_award, points(stake / 2))
        Award(text, text)
    }
}

/** The points in play and who may offer the next double, during play. */
@Composable
private fun StakeSummary(game: GameRecord) {
    val stake = game.stake ?: return
    val nextDoubler = game.nextDoubler
    val rightToOffer = when {
        stake >= GameRecord.MAX_STAKE -> stringResource(R.string.double_right_max)
        nextDoubler == null -> stringResource(R.string.double_right_either)
        else -> stringResource(R.string.double_right_only, sideName(nextDoubler))
    }
    Column(
        Modifier
            .padding(horizontal = 16.dp)
            .testTag("stake")
            .semantics(mergeDescendants = true) {},
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            stringResource(R.string.stake, points(stake)),
            style = MaterialTheme.typography.titleMedium
        )
        Text(rightToOffer, style = MaterialTheme.typography.bodyMedium)
    }
}

/**
 * The Double response surface, below the board in place of the game actions while a double
 * awaits its answer, under the status that names the responder: the stake as it is, what
 * taking or declining means, and the only two game actions, with equal weight so that neither
 * answer is suggested.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun DoubleResponse(game: GameRecord, actions: BoardActions) {
    val offerer = game.position.sideToMove
    val stake = game.stake ?: return
    val doubled = game.doubledStake ?: return
    Surface(
        color = MaterialTheme.colorScheme.secondaryContainer,
        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
        shape = MaterialTheme.shapes.medium,
        modifier = Modifier.padding(horizontal = 16.dp).fillMaxWidth()
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                stringResource(R.string.stake, points(stake)),
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                stringResource(R.string.take_effect, points(doubled)),
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                stringResource(R.string.decline_effect, sideName(offerer), points(stake)),
                style = MaterialTheme.typography.bodyLarge
            )
            FlowRow(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(onClick = actions.onTake) { Text(stringResource(R.string.take)) }
                OutlinedButton(onClick = actions.onDecline) {
                    Text(stringResource(R.string.decline))
                }
            }
        }
    }
}

@Composable
private fun points(count: Int) = pluralStringResource(R.plurals.points, count, count)

@Composable
private fun ConfirmDialog(
    confirmation: Confirmation,
    state: LocalGameUiState,
    actions: BoardActions
) {
    val question = when (confirmation) {
        Confirmation.Resign -> stringResource(R.string.confirm_resign, sideName(state.sideToMove))
        Confirmation.Draw -> stringResource(R.string.confirm_draw)
        Confirmation.Replace -> stringResource(R.string.confirm_replace)
    }
    AlertDialog(
        onDismissRequest = actions.onCancel,
        title = { Text(question) },
        confirmButton = {
            TextButton(onClick = actions.onConfirm) { Text(stringResource(R.string.confirm)) }
        },
        dismissButton = {
            TextButton(onClick = actions.onCancel) { Text(stringResource(R.string.cancel)) }
        }
    )
}

@Composable
private fun PromotionDialog(actions: BoardActions) {
    AlertDialog(
        onDismissRequest = actions.onPromotionCancelled,
        title = { Text(stringResource(R.string.promotion)) },
        text = {
            // Scrolls so that every choice stays reachable at large font scales in landscape.
            Column(Modifier.verticalScroll(rememberScrollState())) {
                for ((type, label) in promotionChoices) {
                    TextButton(
                        onClick = { actions.onPromotionChosen(type) },
                        modifier = Modifier.fillMaxWidth()
                    ) { Text(stringResource(label)) }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = actions.onPromotionCancelled) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}

private val promotionChoices = listOf(
    PieceType.Queen to R.string.queen,
    PieceType.Rook to R.string.rook,
    PieceType.Bishop to R.string.bishop,
    PieceType.Knight to R.string.knight
)

@Composable
private fun statusText(game: GameRecord, inCheck: Boolean): String {
    if (game.doublePending) {
        return stringResource(R.string.answer_double, sideName(game.position.sideToMove.opponent))
    }
    val result = game.result
        ?: return stringResource(
            if (inCheck) R.string.turn_check else R.string.turn,
            sideName(game.position.sideToMove)
        )
    val reason = stringResource(
        when (result.reason) {
            EndReason.Checkmate -> R.string.reason_checkmate
            EndReason.Resignation -> R.string.reason_resignation
            EndReason.DoubleDeclined -> R.string.reason_double_declined
            EndReason.Stalemate -> R.string.reason_stalemate
            EndReason.InsufficientMaterial -> R.string.reason_insufficient_material
            EndReason.Agreement -> R.string.reason_agreement
        }
    )
    return result.winner?.let { stringResource(R.string.win, sideName(it), reason) }
        ?: stringResource(R.string.draw, reason)
}

@Composable
private fun sideName(side: Side) =
    stringResource(if (side == Side.White) R.string.side_white else R.string.side_black)

@Preview(widthDp = 360, heightDp = 640)
@Composable
private fun BoardScreenPreview() {
    CuteTheme {
        BoardScreen(
            state = LocalGameUiState(loading = false, game = GameRecord.New),
            actions = BoardActions()
        )
    }
}

@Preview(widthDp = 360, heightDp = 640)
@Composable
private fun FinishedBoardScreenPreview() {
    CuteTheme {
        BoardScreen(
            state = LocalGameUiState(
                loading = false,
                game = GameRecord(Position.Opening, GameResult(Side.Black, EndReason.Resignation)),
                failure = Failure.Write
            ),
            actions = BoardActions()
        )
    }
}

@Preview(widthDp = 360, heightDp = 800)
@Composable
private fun DoubleResponseBoardScreenPreview() {
    CuteTheme {
        BoardScreen(
            state = LocalGameUiState(
                loading = false,
                game = GameRecord(
                    Position.Opening,
                    result = null,
                    stake = 2,
                    nextDoubler = Side.White,
                    doublePending = true
                )
            ),
            actions = BoardActions()
        )
    }
}

@Preview(widthDp = 360, heightDp = 640)
@Composable
private fun UnreadableBoardScreenPreview() {
    CuteTheme {
        BoardScreen(
            state = LocalGameUiState(loading = false, failure = Failure.Read),
            actions = BoardActions()
        )
    }
}
