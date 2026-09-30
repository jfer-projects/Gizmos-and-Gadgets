# Release checklist

Things only the owner can do are marked **[you]**.

## Before the first store submission

- [ ] **[you]** Choose the final name. Search the US Patent and Trademark Office and EU trademark databases, app stores and domain names. Change `config/name` in `game/project.godot` and the export presets.
- [ ] **[you]** Decide who publishes (a person or a company) and create the developer accounts: Apple Developer Program and Google Play Console. Both charge a fee.
- [ ] **[you]** Get the privacy policy reviewed by a lawyer who knows children's privacy (COPPA, GDPR-K). Host it at a public web address.
- [ ] Set a real reverse-domain package name in `game/export_presets.cfg` (Android `package/unique_name`, iOS and macOS `bundle_identifier`). The current value is a placeholder.
- [ ] Replace placeholder art and fonts. Update `ASSETS.md`.
- [ ] Playtest with children and fix what they find.
- [ ] Test on real devices (`TEST_PLAN.md`).

## Android

1. Install Android Studio or the command-line tools, and JDK 17.
2. In Godot: Editor Settings > Export > Android, set the SDK path and JDK path.
3. Create a release keystore with `keytool`. Keep it and its password safe. Losing it means you cannot update the app.
4. In the Android export preset set the keystore, user and password (use environment variables, not the file).
5. Export an AAB (Play Store needs this) by switching the preset to gradle build with AAB output, after installing the Android build template from Project > Install Android Build Template.
6. Upload to Google Play Console. Fill in target audience, the data safety form and the content rating (see `STORE_LISTING.md`). Opt in to the Families program.
7. Use the internal testing track first.

## iOS

1. A Mac with Xcode, and an Apple developer account.
2. In the iOS export preset set the team ID and a real bundle identifier.
3. Export from Godot to an Xcode project, open it in Xcode, set signing, archive and upload to App Store Connect.
4. Set the Kids Category and the 9 to 11 age band. Enter the privacy policy link and the "Data Not Collected" label.
5. Use TestFlight first.

## Desktop and web (optional)

- Web, Windows, macOS and Linux builds are made by `.github/workflows/export.yml` or by `godot --export-release`. They are unsigned. Windows will show a SmartScreen warning; macOS needs an Apple developer certificate and notarisation to open without a warning.
- To host the web build, serve the `build/web` folder over HTTPS. This build does not need cross-origin isolation headers.

## Every release

- [ ] Raise the version (`version/name`, `version/code` on Android, `application/version` on iOS and macOS).
- [ ] `game/tests/run_all.sh` prints ALL GREEN.
- [ ] Re-take store screenshots if screens changed.
- [ ] Check the store forms still match the game (no new permissions, no new data).
- [ ] Tag the release in git.
