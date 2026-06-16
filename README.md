# tvOnline

Aplicación de streaming IPTV multiplataforma construida con Flutter. Soporta películas, series y TV en vivo a través del protocolo Xtream Codes. Disponible para iOS, macOS, Android y Windows.

---

## Características

### Reproducción
- Reproductor de video con `media_kit` (basado en libmpv) — soporta HLS, TS, MKV, MP4 y prácticamente cualquier formato
- Pantalla completa automática con controles que se ocultan solos
- **Scrubbing interactivo**: previsualización de tiempo mientras arrastras la barra de progreso
- Avance automático al siguiente episodio con cuenta regresiva de 5 segundos
- Navegación entre episodios (anterior / siguiente) sin salir del reproductor
- Selección de pista de audio y subtítulos por contenido (se recuerda por cada título)
- Reanudación desde donde lo dejaste — guarda posición y duración

### Contenido
- **Inicio**: Hero banner animado, carrusel "Continuar viendo", trending, top rated, series destacadas
- **Películas (VOD)**: catálogo completo con filtros por categoría, badge de valoración y progreso
- **Series**: catálogo con temporadas, episodios por temporada, badge VISTO y barra de progreso por episodio
- **TV en vivo**: canales por categoría con logos
- **Búsqueda**: filtros por Todo / Películas / Series, búsqueda instantánea
- **Mi lista (Watchlist)**: guarda contenido para ver después
- **Historial**: muestra todo lo visto agrupado por fecha (Hoy / Ayer / Esta semana / Antes), con barra de progreso y tiempo restante. Desliza para eliminar entradas

### Usuario y Administración
- **Perfil**: estado de suscripción, envío de comprobante de pago con imagen adjunta
- **Sugerencias**: buzón para proponer películas o series, visualiza las del resto
- **Ajustes**: calidad de video, idioma de audio y subtítulos, limpiar caché, cerrar sesión
- **Panel de administración** (solo rol `admin`): gestión de usuarios y pagos pendientes via Supabase

### Seguridad y privacidad
- Credenciales IPTV almacenadas con ofuscación XOR + Base64 en SharedPreferences
- En iOS: el archivo de preferencias se excluye del backup de iCloud (las credenciales no se restauran al reinstalar)
- Instalación limpia → pantalla de login vacía (sin datos preexistentes)
- Secrets de build inyectados vía `--dart-define-from-file` en tiempo de compilación; `env.json` nunca se commitea

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Framework | Flutter 3.41.9 / Dart 3.3+ |
| Estado | Riverpod 2.6 (`StateProvider`, `FutureProvider`, `ConsumerWidget`) |
| Navegación | GoRouter 14 con shell routes y guards por rol |
| Video | media_kit 1.1 + media_kit_video 1.2 (libmpv) |
| API IPTV | Xtream Codes Protocol (Dio 5.7) |
| Backend | Supabase (usuarios, suscripciones, pagos, sugerencias) |
| Almacenamiento local | SharedPreferences 2.3 |
| Imágenes | cached_network_image 3.4 |
| UI | Material 3, shimmer, animations, smooth_page_indicator |
| CI/CD | GitHub Actions (macos-15, ubuntu-latest, windows-latest) |

---

## Estructura del proyecto

```
lib/
├── core/
│   ├── constants/       # AppConstants (claves de SharedPreferences)
│   ├── network/         # XtreamApi — cliente Dio para Xtream Codes
│   ├── router/          # GoRouter con guards y shell routes
│   ├── storage/         # AppStorage, WatchHistoryEntry, ContentTrackSettings
│   ├── supabase/        # SupabaseConfig + SupabaseService
│   └── theme/           # AppColors, AppTextStyles, AppTheme
├── features/
│   ├── admin/           # Panel de administración (solo rol admin)
│   ├── auth/            # ServerConfigScreen — login / setup IPTV
│   ├── catalog/         # VodCatalogScreen, SeriesCatalogScreen, FilterBar
│   ├── detail/          # VodDetailScreen, SeriesDetailScreen + _EpisodeTile
│   ├── history/         # HistoryScreen con agrupación por fecha
│   ├── home/            # HomeScreen, HeroBanner, ContentCarousel
│   ├── live/            # LiveScreen — canales en vivo por categoría
│   ├── player/          # PlayerScreen — reproductor completo con controles
│   ├── profile/         # UserProfileScreen — suscripción y pagos
│   ├── search/          # SearchScreen con filtros Todo/Películas/Series
│   ├── settings/        # SettingsScreen — calidad, idioma, caché, logout
│   ├── suggestions/     # SuggestionsScreen — sugerir y ver sugerencias
│   └── watchlist/       # WatchlistScreen — lista personal guardada
└── shared/
    ├── models/          # VodStream, SeriesModel, LiveChannel, CategoryModel
    └── widgets/         # GridCard, MainScaffold, ShimmerCard
```

