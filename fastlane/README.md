fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### meta_sync

```sh
[bundle exec] fastlane meta_sync
```

Generate and optionally sync metadata-only release notes.

### shots_opt

```sh
[bundle exec] fastlane shots_opt
```

Validate screenshot folders when present.

----


## Android

### android a_beta

```sh
[bundle exec] fastlane android a_beta
```

Deploy Android beta build to the internal track.

### android a_rel

```sh
[bundle exec] fastlane android a_rel
```

Deploy Android production build to Google Play production.

----


## iOS

### ios prepare_ios_signing

```sh
[bundle exec] fastlane ios prepare_ios_signing
```

Prepare iOS signing assets with match.

### ios i_beta

```sh
[bundle exec] fastlane ios i_beta
```

Deploy iOS beta build to TestFlight.

### ios i_rel

```sh
[bundle exec] fastlane ios i_rel
```

Deploy iOS production build to App Store Connect.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
