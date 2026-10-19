# Worm Snake Game V2 🐛🎮

Worms Zone style arena game - Flutter APK ONLY, no website.

## V2 Features
- Slower normal speed, baby-tiny player start, grows with food
- 500 fruits, 30 coins, rich death drops
- Anti-circle bot AI + 4 mega bots (King, Titan, Legend, Boss)
- 5000x5000 arena, real snake style (stripes, eyes, tongue)
- Wardrobe: 8 skins + Snake Shop (4 premium) + 8 faces + My Photo (gallery pic as round head)
- Google login + Guest mode, Settings, Admin Panel (admin Gmail only)
- Admin Panel: give/take coins, ban/unban, game config, new skins, announcements - no APK update needed

## Firebase Setup (one time)
1. Firebase Console -> open your existing project (or create new)
2. Add Android app with package name `com.murad.worm_snake_game`
3. Download `google-services.json` -> put at REPO ROOT (next to pubspec.yaml)
4. Authentication -> Sign-in method -> Enable Google
5. Firestore Database -> Create database -> paste `firestore.rules` -> Publish

## Build (GitHub Actions - free, no PC)
1. Create NEW public GitHub repo `worm-snake-game-v2`
2. Upload ALL files to repo ROOT (pubspec.yaml at root, lib/ folder, .github/workflows/build-apk.yml)
3. Push -> Actions tab -> Build Worm Snake V2 APK -> wait 5-10 min (green tick)
4. Download `worm-snake-v2-apk` artifact -> install on phone as UPDATE (do NOT uninstall)

Without google-services.json the app shows "Setup Needed" instead of crashing.
