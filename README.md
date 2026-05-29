# ክርስቶስር ክኒ ግናቲትድ — Blin Prayer App

A complete offline **Flutter** app of Blin (ብሊን) prayers, hymns, and catechism in
Ge'ez script, for the faithful of the **Catholic Eparchy of Keren**.

- 📖 **7 prayer sections** — daily prayers, the Creed & Acts, Confession & Communion,
  the Rosary & Litany, the Divine Mercy Chaplet, the Way of the Cross, and Grace at meals
- ✝️ **Catechism** — 10 topics, 55 question-and-answer pairs (for First Communion)
- 🎓 **Quiz mode** — shuffle-able flashcards, all topics or one at a time
- 🎵 **42 Blin hymns**
- ⭐ Favorites, full-text search, adjustable text size, all **fully offline**
- 🌐 English **context notes** on every section/topic (toggle on/off in Settings),
  plus empty `translation` fields you can fill in later with verified translations

---

## What's in this folder

```
blin_prayers/
├── pubspec.yaml            # dependencies & asset registration
├── analysis_options.yaml
├── assets/
│   └── data.json           # ALL content (prayers, hymns, catechism, quiz)
└── lib/
    ├── main.dart           # app entry, navigation, home/search/favorites/settings
    ├── data.dart           # data models + JSON loader
    ├── store.dart          # favorites / text-size / notes toggle (persisted)
    ├── theme.dart          # colors + Ge'ez fonts (Noto Serif/Sans Ethiopic)
    ├── widgets.dart        # shared UI (rows, cards, formatted prayer text)
    ├── reader_screen.dart  # reading view
    └── quiz_screen.dart    # catechism quiz
```

> The `android/` and `ios/` folders are **not** included — you generate them in one
> step below with `flutter create`. This guarantees they match your installed
> Flutter version (hand-written Gradle files break across versions).

---

## Part 1 — Install Flutter (one time)

1. Install Flutter: https://docs.flutter.dev/get-started/install — pick your OS and follow it.
2. Install **Android Studio** (it bundles the Android SDK). Open it once and let it
   finish downloading the SDK + command-line tools.
3. Verify everything is ready:
   ```bash
   flutter doctor
   ```
   Fix anything it flags with a ✗ (accept Android licenses with
   `flutter doctor --android-licenses`).

---

## Part 2 — Set up this project

From inside the `blin_prayers` folder:

```bash
# 1. Generate the platform folders (android/, ios/) for YOUR Flutter version,
#    with the correct package name. This will NOT overwrite lib/ or assets/.
flutter create . --org com.kereneparchy --project-name blin_prayers

# 2. Download dependencies
flutter pub get

# 3. Run it on a connected phone or emulator to check it works
flutter run
```

If `flutter create` ever asks about overwriting files, it only touches platform
scaffolding — your `lib/`, `assets/`, and `pubspec.yaml` are safe.

> **Package name (Application ID).** The command above sets it to
> `com.kereneparchy.blin_prayers`. To use something else, change `--org` /
> `--project-name`, or after creating, edit `android/app/build.gradle` →
> `applicationId`. **Once you publish, the package name can never change**, so
> pick it deliberately.

---

## Part 3 — App name & icon

**App display name** (what shows under the icon on the phone):
edit `android/app/src/main/AndroidManifest.xml`, find `android:label` and set it,
e.g. `android:label="ግናቲትድ"` (or "Blin Prayers" — your choice).

**App icon:** the easiest path is the `flutter_launcher_icons` package.
1. Put a 1024×1024 PNG at `assets/icon.png`.
2. Add to `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/icon.png"
     adaptive_icon_background: "#7A1F2B"
     adaptive_icon_foreground: "assets/icon.png"
   ```
3. Run:
   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```

---

## Part 4 — Build a release for the Play Store

Google Play requires a signed **App Bundle** (`.aab`).

### 4a. Create a signing key (one time)
```bash
keytool -genkey -v -keystore ~/blin-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Keep this `.jks` file and its passwords **safe and backed up** — losing it means you
can't update the app again.

### 4b. Tell Gradle about the key
Create `android/key.properties` (do **not** commit it — it's already git-ignored):
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/blin-upload-key.jks
```

Then edit `android/app/build.gradle`:
```gradle
// near the top, before android { }
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 4c. Build
```bash
flutter build appbundle --release
```
The bundle is created at:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## Part 5 — Publish on Google Play

1. Create a **Google Play Developer account** ($25 one-time): https://play.google.com/console
2. **Create app** → fill in name, language, "App" / "Free".
3. Complete the required questionnaires (content rating, target audience,
   data safety — this app collects **no** data and works offline, which makes these short).
4. **Production → Create new release** → upload `app-release.aab`.
5. Add a short description, screenshots (take them with `flutter run` on a phone),
   and a 512×512 icon + feature graphic.
6. Submit for review. First review can take a few days.

**Version bumps for later updates:** edit `version:` in `pubspec.yaml`
(e.g. `1.0.1+2` — the `+2` is the build number, which must increase every upload),
then rebuild the `.aab`.

---

## Updating the content

All text lives in **`assets/data.json`**. To fix a typo or add a translation,
edit that file and rebuild — no Dart changes needed.

- **English translations:** every prayer/hymn has a `"translation": ""` field, and
  every catechism Q&A has `"q_en": ""` / `"a_en": ""`. Fill these with verified
  translations and they'll appear automatically (toggle "English notes" in Settings).
- The `"note"` fields hold the short English context descriptions.

---

## Notes on the source material

The content was extracted from three community files:
- a Blin **hymns** text (42 hymns + opening prayers),
- **ግናቲትድ ኒኰስዲክ** ("አውኒ መሀድዅንና") — the catechism + mass prayer book (38 scanned pages),
- **መስቀል ደርብ** — the Way of the Cross devotional (25 scanned pages).

The hymn book was hand-formatted, so a few hymn boundaries may need minor review;
all text is preserved and searchable. Verify against the originals before publishing.
