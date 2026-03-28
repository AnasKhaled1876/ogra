# 2ogra (أجرة)

> An offline-first, one-handed fare collection app for Egyptian microbus conductors — built in public, deployed automatically, and open for contribution.

---

## What is 2ogra?

Microbuses move **~8.1 million passengers a day** across Greater Cairo. Every single trip involves a cash fare transaction — usually done standing up, one-handed, in a noisy moving vehicle. The conductor has to mentally compute fares for multiple riders, figure out change from a 100-pound note, and do it all in under 3 seconds.

**2ogra (أجرة — the Arabic word for "fare")** is a mobile app that makes that calculation instant, accurate, and fair.

Core features:

- **Smart Change Engine** — given a fare, rider count, and payment denomination, instantly suggests the optimal change breakdown
- **Pocket Mode** — tracks the conductor's actual cash inventory so it only suggests change that can actually be made
- **Offline-first** — works with zero network, zero account, zero friction
- **One-handed UI** — all primary actions in the bottom half of the screen, no typing required
- **Batch settlement** — handles multiple passengers paying simultaneously with a single tap flow
- **Rounding policy** — opt-in, transparent, and always disclosed to passengers

---

## The Problem in Numbers

| Stat | Source |
| --- | --- |
| ~63% of daily trips >500m in Greater Cairo use microbuses | World Bank mobility report |
| 11–14 seats per vehicle, high-frequency boarding | Transport for Cairo route survey |
| Common fares: EGP 14–22 depending on route and AC | Cairo governorate 2024–2025 announcements |
| Common payment: two fares from a 100-pound note | Egyptian Arabic usage guides |
| Change shortage is a documented daily source of disputes | Field research |

---

## Architecture Overview

```text
┌─────────────────────────────────────────────────────────┐
│                      Flutter UI                         │
│   Collect Screen · Pocket Screen · Presets · Reports    │
└─────────────────┬───────────────────────────────────────┘
                  │ Riverpod Notifiers
┌─────────────────▼───────────────────────────────────────┐
│              Application Layer                          │
│   CollectController · PocketController · SettingsCtrl   │
└─────────────────┬───────────────────────────────────────┘
                  │ pure Dart, no side-effects
┌─────────────────▼───────────────────────────────────────┐
│              Domain — Change Distribution Engine        │
│   ChangeEngine · BatchAllocator · Scoring · Models      │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│                   Data Layer                            │
│   Hive (local)  ·  Optional Firebase (consent-gated)   │
└─────────────────────────────────────────────────────────┘
```

**Design constraints:**

- Engine is pure Dart — no Flutter, no Firebase, fully unit-testable
- Firebase is **never initialized** until the user explicitly grants consent
- All monetary values are integers in minor units (50 = 0.50 EGP)
- Target: **< 1 second** computation end-to-end on mid-range Android

### Money Representation

The denomination set uses half-pound precision:

```text
[200 EGP, 100 EGP, 50 EGP, 20 EGP, 10 EGP, 5 EGP, 0.50 EGP]
 → stored as [20000, 10000, 5000, 2000, 1000, 500, 50]  (minor units, GCD = 50)
```

### Engine Modes

| Mode | When | Algorithm | Complexity |
| --- | --- | --- | --- |
| Fast / Greedy | Immediate UI feedback | Greedy bounded | O(D) |
| Smart / DP | Best single-passenger plan | Bounded DP with scoring | O(D × T) |
| Batch / Search | Multi-passenger settlement | DFS with top-K pruning + time budget | O(K^N) bounded |
| Fallback Greedy | Batch timeout | Sequential greedy | O(N × D) |

The scoring function penalizes small-denomination use and depletion to preserve future feasibility — configurable via `EngineConfig` and `ScoreWeights`.

### Key Engine Semantics

```text
1. Snapshot pocket P0
2. Add ALL incoming payments → P1   ← critical for batch mode
3. Allocate change plans using P1
4. Preview in UI (never mutate until confirmed)
5. On confirm: commit P2 = P1 - change_given + transaction record (atomic)
```