---

## Requisitos previos

- Flutter 3.41.9 (`flutter --version`)
- Dart 3.3+
- Un servidor IPTV con soporte para el protocolo **Xtream Codes**
- Cuenta en [Supabase](https://supabase.com) (para usuarios, pagos y sugerencias)
- Archivo `env.json` con las claves (ver sección siguiente)

---

## Configuración local (`env.json`)

Crea un archivo `env.json` en la raíz del proyecto. **Este archivo nunca debe commitearse** (ya está en `.gitignore`).

```json
{
  "SUPABASE_URL": "https://tu-proyecto.supabase.co",
  "SUPABASE_ANON_KEY": "eyJ...",
  "STORAGE_OBFUSCATION_KEY": "tu-clave-de-ofuscacion"
}
```

| Variable | Descripción |
|---|---|
| `SUPABASE_URL` | URL del proyecto Supabase |
| `SUPABASE_ANON_KEY` | Anon/public key de Supabase |
| `STORAGE_OBFUSCATION_KEY` | Clave para ofuscar credenciales IPTV en SharedPreferences |

---

## Desarrollo local

```bash
# Instalar dependencias
flutter pub get

# Correr en dispositivo/simulador
flutter run --dart-define-from-file=env.json

# Correr en macOS
flutter run -d macos --dart-define-from-file=env.json

# Correr en dispositivo iOS conectado
flutter run -d <DEVICE_ID> --dart-define-from-file=env.json
```

---

## Build por plataforma

### iOS

```bash
# Build archive
flutter build ipa --no-codesign --dart-define-from-file=env.json

# Exportar IPA firmado con tu cuenta de desarrollador
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates

# O usar el script incluido (también sube al release de GitHub)
./scripts/release_ios.sh v1.0.1
```

> `ExportOptions.plist` está incluido en el repo. Usa el método `debugging` con el team ID de tu cuenta Apple.

### macOS

```bash
cd macos && pod install && cd ..
flutter build macos --dart-define-from-file=env.json
# App en: build/macos/Build/Products/Release/tvonline.app
```

### Android

```bash
flutter build apk --release --dart-define-from-file=env.json
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

Para firma release, crea `android/key.properties` (no commitear):

```properties
storePassword=tu-password
keyPassword=tu-key-password
keyAlias=tu-alias
storeFile=release.jks
```

### Windows

```bash
flutter config --enable-windows-desktop
flutter build windows --dart-define-from-file=env.json
# Ejecutable en: build/windows/x64/runner/Release/tvonline.exe
```

---

## CI/CD — GitHub Actions

El workflow `.github/workflows/release.yml` se dispara automáticamente al hacer push de un tag `v*`.

### Cómo crear un nuevo release

```bash
git tag v1.0.2
git push origin v1.0.2
```

Esto lanza tres jobs en paralelo:

| Job | Runner | Artefacto |
|---|---|---|
| `build-macos` | `macos-15` | `tvOnline-macOS.zip` |
| `build-android` | `ubuntu-latest` | `tvOnline-Android.apk` |
| `build-windows` | `windows-latest` | `tvOnline-Windows.zip` |

Cuando los tres terminan, el job `release` crea automáticamente el GitHub Release con los tres archivos y las instrucciones de instalación.

> iOS se excluye del CI porque requiere un certificado de Apple registrado en el runner. Se sube manualmente con `./scripts/release_ios.sh <tag>`.

### Secrets requeridos en GitHub

Ve a **Settings → Secrets and variables → Actions** y agrega:

| Secret | Descripción |
|---|---|
| `SUPABASE_URL` | URL del proyecto Supabase |
| `SUPABASE_ANON_KEY` | Anon key de Supabase |
| `STORAGE_OBFUSCATION_KEY` | Clave de ofuscación de credenciales |

### Secrets opcionales (firma Android release)

| Secret | Descripción |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Keystore en Base64 (`base64 -i release.jks`) |
| `ANDROID_KEY_STORE_PASSWORD` | Password del keystore |
| `ANDROID_KEY_PASSWORD` | Password de la clave |
| `ANDROID_KEY_ALIAS` | Alias de la clave |

Sin estos secrets el APK se firma con la clave debug (funcional pero no apta para Google Play).

---

## Instalación por plataforma

### iOS — iPhone / iPad

> Requiere Mac con Xcode y una cuenta de desarrollador Apple (gratuita).

1. Descarga `tvOnline.ipa` del release
2. Conecta el iPhone al Mac y ejecuta:
   ```bash
   # Ver dispositivos disponibles
   flutter devices

   # Instalar (usa el ID que aparece en flutter devices)
   xcrun devicectl device install app --device <DEVICE_ID> build/ios/iphoneos/Runner.app
   ```
3. En el iPhone: **Ajustes → General → VPN y gestión de dispositivos** → toca el desarrollador → **Confiar**

### macOS

1. Descarga y descomprime `tvOnline-macOS.zip`
2. **Primera vez**: haz clic derecho → **Abrir** en `tvonline.app`
3. Confirma en el diálogo de Gatekeeper
4. Mueve a `/Applications` si lo deseas

> Si sigue bloqueada: **Ajustes del Sistema → Privacidad y seguridad → Abrir de todas formas**

### Android

1. En tu Android: **Ajustes → Aplicaciones → Instalar apps desconocidas** → actívalo para tu navegador
2. Descarga `tvOnline-Android.apk` directamente en el dispositivo
3. Toca el archivo descargado e instala

> Requiere Android 6.0 (API 23) o superior.

### Windows

1. Descarga y descomprime `tvOnline-Windows.zip` en la carpeta que prefieras
2. Ejecuta `tvonline.exe`
3. Si Windows Defender SmartScreen aparece: **Más información → Ejecutar de todas formas**

> Requiere Windows 10 versión 1903+ (64-bit). No necesita instalación.

---

## Primer inicio

La primera vez que abres la app aparece la pantalla de configuración:

1. **URL del servidor** IPTV — formato `http://tuservidor.com:8080`
2. **Usuario** y **contraseña** de tu cuenta IPTV

Una vez configurado, el acceso queda guardado localmente en el dispositivo. Las credenciales se ofuscan en el almacenamiento y en iOS se excluyen del backup de iCloud, garantizando que cada instalación limpia pide credenciales nuevas.

---

## Protocolo Xtream Codes

La app se conecta a cualquier servidor IPTV compatible con Xtream Codes. Los endpoints que utiliza:

| Acción | Parámetro |
|---|---|
| Autenticación | `player_api.php?username=&password=` |
| Categorías VOD | `action=get_vod_categories` |
| Películas | `action=get_vod_streams` |
| Detalle película | `action=get_vod_info&vod_id=` |
| Categorías series | `action=get_series_categories` |
| Series | `action=get_series` |
| Detalle serie | `action=get_series_info&series_id=` |
| Categorías live | `action=get_live_categories` |
| Canales en vivo | `action=get_live_streams` |

Las URLs de streaming se construyen como:
- VOD: `{server}/movie/{user}/{pass}/{stream_id}.{ext}`
- Series: `{server}/series/{user}/{pass}/{episode_id}.{ext}`
- Live: `{server}/live/{user}/{pass}/{stream_id}.ts`

---

## Archivos que nunca deben commitearse

```
env.json                    # Supabase keys + obfuscation key
android/key.properties      # Android signing config
android/app/*.jks           # Android keystore
android/app/*.keystore      # Android keystore (alternativo)
```

Todos están incluidos en `.gitignore`.

---

## Releases

Los releases oficiales están en [GitHub Releases](../../releases). Cada release incluye:

- `tvOnline-macOS.zip` — aplicación macOS (arm64)
- `tvOnline-Android.apk` — APK Android universal
- `tvOnline-Windows.zip` — ejecutable Windows portable (x64)
- `tvOnline.ipa` — instalable iOS (subido manualmente con `scripts/release_ios.sh`)
