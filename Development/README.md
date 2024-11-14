# OpenPass iOS SDK Development App

## Device Authentication Flow

In order to test this flow you will need to set `OpenPassClientId` to `51c42041a7de48f59bff4f8a8a6ad18b` in `Info.plist`, i.e.

```
plutil -replace OpenPassClientId -string "51c42041a7de48f59bff4f8a8a6ad18b" Development/OpenPassDevelopmentApp/Info.plist
```

and to revert:

```
plutil -replace OpenPassClientId -string "421d407048794885b2baf4dbcde185cb" Development/OpenPassDevelopmentApp/Info.plist
```
