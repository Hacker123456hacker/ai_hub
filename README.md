# AI Hub — Phase 1

Chat UI + OpenRouter integration + API key settings + Hive local storage +
model selection. Material 3, dark purple theme, light/dark mode.

## What's in this phase

- `lib/main.dart` — entry point, Hive init, theme wiring
- `lib/features/splash` — splash screen
- `lib/features/chat` — home (chat list), chat screen, message bubbles,
  input bar, model picker
- `lib/features/settings` — API key entry/validation, theme toggle,
  temperature/max-tokens
- `lib/core/services/openrouter_service.dart` — streaming chat completions
  + key validation against OpenRouter's REST API
- `lib/data` — Hive models (`ChatMessage`, `ChatSession`), repository,
  secure storage for the API key

## One-time setup in Termux

You need the Flutter SDK and Android SDK command-line tools installed in
Termux first (outside the scope of this project's files). If you haven't
done that yet:

```bash
pkg install git unzip openjdk-17 -y
# install Flutter SDK per Flutter's Linux instructions, then:
flutter doctor
```

`flutter doctor` will tell you if the Android SDK / licenses still need
attention — resolve those before continuing.

## Building this project

```bash
cd ai_hub

# 1. Fetch packages
flutter pub get

# 2. Regenerate Hive adapters (the .g.dart files in this repo were
#    hand-written since build_runner couldn't run in the generation
#    environment — this step confirms/repairs them against your actual
#    Hive/Flutter versions)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Confirm a connected device or emulator is visible
flutter devices

# 4. Run in debug mode
flutter run

# 5. Or build a release APK directly
flutter build apk --debug
# (use --release once you've set up a real signing config — see note below)
```

## Known gaps you must fill before `flutter run` works

1. **`android/local.properties`** — placeholder paths are committed for
   reference but almost certainly don't match your machine. Either delete
   the file and run `flutter pub get` (Flutter regenerates it), or edit
   `sdk.dir` / `flutter.sdk` to your real paths.
2. **`android/gradle/wrapper/gradle-wrapper.jar`** — this is a binary file
   that could not be generated as part of this text-based build. Run this
   once from the project root to fetch it automatically:
   ```bash
   cd android && gradle wrapper --gradle-version 8.6 && cd ..
   ```
   (requires a system `gradle` install just for this one bootstrap step —
   `pkg install gradle` in Termux). After this runs once, `./gradlew` works
   standalone from then on and you don't need system Gradle again.
3. **Release signing** — `buildTypes.release` currently falls back to the
   debug signing config so `flutter build apk --release` doesn't fail, but
   this is NOT suitable for distribution. Phase 2+ should add a real
   `key.properties` + signing config.

## Using the app

1. Launch the app → Settings → paste an OpenRouter API key
   (get one free at https://openrouter.ai/keys) → **Verify & Save**.
2. Go back, tap **New Chat**, tap the model name in the app bar to switch
   models, and start chatting. Responses stream in token-by-token.
3. Chats persist locally via Hive — closing and reopening the app keeps
   your history.

## Not included in Phase 1 (by design)

Document AI, Image AI, voice features, offline/local models, other
providers (Gemini/Claude/Grok/DeepSeek direct, Mistral), memory system,
cloud backup, plugins. These are future phases.