---

## Project Structure

```text
lib/
  engine/                     ← pure Dart, no Flutter imports
    models.dart               ← all data models
    scoring.dart              ← ScoreWeights + scorePlan()
    change_engine.dart        ← single-passenger solver
    batch_allocator.dart      ← multi-passenger optimizer
    engine_facade.dart        ← public API
    riverpod_providers.dart   ← DI wiring
  features/
    collect/                  ← main transaction screen
    pocket/                   ← cash inventory management
    presets/                  ← route/fare presets
    reports/                  ← daily rollups
    settings/                 ← app config + consent
  src/
    bootstrap/                ← app init + Firebase consent gate
    core/                     ← analytics, crash reporting, crypto, IDs

fastlane/
  Fastfile                    ← lanes: a_rel, i_rel, meta_sync, shots_opt
  Matchfile                   ← iOS code signing via Match
  gen_release_notes           ← auto-generates changelogs from git history
  metadata/
    android/en-US/            ← Play Store copy
    android/ar-EG/            ← Arabic Play Store copy
    ios/en-US/                ← App Store copy
    ios/ar-EG/                ← Arabic App Store copy

.github/workflows/
  ci.yml                      ← runs on every push/PR to main
  deploy-android.yml          ← triggers on v* tags
  deploy-ios.yml              ← triggers on v* tags
```

---

## CI/CD Pipeline

This project uses a **fully automated, tag-driven deployment pipeline**. Here is exactly what happens when you push a version tag:

```bash
git tag v1.2.0+5
git push origin v1.2.0+5
```

### What triggers automatically

```text
Tag pushed
    │
    ├─► deploy-android.yml (ubuntu-latest)
    │       analyze → test → validate secrets
    │       → decode keystore → build AAB
    │       → verify signature (jarsigner)
    │       → gen_release_notes
    │       → fastlane android a_rel
    │           └─► supply → Google Play production
    │
    └─► deploy-ios.yml (macos-latest)
            analyze → test → validate secrets
            → pod install → decode ASC API key
            → fastlane ios prepare_ios_signing
            │   └─► match (readonly) + update_code_signing_settings
            → flutter build ipa
            → fastlane ios i_rel
                └─► deliver → App Store Connect
```

### Release notes are generated automatically

On every merge to `main`, `gen_release_notes` runs and:

1. Collects commit titles since the last git tag
2. Translates contributor mentions (`@username`) into a "Thanks" line
3. Writes changelogs in **English and Arabic (ar-EG)** to both Play Store and App Store metadata paths

You never write release notes manually.

### Environments and secrets

The deployment workflows are gated behind GitHub Environments:

**`android-production`** requires:

| Secret | What it is |
| --- | --- |
| `ANDROID_SERVICE_ACCOUNT_JSON` | Google Play API service account JSON |
| `KEYSTORE_BASE64` | Base64-encoded `.jks` upload keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias (e.g. `upload`) |
| `KEY_PASSWORD` | Key password |
| `SLACK_WEBHOOK` | (optional) Slack notifications |

**`ios-production`** requires:

