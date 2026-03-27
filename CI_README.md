# CI / CD for 2ogra

## Workflows
- `ci.yml`: runs on push and PR to `main`; installs Flutter, runs `flutter analyze` and `flutter test`, and generates release-note artifacts on push to `main`.
- `deploy-android.yml`: manual dispatch and automatic production deploy on `vX.Y.Z` tags.
- `deploy-ios.yml`: manual dispatch and automatic production deploy on `vX.Y.Z` tags.

## Required Secrets
### Android
- `ANDROID_SERVICE_ACCOUNT_JSON`
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

### iOS
- `APP_STORE_CONNECT_API_KEY_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `MATCH_PASSWORD`
- `MATCH_GIT_URL`

### Optional
- `IOS_EXPORT_METHOD`
- `FIREBASE_TOKEN`
- `SLACK_WEBHOOK`

## Environment Rules
- Create GitHub environments `android-production` and `ios-production`.
- Production deploys run only from:
  - tag pushes matching `vX.Y.Z`
  - manual workflow dispatch

## Flavor Mapping
- Android `production` -> `com.ogra.app`
- iOS `production` -> `com.ogra.app`

## Release Notes
- `fastlane/gen_release_notes` reads commit titles since the previous tag.
- It writes bilingual notes and store descriptions to:
  - `fastlane/metadata/android/en-US/changelogs/<version>.txt`
  - `fastlane/metadata/android/ar-EG/changelogs/<version>.txt`
  - `fastlane/metadata/android/en-US/full_description.txt`
  - `fastlane/metadata/android/ar-EG/full_description.txt`
  - `fastlane/metadata/ios/en-US/whats_new.txt`
  - `fastlane/metadata/ios/ar-SA/whats_new.txt`
  - `fastlane/metadata/ios/en-US/description.txt`
  - `fastlane/metadata/ios/ar-SA/description.txt`

## Rollback
### Google Play
- Promote the previous production release if it still exists on Play.
- If rollout started and must stop, halt the rollout or unpublish the bad release in Play Console.

### App Store Connect
- Reject the current submission if it has not gone live yet.
- Re-submit the previous approved build if a replacement release is needed.

## Local Commands
- `bundle exec fastlane lanes`
- `bundle exec fastlane meta_sync flavor:production`
- `bundle exec fastlane android a_rel`
- `bundle exec fastlane ios prepare_ios_signing flavor:production`
- `bundle exec fastlane ios i_rel`
