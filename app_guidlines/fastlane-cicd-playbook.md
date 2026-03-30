# Fastlane + GitHub Actions Deployment Playbook

This document is a reusable implementation guide for another AI agent that needs to set up the same style of Fastlane + GitHub Actions CI/CD pipeline for a different Flutter app.

It is based on the deployment strategy implemented in this repo and, more importantly, on the problems we actually ran into while getting it working.

Use this as an execution brief, not as a vague reference.

---

## 1. Goal

Set up a production-ready deployment pipeline for a Flutter app that:

- builds Android and iOS release artifacts in GitHub Actions
- signs Android with a keystore
- signs iOS with Fastlane `match`
- uploads Android with Fastlane `supply`
- uploads iOS with Fastlane `deliver`
- generates release notes and store metadata automatically
- avoids the common signing / App Store / Play Console / workflow mistakes listed below

If the user does **not explicitly need beta/staging flavors**, default to **production-only**. This keeps the pipeline simpler and avoids extra store records, bundle IDs, provisioning profiles, and workflow branches.

---

## 2. Default Architecture

Use this structure unless the target app has a strong reason to differ:

### Root files

- `Gemfile`
- `.ruby-version`
- `CI_README.md`

### Fastlane

- `fastlane/Appfile`
- `fastlane/Fastfile`
- `fastlane/Matchfile`
- `fastlane/gen_release_notes`
- `fastlane/metadata/android/...`
- `fastlane/metadata/ios/...`

### GitHub Actions

- `.github/workflows/ci.yml`
- `.github/workflows/deploy-android.yml`
- `.github/workflows/deploy-ios.yml`

### Flutter entrypoints

If production-only:

- `lib/main.dart` or `lib/main_production.dart`

If flavors are explicitly required:

- `lib/main_beta.dart`
- `lib/main_production.dart`

---

## 3. Production-Only Recommendation

Unless the user explicitly asks for `beta`, do **not** scaffold it.

Why:

- Android package IDs multiply
- iOS bundle IDs multiply
- App Store Connect app records multiply
- provisioning profiles multiply
- the user may not actually have a beta app configured
- most breakage comes from over-scaffolding before the store configuration exists

Recommended default:

- Android application ID: real production ID only
- iOS bundle identifier: real production ID only
- one Android lane: `a_rel`
- one iOS lane: `i_rel`
- one Android deploy workflow
- one iOS deploy workflow

---

## 4. Inputs the AI Must Confirm Before Coding

Before editing anything, confirm these values or discover them from the repo/user:

- production Android application ID
- production iOS bundle identifier
- whether beta/staging is actually needed
- whether the app already exists in Google Play Console
- whether the app already exists in App Store Connect
- whether iOS signing should use `match`
- whether the team already has a private `match` repo

If the user does not know, do not invent fake production IDs in the final state.

---

## 5. Android Setup

## 5.1 Build config

For Android production releases:

- ensure the `applicationId` matches the Play Console app exactly
- wire release signing to environment-provided keystore values
- ensure the release `.aab` path is stable and predictable

Use Gradle env-driven signing values instead of committing secrets.

## 5.2 Required Android secrets

GitHub repo or environment secrets:

- `ANDROID_SERVICE_ACCOUNT_JSON`
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

Optional:

- `FIREBASE_TOKEN`
- `SLACK_WEBHOOK`

## 5.3 Android workflow requirements

The Android deploy workflow should:

1. checkout
2. set up Flutter
3. set up Java 17
4. set up Ruby
5. run `flutter pub get`
6. run `flutter analyze`
7. run `flutter test`
8. validate secrets explicitly
9. decode Play service account JSON
10. decode keystore
11. compute a unique CI build number
12. build `.aab`
13. verify signing
14. generate release notes
15. run `bundle exec fastlane android a_rel`
16. upload artifacts

---

## 6. iOS Setup

## 6.1 Signing model

Use Fastlane `match` by default for CI signing.

That means:

- one private git repo containing encrypted certificates and provisioning profiles
- `MATCH_GIT_URL`
- `MATCH_PASSWORD`
- App Store Connect API key auth

