# Configuración nativa (copiar/pegar)

## Android
1. `android/app/build.gradle(.kts)` → dentro de `defaultConfig`:
   `minSdk = 23`   (flutter_secure_storage lo exige)
2. `android/app/src/main/AndroidManifest.xml` → antes de `<application>`:
   ```xml
   <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
   ```
3. `MainActivity.kt` → que extienda `FlutterFragmentActivity` (ver MainActivity.kt de esta carpeta).
4. `android/app/src/main/res/values/styles.xml` (y `values-night/styles.xml`):
   cambia el `parent` de `LaunchTheme` y `NormalTheme` a `Theme.AppCompat.DayNight`.

## iOS
`ios/Runner/Info.plist` → agregar dentro de `<dict>`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Usamos Face ID para que inicies sesión de forma rápida y segura.</string>
```
