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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
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
                Text(
                    text = statusText(game, state.inCheck),
                    style = MaterialTheme.typography.headlineSmall,
                    modifier = Modifier
                        .padding(horizontal = 16.dp)
                        .testTag("status")
                        .semantics {
                            heading()
                            liveRegion = LiveRegionMode.Polite
                        }
                )
                ChessBoard(
                    position = game.position,
                    bottomSide = state.bottomSide,
                    selection = state.selection,
                    destinations = state.destinations,
                    enabled = game.result == null,
                    onSquareTapped = actions.onSquareTapped,
                    modifier = Modifier.fillMaxWidth()
                )
            }
            if (!state.loading) {
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
                    }
                }
            }
        }
        state.confirmation?.let { ConfirmDialog(it, state.sideToMove, actions) }
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

@Composable
private fun ConfirmDialog(confirmation: Confirmation, sideToMove: Side, actions: BoardActions) {
    val question = when (confirmation) {
        Confirmation.Resign -> stringResource(R.string.confirm_resign, sideName(sideToMove))
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
    val result = game.result
        ?: return stringResource(
            if (inCheck) R.string.turn_check else R.string.turn,
            sideName(game.position.sideToMove)
        )
    val reason = stringResource(
        when (result.reason) {
            EndReason.Checkmate -> R.string.reason_checkmate
            EndReason.Resignation -> R.string.reason_resignation
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
