# 🤖 J.A.R.V.I.S - Complete Build Guide
## Build Your APK for FREE (Cloud-Based)

---

## 📁 PROJECT FILE STRUCTURE

```
jarvis_ai/
├── lib/
│   ├── main.dart                          ← App entry point
│   ├── screens/
│   │   ├── home_screen.dart               ← Main JARVIS UI
│   │   └── settings_screen.dart           ← Settings & name change
│   ├── services/
│   │   ├── background_service.dart        ← Notification bar service
│   │   ├── command_processor.dart         ← Voice command handler
│   │   └── app_launcher_service.dart      ← Opens apps by voice
│   └── widgets/
│       ├── orb_widget.dart                ← 3D animated orb
│       └── status_cards.dart              ← Battery/CPU/brightness cards
├── android/
│   └── app/
│       ├── src/main/AndroidManifest.xml   ← App permissions
│       └── build.gradle                   ← Android build config
└── pubspec.yaml                           ← Flutter dependencies
```

---

## 🌐 STEP 1: Use FlutLab.io (Free Cloud IDE)

### Why FlutLab?
- 100% free cloud Flutter IDE
- Works in your browser — no powerful laptop needed
- Can build and download APK directly

### Setup:
1. Go to → **https://flutlab.io**
2. Click **Sign Up** (free account)
3. Click **New Project** → **Empty Flutter Project**
4. Name it: `jarvis_ai`

---

## 📋 STEP 2: Copy All Files

In FlutLab's file explorer on the left:

1. **Replace `pubspec.yaml`** → paste the pubspec.yaml content
2. **Replace `lib/main.dart`** → paste main.dart content
3. **Create folders** in lib/:
   - `lib/screens/`
   - `lib/services/`
   - `lib/widgets/`
4. **Create each file** and paste the code:
   - `lib/screens/home_screen.dart`
   - `lib/screens/settings_screen.dart`
   - `lib/services/background_service.dart`
   - `lib/services/command_processor.dart`
   - `lib/services/app_launcher_service.dart`
   - `lib/widgets/orb_widget.dart`
   - `lib/widgets/status_cards.dart`
5. **Replace** `android/app/src/main/AndroidManifest.xml`
6. **Replace** `android/app/build.gradle`

---

## 📦 STEP 3: Build the APK on FlutLab

1. In FlutLab, click the **⚙️ Build** button (top right)
2. Select **Android APK (Release)**
3. Wait ~5-10 minutes for the build
4. Click **Download APK** when done

---

## 📱 STEP 4: Install on Your Android 15 Phone

### Method 1: Direct download
1. Download the APK to your phone
2. Go to **Settings → Security → Install Unknown Apps**
3. Allow your browser/file manager
4. Open the APK file → **Install**

### Method 2: Via USB
1. Download APK to your PC
2. Connect phone via USB
3. Copy APK to phone storage
4. Open from file manager → Install

---

## 🔧 ALTERNATIVE: GitHub Actions (Build for FREE online)

If FlutLab build fails, use this GitHub method:

### 1. Create GitHub account → New Repository → Upload all files

### 2. Create `.github/workflows/build.yml`:

```yaml
name: Build Flutter APK
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: jarvis-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

### 3. Push code → GitHub Actions builds it automatically
### 4. Download APK from **Actions → Artifacts**

---

## 🎤 VOICE COMMANDS (FULL LIST)

| Command | Action |
|---------|--------|
| "Open WhatsApp" | Opens WhatsApp |
| "Open Instagram" | Opens Instagram |
| "Open YouTube" | Opens YouTube |
| "Open Gmail" | Opens Gmail |
| "Open Maps" | Opens Google Maps |
| "Open Chrome" | Opens Chrome browser |
| "Open Calculator" | Opens Calculator |
| "Open Camera" | Opens Camera |
| "Open Settings" | Opens Settings |
| "Open GPay" | Opens Google Pay |
| "Open Flipkart" | Opens Flipkart |
| "Open Play Store" | Opens Play Store |
| "Open ChatGPT" | Opens ChatGPT |
| "Open IRCTC / Rail" | Opens RailOne |
| "Open Airtel" | Opens Airtel |
| "What time is it?" | Tells the time |
| "What's today's date?" | Tells the date |
| "Take a screenshot" | Captures screen |
| "Increase brightness" | Raises brightness |
| "Decrease brightness" | Lowers brightness |
| "Volume up" | Increases volume |
| "Volume down" | Decreases volume |
| "Mute" | Silences phone |
| "Battery level" | Tells battery % |
| "Play music" | Starts music |
| "Pause music" | Pauses music |
| "Tell me a joke" | Tells a joke |
| "Hello / Hi" | JARVIS greets you |
| "How are you?" | Status check |

---

## ⚙️ FEATURES SUMMARY

| Feature | Status |
|---------|--------|
| 🎙️ Voice commands (offline) | ✅ Android built-in STT |
| 🔊 Female voice replies | ✅ Flutter TTS |
| 🔔 Background notification | ✅ Foreground service |
| 💾 Remember assistant name | ✅ SharedPreferences |
| 🔋 Battery display | ✅ battery_plus |
| 💡 Brightness control | ✅ screen_brightness |
| 🔊 Volume control | ✅ volume_controller |
| 📱 Open 20+ apps | ✅ android_intent_plus |
| 📸 Screenshot button | ✅ screenshot package |
| 🌑 Dark sky/blue UI | ✅ Custom design |
| 🔵 3D animated orb | ✅ Custom painter |
| ⭐ Twinkling star BG | ✅ Custom painter |
| 📴 Offline (no API) | ✅ 100% offline |

---

## 🛠️ TROUBLESHOOTING

**Build fails with "minSdk" error?**
→ In `android/app/build.gradle`, change `minSdk 26` to `minSdk 21`

**Speech recognition not working?**
→ The first time, it will ask for microphone permission — allow it!

**App crashes on startup?**
→ Make sure all permissions in AndroidManifest.xml are present

**Can't install APK?**
→ Go to Settings → Apps → Special App Access → Install Unknown Apps → Allow your file manager

**Background service not showing?**
→ Tap the green "OFFLINE" button in the top left of the app to start it

---

## 📌 IMPORTANT NOTES

1. **Internet only needed for**: Opening web apps (YouTube, WhatsApp etc.)
   The AI itself is 100% offline.

2. **The name you set in Settings is permanent** — stored locally on your phone forever.

3. **Background service** = tap "OFFLINE" button → turns GREEN = JARVIS runs in notification bar even when app is closed.

4. **Android 15** may ask for extra permissions — allow all of them for full functionality.

---

*Built with Flutter • 100% Free • 100% Offline AI*