| Secret | What it is |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY_ID` | ASC API key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | ASC issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded `.p8` private key |
| `MATCH_GIT_URL` | Git repo URL storing Match certificates |
| `MATCH_PASSWORD` | Encryption password for Match repo |
| `IOS_EXPORT_METHOD` | `app-store` |
| `SLACK_WEBHOOK` | (optional) Slack notifications |

### Rollback procedure

**Android:** In Play Console → Production → promote the previous release, or use `supply` with the previous AAB.

**iOS:** In App Store Connect → reject the pending submission → resubmit the previous build.

---

## Contributing

This is an **open contribution project** — the goal is to build something real and useful with the community.

### Ground rules

1. **The engine stays pure.** `lib/engine/` must have zero Flutter or Firebase imports. All logic is unit-testable without a device.
2. **No rounding by default.** `EngineConfig.roundingEnabled` defaults to `false`. Any change to rounding behavior must be explicitly opt-in and shown to the user.
3. **Offline first, always.** Every core feature must work without a network connection. Firebase is an optional add-on, never a dependency.
4. **Integer money only.** No `double` for monetary values anywhere. Use minor units (×100 for EGP precision, ×50 for half-pound).
5. **Arabic matters.** UI strings, release notes, and user-facing messages should have both English and Arabic (ar-EG) versions.

### How to contribute

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/ogra.git
cd ogra

# 2. Install dependencies
flutter pub get

# 3. Run tests
flutter test

# 4. Run the analyzer
flutter analyze

# 5. Create a feature branch
git checkout -b feat/your-feature-name

# 6. Open a PR against main
```

Your PR will automatically go through CI (analyze + test) on every push.

### What we need help with

- [ ] **Collect screen UI** — fare strip, riders selector, denomination pad, result panel
- [ ] **Pocket screen UI** — denomination list with +/- controls and shift-start presets
- [ ] **Preset system** — one-tap "اتنين من 100" style shortcuts
- [ ] **Hive persistence** — wiring `PocketInventory` and transactions to local storage
- [ ] **Engine tests** — property-based tests for the change engine invariants
- [ ] **Arabic localization** — l10n for all UI strings
- [ ] **Reports screen** — daily totals, infeasible count, rounding delta
- [ ] **Voice Mode** (later) — Egyptian Arabic STT for "اتنين من مية"

### Contributor recognition

Your GitHub handle appears automatically in the release notes on the next tagged release. Every merged PR gets a "Thanks @you" line in the Arabic and English changelogs shipped to Google Play and the App Store.

---

## Running Locally

**Requirements:**

- Flutter stable channel (`flutter --version`)
- Dart SDK `^3.11.0`
- For iOS: Xcode + CocoaPods (`pod --version`)
- For Android: Java 17

```bash
# Run on a connected device or emulator (production flavor)
flutter run --flavor production -t lib/main_production.dart

# Run tests
flutter test

# Analyze
flutter analyze
```

**Local Android signing (for release builds):**

Create `android/key.properties` (never committed — already in `.gitignore`):

```properties
KEYSTORE_PATH=/absolute/path/to/your.jks
KEYSTORE_PASSWORD=your_password
KEY_ALIAS=upload
KEY_PASSWORD=your_password
```

Then:

```bash
flutter build appbundle --release --flavor production -t lib/main_production.dart
```

---

## Tech Stack

| Layer | Choice | Why |
| --- | --- | --- |
| UI | Flutter stable | Cross-platform, one-handed UI, 60fps |
| State | Riverpod (Notifier-based) | Testable DI, clean provider boundaries |
| Local storage | Hive | Fast KV, small objects, offline-first |
| Engine | Pure Dart | Zero dependencies, fully unit-testable |
| CI/CD | GitHub Actions + Fastlane | Tag-driven, automated, contributor-aware release notes |
| iOS signing | Fastlane Match | Shared certs via encrypted git repo |
| Android signing | Upload keystore + Play App Signing | Standard Play Store flow |
| Optional cloud | Firebase (consent-gated) | Analytics, Crashlytics, encrypted backups |
| Font | Cairo (Google Fonts) | Arabic + Latin, full weight range |

---

## Roadmap

| Phase | Scope |
| --- | --- |
| **MVP** | Collect screen · Pocket Mode · Presets · Basic reports · Local-only |
| **v1** | Consent screen · Opt-in Analytics + Crashlytics · CI flavors |
| **v1.1** | Encrypted backup via Firestore · Restore flow · Key management |
| **Later** | Voice Mode (ar-EG STT) · App Check · Fleet/B2B features |

---

## License

MIT — build on it, fork it, deploy it. If you improve it, send a PR.

---

> Built for the microbus conductor. Dedicated to everyone who has ever asked for their change back.
