# 🔐 Flutter Biometría + Almacenamiento Seguro

Demo de **login con huella / Face ID** y **guardado cifrado de tokens** en Flutter.

| Paquete | Para qué sirve |
|---|---|
| [`local_auth`](https://pub.dev/packages/local_auth) | Pide huella / Face ID usando el diálogo nativo del sistema |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Guarda datos cifrados (Android Keystore / iOS Keychain) |

## ¿Qué hace la app?
1. Login con correo y contraseña (`demo@demo.com` / `1234`) → el token se guarda **cifrado**.
2. Al volver a abrir la app aparece el botón **"Entrar con huella / Face ID"**: si la biometría es correcta, se lee el token y se entra sin escribir la contraseña.
3. En la pantalla principal, ver el token completo **vuelve a pedir huella**.
4. Se puede guardar una **API key de un modelo de IA** de forma cifrada (en vez de dejarla en el código).
5. Cerrar sesión borra todo del almacenamiento seguro.

## 👤 Métodos de acceso y "quién ingresó"
La pantalla de login tiene **3 botones: huella, rostro y PIN** (más contraseña para la primera vez).
- Al entrar, el Home muestra un mensaje como **"Ingresó Persona 1 con huella"** y la hora.
- Los nombres (Persona 1/2/3) se editan con el ícono ✏️ de la barra superior.
- El **token es el mismo** para todos los métodos: viene del servidor en el login con contraseña y se guarda cifrado una sola vez. Lo que cambia es *cómo se desbloquea*.
- El **PIN** es de la app (4 dígitos), se crea tras el primer login con contraseña y se guarda en `flutter_secure_storage`.

**Limitaciones reales del sistema operativo:**
- Android/iOS **no le dicen a la app quién es el dueño de la huella** ni su nombre registrado; solo responden sí/no. Por eso los nombres los define la app.
- En Android la app **no puede exigir "solo rostro" o "solo huella"**: el sistema acepta la biometría que el usuario tenga registrada. En iOS sí se distingue según el dispositivo (Face ID o Touch ID).
- El emulador de Android normalmente solo simula huella; el rostro se prueba en el simulador de iOS o en un celular real con desbloqueo facial.

## 🚀 Cómo correrlo (paso a paso)

**Requisitos:** Flutter 3.x instalado (`flutter doctor` sin errores) y un emulador/dispositivo.

```bash
# 1. Clonar este repositorio
git clone <URL_DE_ESTE_REPO>
cd flutter_biometria_demo

# 2. Generar las carpetas nativas android/ e ios/ (el repo solo trae lib/ y pubspec)
flutter create . --project-name flutter_biometria_demo

# 3. Instalar dependencias
flutter pub get
```

**4. Configurar permisos nativos** → sigue `platform_config/ANDROID_Y_IOS.md` (son 4 cambios en Android y 1 en iOS).

**5. Registrar una huella en el emulador**
- **Android:** Ajustes del emulador → Seguridad → Huella digital → agregar (te pedirá PIN primero). Para "tocar el sensor": `⋯` (Extended controls) → **Fingerprint** → *Touch the sensor*.
- **iOS Simulator:** menú *Features → Face ID → Enrolled*; para validar: *Features → Face ID → Matching Face*.

```bash
# 6. Ejecutar
flutter run
```

## 🧪 Probar el flujo
1. Entra con contraseña (`demo@demo.com` / `1234`).
2. Cierra la app por completo y ábrela de nuevo.
3. Aparece el botón de huella → tócalo → en el emulador simula la huella.
4. Prueba también "Fingerprint no coincide" para ver el manejo de error.

## 📁 Estructura
```
lib/
├── main.dart                      # Punto de entrada
├── services/
│   ├── biometric_service.dart     # Envuelve local_auth
│   ├── token_storage.dart         # Envuelve flutter_secure_storage
│   ├── ai_service.dart            # Llamada a la API de Gemini
│   └── fake_auth_api.dart         # Backend simulado
└── screens/
    ├── login_screen.dart          # Login + botón biométrico
    ├── home_screen.dart           # Token protegido + API key de IA
    └── ai_chat_screen.dart        # Chat con IA (tras la huella)
```

## 🤖 IA real incluida (Gemini)
La app trae un **asistente de IA funcional**:
1. Consigue una API key gratis en [Google AI Studio](https://aistudio.google.com) → *Get API key*.
2. En la pantalla principal pégala en el campo y pulsa **Guardar cifrada** (queda en Keystore/Keychain).
3. Pulsa **Abrir asistente IA** → pide huella → chatea con el modelo.
- El modelo se define en `lib/services/ai_service.dart` (constante `model`). Si da error 404, revisa los nombres vigentes en la documentación de Gemini y cambia solo esa línea.
- Para builds *release* en Android agrega `<uses-permission android:name="android.permission.INTERNET"/>` al `AndroidManifest.xml` (en debug ya viene).

## 🤖 Usos reales con IA
- Guardar la **API key** de OpenAI/Gemini/Claude en el dispositivo sin exponerla en el código.
- Proteger el **historial de chats** de un asistente/chatbot detrás de la huella.
- Pedir biometría antes de acciones sensibles de una app con IA (exportar datos, borrar conversaciones).
- Guardar el token de sesión del backend que sirve el modelo.

> ⚠️ En apps de producción real, la API key del LLM debe vivir en tu backend, no en el celular. Aquí se muestra como ejemplo de almacenamiento seguro.

## 🛠️ Problemas frecuentes
| Problema | Solución |
|---|---|
| `MissingPluginException` / crash al pedir huella en Android | `MainActivity` debe extender `FlutterFragmentActivity` |
| Error de tema `AppCompat` | Cambiar parent de `LaunchTheme`/`NormalTheme` a `Theme.AppCompat.DayNight` |
| Error de `minSdkVersion` | Poner `minSdk = 23` |
| "Biometría NO disponible" | Registrar una huella/Face ID en el emulador |
| Conflicto de versiones | `flutter pub upgrade --major-versions` |
