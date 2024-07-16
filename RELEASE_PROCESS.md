## Release Process

Releases are performed via [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).  This promotes consistency and visibility in the process.

### Steps

1. Confirm `sdkVersion` in `OpenPassManager` is expected version.
2. Use GitHub Releases to create tag matching `sdkVersion` in `OpenPassManager` and publish release.
3. Update `sdkVersion` in `OpenPassManager` to next minor version to support future development and merge into `main`.
4. Update `version` and `source.tag` in `OpenPass.podspec.json` to next match the new version number.

### Version Numbers

Version Numbering follows [Semantic Versioning](https://semver.org) standards.  The format is `MAJOR.MINOR.PATCH`.. ex `0.1.0`

<img width="753" alt="semver-summary" src="https://user-images.githubusercontent.com/989928/230925438-ac6ac422-6358-4e96-9536-e3f8fc935317.png">
