# Asha — Flutter App
 
## Run on an Android emulator or phone (step by step)
 
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. From this folder, install packages:
   ```
   flutter pub get
   ```
3. Point the app at your backend — edit `lib/services/api_service.dart`:
   - Android emulator → `http://10.0.2.2:5000` (already set)
   - Real Android phone on same WiFi → `http://<your-computer-LAN-IP>:5000`
4. Add your Google Maps API key (Doctor Finder map screen needs it):
   - `android/app/src/main/AndroidManifest.xml` → inside `<application>`:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY"/>
     ```
5. **To preview on an Android phone:**
   - Enable Developer Options + USB Debugging on the phone
   - Connect via USB, run `flutter devices` to confirm it's detected
   - Run `flutter run` — installs and launches the app directly on your phone
6. **To generate a shareable APK** (install on any Android phone without a cable):
   ```
   flutter build apk --release
   ```
   The APK appears at `build/app/outputs/flutter-apk/app-release.apk` —
   copy it to the phone and tap to install (allow "install from unknown sources").
 
## Project structure
```
lib/
  main.dart                 — app entry point
  theme/app_theme.dart       — colors, buttons, card styling
  models/models.dart         — data models (UserProfile, PredictionResult, etc.)
  services/api_service.dart  — all backend calls
  widgets/bottom_nav_shell.dart — 5-tab navigation shell
  screens/                   — one file per screen (19 screens)
```