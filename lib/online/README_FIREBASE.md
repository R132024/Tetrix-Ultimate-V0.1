# Modo Online 1v1 — Firebase + WebRTC (BeatBlocks)

Este módulo (`lib/online/`) implementa PvP 1v1 con **Firebase Realtime Database
como servidor de señalización** y **WebRTC DataChannels para el gameplay P2P**.
Una vez establecido el puente WebRTC, Firebase ya **no** participa en la partida,
por lo que el costo se mantiene casi a cero incluso con miles de usuarios.

---

## 1. Estructura ideal de la Realtime Database

```json
{
  "usuarios": {
    "<uid>": {
      "nombre": "Player1",
      "avatar": 3,
      "es_premium": false,        // se lee SOLO al iniciar la app (suscripción Google Play)
      "ultimo_acceso": 1718200000000
    }
  },
  "salas_pvp": {
    "<roomId>": {
      "estado": "esperando_rival",   // esperando_rival | jugando | terminado
      "creado": 1718200000000,
      "host_sdp":   { "type": "offer",  "sdp": "..." },
      "client_sdp": { "type": "answer", "sdp": "..." },
      "ice_candidates_host": {
        "<pushId>": { "candidate": "...", "sdpMid": "0", "sdpMLineIndex": 0 }
      },
      "ice_candidates_client": {
        "<pushId>": { "candidate": "...", "sdpMid": "0", "sdpMLineIndex": 0 }
      }
    }
  }
}
```

### Reglas de seguridad recomendadas (resumen)
```json
{
  "rules": {
    "usuarios": {
      "$uid": {
        ".read":  "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "salas_pvp": {
      "$room": {
        ".read":  "auth != null",
        ".write": "auth != null",
        // Auto-expira: limpia salas viejas con una Cloud Function programada.
        ".indexOn": ["estado"]
      }
    }
  }
}
```

> **`es_premium`**: pensado para tu sistema de suscripciones de Google Play.
> Se lee una sola vez al arrancar (`usuarios/<uid>/es_premium`) y se cachea en
> memoria, sin listeners permanentes, para no afectar el rendimiento.

---

## 2. Configuración nativa requerida

El código Dart ya está listo, pero **debes** configurar Firebase y los permisos
de WebRTC (esto no se puede hacer desde el código Dart solo):

1. Crea un proyecto en <https://console.firebase.google.com> y habilita
   **Realtime Database**.
2. Instala FlutterFire y genera `firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Luego en `main.dart` cambia a:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
3. Coloca `google-services.json` (Android) y `GoogleService-Info.plist` (iOS).
4. **Permisos WebRTC**:
   - Android `AndroidManifest.xml`:
     ```xml
     <uses-permission android:name="android.permission.INTERNET"/>
     <uses-permission android:name="android.permission.CAMERA"/>
     <uses-permission android:name="android.permission.RECORD_AUDIO"/>
     <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
     ```
     (Para solo-DataChannel, INTERNET basta; los de cámara/audio se piden por
     compatibilidad de `flutter_webrtc`.)
   - `minSdkVersion` ≥ 23 en `android/app/build.gradle`.
   - iOS: añade `NSCameraUsageDescription` y `NSMicrophoneUsageDescription` en
     `Info.plist`.
5. Para NAT estricto en producción, añade un **servidor TURN** en `_rtcConfig`
   dentro de `p2p_game_manager.dart` (Twilio, Metered, o coturn propio).

---

## 3. Flujo resumido

| Paso | Host | Cliente |
|------|------|---------|
| 1 | `crearPartida()` → crea sala + Offer | comparte link por WhatsApp |
| 2 | escucha `client_sdp` | `unirseAPartida(roomId)` lee Offer |
| 3 | recibe Answer → `setRemoteDescription` | genera Answer → sube a Firebase |
| 4 | intercambian ICE candidates por Firebase | idem |
| 5 | **DataChannel abierto** → gameplay P2P directo | idem |
| 6 | `terminarPartida()` borra la sala y cancela listeners | `terminarPartida()` |

El intercambio de gameplay (`enviarLineaBasura`, `enviarGameOver`, etc.) viaja
**solo** por el DataChannel, nunca por Firebase.
