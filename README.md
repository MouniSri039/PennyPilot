# PennyPilot — Offline Budgeting & Savings Companion

Team PennyPilot: Akshitha Sainath Sanagarapu and Mouni Sri Nallapaneni.

GitHub: https://github.com/MouniSri039/PennyPilot
ClickUp: https://app.clickup.com/90141780871/v/b/2kydwuw7-354

## Setup
Requires Flutter SDK, Android Studio / Android SDK, and a device or emulator.
This archive contains **Dart application source**, not generated Android/iOS
platform scaffolding. In a fresh folder, run:

```bash
flutter create --project-name pennypilot .
flutter pub get
flutter run
flutter test
flutter build apk --release
```

`flutter create` fills in the platform-specific files while preserving `lib/`,
`test/`, and `pubspec.yaml`. Check the generated Android settings for compatibility
with the `flutter_local_notifications` plugin if you later enable notifications.

## Current implemented scope in source
- Five primary screen roles with navigation and transaction details
- SQLite full CRUD for categories and transactions, validated forms,
  delete confirmations, explicit parent/child restriction
- Monthly budget, settings persistence, category filter and spending aggregates
- Offline spending helper with a simple baseline and unit tests
- Savings challenge with persistent start/progress/finish/reset/delete
- Spending-by-category bar chart and empty states

## Not yet implemented / verify before submission
- Actual scheduled local notifications (only the preference toggle exists)
- CSV export, advanced graduate background task, animations
- Device-specific integration tests and two-device evidence
- Actual APK, screenshots, test results, 20 meaningful commits per person,
  ClickUp snapshots, presentation, video, and final submission evidence

Do not claim these are complete until tested and documented.

## Workflow
Each teammate should work on their own Git branch and commit their own genuine
work. Use pull requests and review before merging. See `TEAM_COMMITS.md`.
