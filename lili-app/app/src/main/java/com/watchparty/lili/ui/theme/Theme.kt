package com.watchparty.lili.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LiliColors = darkColorScheme(
    primary          = RosePink,
    onPrimary        = Color.White,
    primaryContainer = Color(0xFF4A1030),
    secondary        = SoftLavender,
    onSecondary      = Color(0xFF1A1040),
    background       = DeepNight,
    onBackground     = WarmWhite,
    surface          = NightSurface,
    onSurface        = WarmWhite,
    surfaceVariant   = CardBg,
    onSurfaceVariant = DimWhite,
    error            = Color(0xFFFF6B6B),
)

@Composable
fun LiliTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LiliColors,
        typography  = LiliTypography,
        content     = content,
    )
}
