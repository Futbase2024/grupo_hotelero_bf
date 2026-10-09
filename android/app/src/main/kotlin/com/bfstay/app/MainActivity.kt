package com.bfstay.app

import io.flutter.embedding.android.FlutterActivity

/**
 * Activity principal de BF Stay.
 *
 * No configura edge-to-edge manualmente: `WindowCompat.setDecorFitsSystemWindows()` está
 * deprecado y desde API 35 el comportamiento edge-to-edge es el predeterminado. Para versiones
 * anteriores lo aplica el engine de Flutter al recibir `SystemUiMode.edgeToEdge` (ver
 * `lib/main.dart`), por lo que duplicarlo aquí solo añadía APIs obsoletas al bundle.
 */
class MainActivity : FlutterActivity()
