## Release Process

Releases are performed via [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).  This promotes consistency and visibility in the process.

### Steps

1. Confirm `sdkVersion` in `OpenPassConfiguration.swift` is expected version.
2. Use GitHub Releases to create tag matching `sdkVersion` in `OpenPassManager` and publish release.
3. Update `sdkVersion` in `OpenPassConfiguration.swift` to next minor version to support future development and merge into `main`.

### CocoaPods

Updating the version and tag in podspec.json files is unnecessary. The [cocoapods-publish](https://github.com/openpass-sso/openpass-ios-sdk/actions/workflows/cocoapods-publish.yml) workflow will do this automatically when you publish.

### Version Numbers

Version Numbering follows [Semantic Versioning](https://semver.org) standards.  The format is `MAJOR.MINOR.PATCH`.. ex `0.1.0`

<img width="753" alt="semver-summary" src="https://user-images.githubusercontent.com/989928/230925438-ac6ac422-6358-4e96-9536-e3f8fc935317.png">
