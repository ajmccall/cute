package md.alasdair.cute.localgame

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Move
import md.alasdair.cute.chess.PieceType
import md.alasdair.cute.chess.Position
import md.alasdair.cute.chess.Square
import md.alasdair.cute.chess.automaticResult
import md.alasdair.cute.chess.legalMovesFrom
import md.alasdair.cute.chess.play
import md.alasdair.cute.localgame.data.GameRecord
import md.alasdair.cute.localgame.data.GameRepository

/**
 * The current game at the board. Every change is saved before it is shown, so the board only
 * ever shows a committed game. While a save or load is under way, the board ignores input.
 */
@HiltViewModel
class LocalGameViewModel @Inject constructor(private val repository: GameRepository) :
    ViewModel() {
    private val _uiState = MutableStateFlow(LocalGameUiState())
    val uiState: StateFlow<LocalGameUiState> = _uiState.asStateFlow()

    /** The change that failed to save, which Retry tries again. */
    private var unsaved: GameRecord? = null
    private var busy = false

    init {
        load()
    }

    fun onSquareTapped(square: Square) {
        val state = _uiState.value
        if (busy || state.promotion != null || state.confirmation != null) return
        val position = state.game?.takeIf { it.result == null }?.position ?: return
        val selection = state.selection
        if (position[square]?.side == position.sideToMove) {
            val moves = position.legalMovesFrom(square)
            _uiState.update {
                it.copy(selection = square, destinations = moves.map(Move::to).toSet())
            }
        } else if (selection != null && square in state.destinations) {
            val promotes = position.legalMovesFrom(selection)
                .any { it.to == square && it.promotion != null }
            if (promotes) {
                _uiState.update { it.copy(promotion = Move(selection, square)) }
            } else {
                commit(position, Move(selection, square))
            }
        }
    }

    fun onPromotionChosen(type: PieceType) {
        val state = _uiState.value
        val move = state.promotion ?: return
        val position = state.game?.position ?: return
        _uiState.update { it.copy(promotion = null) }
        commit(position, move.copy(promotion = type))
    }

    fun onPromotionCancelled() {
        _uiState.update { it.copy(promotion = null) }
    }

    fun onResignRequested() = askDuringPlay(Confirmation.Resign)

    fun onDrawRequested() = askDuringPlay(Confirmation.Draw)

    /**
     * After the end, starts afresh at once. During play, or when the saved game couldn't be
     * read and so might still be in play, asks first.
     */
    fun onNewGameRequested() {
        val state = _uiState.value
        if (busy || state.loading) return
        if (state.game?.result != null) {
            save(GameRecord.New)
        } else {
            _uiState.update { it.copy(confirmation = Confirmation.Replace) }
        }
    }

    fun onConfirmed() {
        val state = _uiState.value
        val confirmation = state.confirmation ?: return
        _uiState.update { it.copy(confirmation = null) }
        val position = state.game?.position
        val record = when (confirmation) {
            Confirmation.Replace -> GameRecord.New
            Confirmation.Resign -> position?.let {
                GameRecord(it, GameResult(it.sideToMove.opponent, EndReason.Resignation))
            }
            Confirmation.Draw -> position?.let {
                GameRecord(it, GameResult(null, EndReason.Agreement))
            }
        } ?: return
        save(record)
    }

    fun onCancelled() {
        _uiState.update { it.copy(confirmation = null) }
    }

    /** Tries the failed read or save again. */
    fun onRetry() {
        when (_uiState.value.failure) {
            Failure.Read -> load()
            Failure.Write -> unsaved?.let(::save)
            null -> Unit
        }
    }

    private fun askDuringPlay(confirmation: Confirmation) {
        val game = _uiState.value.game
        if (busy || game == null || game.result != null) return
        _uiState.update { it.copy(confirmation = confirmation) }
    }

    private fun commit(position: Position, move: Move) {
        val next = position.play(move)
        save(GameRecord(next, next.automaticResult()))
    }

    /**
     * Saves [record] and shows it once saved. If it can't be saved, the board shows the saved
     * game as it was, with nothing selected, and Retry can try the same change again.
     */
    private fun save(record: GameRecord) {
        if (busy) return
        busy = true
        viewModelScope.launch {
            val failure = try {
                repository.save(record)
                unsaved = null
                null
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                unsaved = record
                Failure.Write
            }
            try {
                _uiState.update {
                    it.copy(
                        game = if (failure == null) record else it.game,
                        selection = null,
                        destinations = emptySet(),
                        failure = failure
                    )
                }
            } finally {
                busy = false
            }
        }
    }

    private fun load() {
        if (busy) return
        busy = true
        _uiState.update { it.copy(loading = true) }
        viewModelScope.launch {
            try {
                val game = repository.load() ?: GameRecord.New
                _uiState.update { it.copy(loading = false, game = game, failure = null) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _uiState.update { it.copy(loading = false, game = null, failure = Failure.Read) }
            } finally {
                busy = false
            }
        }
    }
}
