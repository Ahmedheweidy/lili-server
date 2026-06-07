package com.watchparty.lili.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.watchparty.lili.ui.theme.*

@Composable
fun JoinScreen(
    serverUrl: String,
    connectionError: Boolean,
    onJoin: (username: String, serverUrl: String) -> Unit,
    onClearError: () -> Unit,
) {
    var selected by remember { mutableStateOf("") }
    var urlInput by remember { mutableStateOf(serverUrl) }
    var showUrl by remember { mutableStateOf(false) }

    val bg = Brush.verticalGradient(
        listOf(Color(0xFF0D0D1A), Color(0xFF1A0F2E), Color(0xFF0D0D1A))
    )

    Box(
        modifier = Modifier.fillMaxSize().background(bg),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Spacer(Modifier.height(48.dp))

            Text("💕", fontSize = 56.sp)

            Text(
                text = "Lili Watch",
                style = MaterialTheme.typography.headlineLarge,
                color = RosePink,
                fontWeight = FontWeight.Bold,
            )

            Text(
                text = "نتفرج سوا مهما بعدنا",
                color = DimWhite,
                textAlign = TextAlign.Center,
                fontSize = 16.sp,
            )

            Spacer(Modifier.height(8.dp))

            Text(
                text = "مين انت؟",
                style = MaterialTheme.typography.headlineMedium,
                color = WarmWhite,
            )

            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                PersonCard(
                    name = "أحمد",
                    emoji = "👨‍💻",
                    selected = selected == "أحمد",
                    onClick = { selected = "أحمد"; onClearError() },
                )
                PersonCard(
                    name = "ليلى",
                    emoji = "🌸",
                    selected = selected == "ليلى",
                    onClick = { selected = "ليلى"; onClearError() },
                )
            }

            AnimatedVisibility(visible = connectionError) {
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = Color(0x33FF5252),
                ) {
                    Text(
                        text = "❌ مش قادر يوصل للسيرفر. تأكد من الـ URL",
                        color = Color(0xFFFF6B6B),
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                        textAlign = TextAlign.Center,
                        fontSize = 14.sp,
                    )
                }
            }

            TextButton(onClick = { showUrl = !showUrl }) {
                Text(
                    if (showUrl) "إخفاء إعدادات السيرفر" else "⚙️ إعدادات السيرفر",
                    color = SoftLavender,
                )
            }

            AnimatedVisibility(visible = showUrl) {
                OutlinedTextField(
                    value = urlInput,
                    onValueChange = { urlInput = it },
                    label = { Text("Server URL") },
                    placeholder = { Text("http://192.168.1.1:3000") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = RosePink,
                        unfocusedBorderColor = Color(0xFF3A2A4A),
                        focusedLabelColor = RosePink,
                        cursorColor = RosePink,
                        focusedTextColor = WarmWhite,
                        unfocusedTextColor = WarmWhite,
                    ),
                )
            }

            Button(
                onClick = { if (selected.isNotEmpty()) onJoin(selected, urlInput) },
                enabled = selected.isNotEmpty(),
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(28.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = RosePink,
                    disabledContainerColor = Color(0xFF4A2030),
                ),
            ) {
                Text("يلا نتفرج 🎬", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White)
            }

            Spacer(Modifier.height(48.dp))
        }
    }
}

@Composable
private fun PersonCard(name: String, emoji: String, selected: Boolean, onClick: () -> Unit) {
    Card(
        modifier = Modifier.width(140.dp).clickable(onClick = onClick),
        shape = RoundedCornerShape(20.dp),
        border = BorderStroke(
            width = if (selected) 2.dp else 1.dp,
            color = if (selected) RosePink else Color(0xFF3A2A4A),
        ),
        colors = CardDefaults.cardColors(
            containerColor = if (selected) Color(0xFF2A0F20) else CardBg,
        ),
    ) {
        Column(
            modifier = Modifier.padding(20.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(emoji, fontSize = 40.sp)
            Text(
                name,
                color = if (selected) RosePink else WarmWhite,
                fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                fontSize = 16.sp,
            )
        }
    }
}