## 6.2 Required iOS secrets

GitHub repo or environment secrets:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64`
- `MATCH_GIT_URL`
- `MATCH_PASSWORD`

Optional:

- `IOS_EXPORT_METHOD`
- `FIREBASE_TOKEN`
- `SLACK_WEBHOOK`

## 6.3 Required iOS workflow requirements

The iOS deploy workflow should:

1. checkout
2. set up Flutter
3. set up Ruby
4. set up Java 17 if shared tooling expects it
5. run `flutter pub get`
6. run `flutter analyze`
7. run `flutter test`
8. validate secrets explicitly
9. decode App Store Connect `.p8` key to a temp file
10. compute a unique CI build number
11. run `bundle exec fastlane ios prepare_ios_signing`
12. build IPA with explicit `--build-number`
13. verify archive/signing
14. generate release notes
15. run `bundle exec fastlane ios i_rel`
16. upload IPA/archive/metadata artifacts

---

## 7. Versioning Strategy

Keep two concepts separate:

- marketing version: user-facing version, e.g. `1.0.0`
- build number: internal monotonically increasing integer, e.g. `1001`

Do **not** rely on the static build number from `pubspec.yaml` for CI uploads.

Why:

- App Store Connect rejects duplicate build numbers
- rerunning the same workflow can reuse the same `+N`
- Google Play also requires a monotonically increasing version code

### Recommended CI build-number strategy

Compute a unique build number from GitHub Actions:

```bash
BUILD_NUMBER=$((GITHUB_RUN_NUMBER * 100 + GITHUB_RUN_ATTEMPT))
```

Then export it:

```bash
echo "APP_BUILD_NUMBER=$BUILD_NUMBER" >> "$GITHUB_ENV"
```

And pass it to Flutter:

```bash
flutter build ipa ... --build-number "$APP_BUILD_NUMBER"
flutter build appbundle ... --build-number "$APP_BUILD_NUMBER"
```

Also make Fastlane honor this override in helper methods so internal fallback builds stay consistent.

---

## 8. Fastlane Design

## 8.1 Recommended lanes

Production-only:

- `android a_rel`
- `ios prepare_ios_signing`
- `ios i_rel`
- `meta_sync`
- `shots_opt`

## 8.2 Fastlane responsibilities

Fastlane should be responsible for:

- store authentication
- iOS signing via `match`
- release note generation trigger
- metadata upload
- final store upload

GitHub Actions should be responsible for:

- environment setup
- secret decoding
- build-number calculation
- calling Fastlane

Keep those boundaries clean.

---

## 9. Release Notes / Metadata Strategy

Recommended behavior:

- generate metadata from git history since the previous tag
- group changes by contributor
- strip commit prefixes like `fix:` / `feat:` / `chore:`
- generate:
  - Android changelogs
  - iOS `whats_new`
  - optional store descriptions with contributor appendix

### Locale warning

Do not assume Android and iOS support the same locale folder names.

Example we hit:

- Android accepted `ar-EG`
- App Store Connect rejected `ar-EG`
- iOS needed `ar-SA`

Rule:

- verify iOS metadata locale names against App Store Connect accepted locale codes

---

## 10. Pitfall Ledger: Exact Problems We Hit and How To Avoid Them

This section is the most important part of this document.

### 10.1 Missing Ruby version in GitHub Actions

Problem:

- `ruby/setup-ruby` failed because no `.ruby-version` or explicit `ruby-version` was set

Fix:

- add `.ruby-version`
- also set `ruby-version: "3.2"` explicitly in workflows

### 10.2 CocoaPods failed inside `bundle exec fastlane`

Problem:

- `pod install` inside Fastlane inherited Bundler’s gem environment and crashed

Fix:

- in `Fastfile`, run `pod install` inside:

```ruby
Bundler.with_unbundled_env do
  sh("cd ... && pod install --project-directory=ios")
