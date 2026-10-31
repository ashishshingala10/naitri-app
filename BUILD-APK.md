# Getting the APK for review

The app is delivered as Flutter **source**, not a pre-built APK. An APK can only be produced
by the Flutter/Android toolchain, so pick one of the two ways below — both give you an
`app-release.apk` you can install on any Android phone (enable "Install unknown apps").

## Option A — no local setup (cloud build) ✅ easiest
1. Put the `app/` folder in a GitHub repo (new repo is fine).
2. Push it. The included workflow (`.github/workflows/build-apk.yml`) runs automatically,
   or open the repo's **Actions** tab → **Build APK** → **Run workflow**.
3. When it finishes (~5 min), open that run → **Artifacts** → download **naitri-app-apk**.
   Unzip to get `app-release.apk`.

The workflow installs Flutter, generates the Android project, enables the one Gradle setting
the notifications plugin needs, and builds the release APK. Nothing to install on your machine.

## Option B — build locally
Needs Flutter + Android SDK installed once (https://docs.flutter.dev/get-started/install).
```bash
cd app
flutter create .          # generate android/ scaffolding (keeps lib/ and the manifest)
flutter pub get
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### If the build fails on `flutter_local_notifications`
Add core-library desugaring to `android/app/build.gradle.kts` (or `build.gradle`):
```kotlin
android { compileOptions { isCoreLibraryDesugaringEnabled = true } }
dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
```
(The cloud workflow already does this for you.)

## Point the app at your server before building
By default the app talks to `http://10.0.2.2:3000/api/app` (emulator → your PC).
For a real phone, build against your server:
```bash
flutter build apk --release --dart-define=API=https://api.naitri.in/api/app
```

## Test login
Run the backend with demo data (`node src/seed-demo.js`), then in the app:
phone **9988776655**, OTP **123456**.
