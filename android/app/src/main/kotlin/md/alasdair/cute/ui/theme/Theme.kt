package md.alasdair.cute.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.platform.LocalContext

/**
 * The board's own colours, which Material's colour scheme doesn't carry. They come from the
 * light dynamic scheme in both appearances, like a physical board, so that the white and black
 * pieces read the same way on every square.
 */
@Immutable
data class BoardColors(
    val lightSquare: Color,
    val darkSquare: Color,
    val marker: Color,
    val pieceInk: Color,
    val pieceFillWhite: Color,
    val pieceFillBlack: Color
)

val LocalBoardColors = staticCompositionLocalOf {
    BoardColors(
        lightSquare = Color(0xFFE6E1D3),
        darkSquare = Color(0xFF8E8A7E),
        marker = Color(0xFF1B5E20),
        pieceInk = Color.Black,
        pieceFillWhite = Color.White,
        pieceFillBlack = Color.Black
    )
}

/**
 * The app's one theme. Dynamic colour on every supported device (AGENTS.md, Android colour):
 * the minimum API level, 36, always supports it.
 */
@Composable
fun CuteTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val context = LocalContext.current
    val light = dynamicLightColorScheme(context)
    val colorScheme = if (darkTheme) dynamicDarkColorScheme(context) else light
    val boardColors = BoardColors(
        lightSquare = light.primaryContainer,
        darkSquare = lerp(light.primary, light.primaryContainer, 0.45f),
        marker = light.tertiary,
        pieceInk = Color.Black,
        pieceFillWhite = Color.White,
        pieceFillBlack = Color.Black
    )
    CompositionLocalProvider(LocalBoardColors provides boardColors) {
        MaterialTheme(colorScheme = colorScheme, content = content)
    }
}