end
```

### 10.3 Google Play API disabled

Problem:

- `PERMISSION_DENIED` because Google Play Android Developer API was not enabled in the linked Google Cloud project

Fix:

- enable `androidpublisher.googleapis.com` in the exact Cloud project connected to Play Console

### 10.4 Google Play package not found

Problem:

- Fastlane `supply` reached Google Play, but the app package did not exist in Play Console

Fix:

- create the Play Console app first
- ensure the package name in Gradle exactly matches the store record

### 10.5 App Store Connect API key missing locally

Problem:

- local Fastlane runs failed because GitHub secrets do not exist in the local shell

Fix:

- export these locally before running Fastlane:
  - `APP_STORE_CONNECT_API_KEY_ID`
  - `APP_STORE_CONNECT_API_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_PATH` or `APP_STORE_CONNECT_API_KEY_BASE64`

### 10.6 `match` repo exists but CI cannot clone it

Problem:

- private `match` repo URL was present, but GitHub Actions had no auth for cloning it

Fix:

- use an authenticated `MATCH_GIT_URL`, or explicitly configure CI access for the private repo

Do not assume the normal repo checkout grants access to a separate private signing repo.

### 10.7 Duplicate iOS build numbers

Problem:

- App Store Connect rejected upload because build number `2` had already been used

Fix:

- generate build numbers in CI
- do not rely on static `pubspec.yaml +N`

### 10.8 `deliver` precheck failed with App Store Connect API key

Problem:

- Fastlane precheck tried to validate in-app purchases while using API-key auth

Fix:

- set:

```ruby
precheck_include_in_app_purchases: false
```

### 10.9 `deliver` conflict: `api_key` and `api_key_path`

Problem:

- `deliver` received explicit `api_key`, but environment still exposed `APP_STORE_CONNECT_API_KEY_PATH`
- precheck later failed with:
  - `Unresolved conflict between options: 'api_key' and 'api_key_path'`

Fix:

- temporarily clear `APP_STORE_CONNECT_API_KEY_PATH` only around the `deliver` call

Pattern:

```ruby
def without_app_store_connect_api_key_path
  original = ENV.delete("APP_STORE_CONNECT_API_KEY_PATH")
  yield
ensure
  ENV["APP_STORE_CONNECT_API_KEY_PATH"] = original unless original.nil?
end
```

Wrap `deliver` in that helper.

### 10.10 App Store locale folder rejected

Problem:

- `deliver` rejected `fastlane/metadata/ios/ar-EG`

Fix:

- use a valid iOS App Store locale, e.g. `ar-SA`

### 10.11 First App Store version may fail in metadata/review flow

Problem:

- initial App Store submission may hit Fastlane/API oddities on the very first version

Fix:

- be ready to complete first-version review metadata manually in App Store Connect if needed
- after the first version is established, automation becomes more reliable

Do not assume the first App Store submission is the same as later updates.

### 10.12 Large iOS app icon rejected because of alpha

Problem:

- App Store Connect rejected the 1024 icon because it contained an alpha channel

Fix:

- ensure the icon canvas is fully opaque
- ensure the final 1024 marketing icon has **no alpha channel**, not just no visible transparency

If generating icons programmatically, verify the final marketing icon file explicitly.

### 10.13 Placeholder app icons

Problem:

- Flutter/iOS validation warned that the app still used placeholder icons

Fix:

- replace launcher icons before store submission
- do not leave asset generation as “later”

### 10.14 Xcode / SDK submission deadline drift

Problem:

- Apple changes minimum Xcode / SDK requirements over time

Fix:

- never hardcode assumptions that the current Xcode is good enough forever
- check Apple’s official requirements before finalizing the iOS pipeline

As of **March 29, 2026**, Apple’s official “Upcoming Requirements” page says that beginning **April 28, 2026**, apps uploaded to App Store Connect must be built with **Xcode 26 or later** using the **iOS 26 SDK or later**.

Source:

- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/support/xcode/

### 10.15 Do not assume `macos-latest` has the Xcode version you need

Problem:

- GitHub Actions runner image labels can lag or differ from Apple’s latest submission requirement

Fix:

- explicitly verify the runner image / Xcode availability before freezing the workflow
- do not assume `macos-latest` automatically satisfies Apple’s latest SDK rule

---

## 11. GitHub Environments

Use GitHub Environments for production gates.

Recommended names:

- `android-production`
- `ios-production`

Put production secrets there if the user wants tighter control.

At minimum, the workflow job should reference the environment so approvals can be added later.

---

## 12. Minimal Generic Workflow Shape

## 12.1 Android

```yaml
name: Deploy Android

