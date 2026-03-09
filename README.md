# 💊 PillCare – Pastillero Inteligente

App de recordatorio de medicamentos para Android e iOS, construida con Flutter.

---

## 🚀 Requisitos previos

Antes de ejecutar la app, asegúrate de tener instalado:

### 1. Flutter SDK
- Descarga en: https://docs.flutter.dev/get-started/install
- Versión recomendada: **Flutter 3.19+**
- Agrega Flutter al PATH de tu sistema

### 2. Visual Studio Code
- Descarga en: https://code.visualstudio.com/
- Instala las extensiones:
  - **Flutter** (Dart-Code.flutter)
  - **Dart** (Dart-Code.dart-code)
  - Puedes instalarlas desde VS Code → Extensions → buscar "Flutter"

### 3. Android Studio (para Android)
- Descarga en: https://developer.android.com/studio
- Instala Android SDK y crea un emulador AVD, o conecta un dispositivo físico
- Acepta las licencias: `flutter doctor --android-licenses`

### 4. Xcode (solo macOS, para iOS)
- Descarga desde la App Store
- Ejecuta: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- Instala CocoaPods: `sudo gem install cocoapods`

---

## ⚡ Instalación y ejecución

### Paso 1 – Verificar el entorno
```bash
flutter doctor
```
Asegúrate de que Android y iOS (en Mac) estén en verde ✓

### Paso 2 – Abrir el proyecto en VS Code
```bash
cd pillcare
code .
```

### Paso 3 – Instalar dependencias
```bash
flutter pub get
```

### Paso 4 – Para iOS, instalar pods (solo macOS)
```bash
cd ios
pod install
cd ..
```

### Paso 5 – Ejecutar la app

**Opción A – Desde VS Code:**
1. Abre la paleta de comandos: `Cmd+Shift+P` (Mac) / `Ctrl+Shift+P` (Windows)
2. Escribe: `Flutter: Select Device`
3. Elige tu emulador o dispositivo
4. Presiona `F5` o ve a **Run > Start Debugging**

**Opción B – Desde terminal:**
```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device_id>

# Ejecutar en Android
flutter run -d android

# Ejecutar en iOS (solo Mac)
flutter run -d ios
```

---

## 📁 Estructura del proyecto

```
pillcare/
├── lib/
│   ├── main.dart                  # Entrada principal
│   ├── models/
│   │   ├── alarm.dart             # Modelo de alarma
│   │   ├── app_theme.dart         # Colores y constantes
│   │   └── alarm_storage.dart     # Persistencia local
│   └── screens/
│       ├── login_screen.dart      # Pantalla de login
│       ├── home_screen.dart       # Home con calendario
│       └── alarm_form_screen.dart # Crear/editar alarma
├── android/                       # Config Android
├── ios/                           # Config iOS
├── .vscode/
│   ├── launch.json                # Configuración de depuración
│   └── extensions.json            # Extensiones recomendadas
└── pubspec.yaml                   # Dependencias
```

---

## ✨ Funcionalidades

| Feature | Descripción |
|---------|-------------|
| 🔐 Login | Pantalla de inicio de sesión |
| 📅 Calendario semanal | Visualiza la semana, selecciona día |
| ➕ Nueva alarma | Crea recordatorios con título y dosis |
| ⏰ Hora específica | Selector de hora con AM/PM |
| 🔄 Cada X horas | Calcula automáticamente los horarios del día |
| 📋 Selector de días | Activa qué días de la semana aplica |
| 🎨 Color por medicamento | Distingue visualmente cada medicamento |
| 👈 Deslizar → Editar/Eliminar | Swipe izquierda sobre alarma |
| 🔔 Toggle on/off | Activa/desactiva sin eliminar |
| 💾 Persistencia | Las alarmas se guardan localmente |

---

## 🛠️ Dependencias principales

```yaml
flutter_slidable: ^3.1.0      # Swipe para editar/eliminar
shared_preferences: ^2.2.2    # Guardar alarmas localmente
flutter_local_notifications   # Notificaciones
intl: ^0.19.0                 # Formato de fechas
google_fonts: ^6.2.1          # Tipografías
```

---

## 🐛 Solución de problemas

**Error: `flutter: command not found`**
→ Asegúrate de que Flutter esté en el PATH. Reinicia VS Code.

**Error en Android: SDK not found**
→ Crea el archivo `android/local.properties` con:
```
flutter.sdk=/ruta/a/flutter
sdk.dir=/ruta/a/android-sdk
```

**Error en iOS: pod install failed**
→ Ejecuta `pod repo update` y luego `pod install` de nuevo.

**Emulador lento**
→ Activa la aceleración de hardware (HAXM) en Android Studio.