on:
  workflow_dispatch:
  push:
    tags:
      - "v*"

jobs:
  deploy-production:
    runs-on: ubuntu-latest
    environment: android-production
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - uses: actions/setup-java@v4
      - uses: ruby/setup-ruby@v1
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: validate-secrets
      - run: decode-play-json
      - run: decode-keystore
      - run: compute-build-number
      - run: flutter build appbundle --build-number "$APP_BUILD_NUMBER"
      - run: bundle exec fastlane android a_rel
```

## 12.2 iOS

```yaml
name: Deploy iOS

on:
  workflow_dispatch:
  push:
    tags:
      - "v*"

jobs:
  deploy-production:
    runs-on: macos-latest
    environment: ios-production
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - uses: ruby/setup-ruby@v1
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: validate-secrets
      - run: decode-asc-key
      - run: compute-build-number
      - run: bundle exec fastlane ios prepare_ios_signing
      - run: flutter build ipa --build-number "$APP_BUILD_NUMBER"
      - run: bundle exec fastlane ios i_rel
```

This is the shape. The details matter.

---

## 13. What Another AI Should Explicitly Avoid

Do **not**:

- scaffold beta unless the user explicitly needs it
- assume store apps already exist
- assume `match` is configured just because the user added some secrets
- assume GitHub repo secrets exist in the local shell
- assume App Store locale names equal Play locale names
- assume static build numbers are acceptable
- assume `macos-latest` has the Xcode version Apple currently requires
- assume iOS app icons can contain alpha just because they look opaque
- leave `deliver` to infer both `api_key` and `api_key_path`
- run `pod install` inside Bundler without checking for environment conflicts

---

## 14. Recommended Prompt to Give Another AI

Use this when asking another AI to implement the pipeline for a different Flutter app:

```md
Set up a production-only Fastlane + GitHub Actions deployment pipeline for this Flutter app.

Requirements:
- Android deploy with Fastlane `supply`
- iOS deploy with Fastlane `match` + `deliver`
- GitHub Actions workflows for Android and iOS
- explicit secret validation steps
- CI-generated unique build numbers using workflow run number + attempt
- release-note generation from git history
- metadata folders for Android and iOS

Important constraints:
- Do not scaffold beta/staging unless the repo already clearly needs it
- Do not assume store apps already exist; call that out if missing
- Do not rely on static `pubspec.yaml` build numbers in CI
- In Fastlane, exclude IAP precheck when using App Store Connect API key
- Prevent `deliver` from seeing both `api_key` and `APP_STORE_CONNECT_API_KEY_PATH`
- If `pod install` runs from Fastlane, avoid Bundler/CocoaPods environment conflicts
- Use valid iOS App Store locale folder names
- Ensure the iOS 1024 marketing icon has no alpha channel
- Keep GitHub environments for production gates

Deliverables:
- Gemfile
- .ruby-version
- fastlane/Appfile
- fastlane/Fastfile
- fastlane/Matchfile
- fastlane/gen_release_notes
- .github/workflows/ci.yml
- .github/workflows/deploy-android.yml
- .github/workflows/deploy-ios.yml
- CI_README.md

Also document every required secret and every likely failure mode.
```

---

## 15. Final Rule

A deployment pipeline is not done when the YAML exists.

It is done only when:

- the secrets contract is explicit
- local signing assumptions are removed
- the build numbers are monotonic
- Android upload reaches Play Console successfully
- iOS upload reaches App Store Connect successfully
- the known failure modes above are handled up front

That is the standard another AI should meet.
