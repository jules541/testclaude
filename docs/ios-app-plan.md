# iOS App Plan — Quarterly Goal Plan (native SwiftUI)

> **Status:** Approved plan, ready to implement **in Claude Code on a Mac terminal**
> (Xcode is macOS-only). When you start there, tell Claude Code:
> *"Read docs/ios-app-plan.md and start implementing M1 (project scaffold + parity core)."*

## Context

The Quarterly Goal Plan currently exists as a vanilla HTML/CSS/JS web app
(`index.html`, `script.js`, `styles.css`) deployed to GitHub Pages
(https://jules541.github.io/testclaude/). The goal is a **native iPhone app**.

Decisions made:

- **Approach:** Build native in **SwiftUI** (best feel + deepest iPhone integration).
- **Data:** **Local on device**, with JSON export/import for backup (mirrors today's model).
- **Priority features:** **Reminders/notifications**, **home-screen widget**, **streaks & momentum**.
  (Face ID lock was *not* selected — noted as a future option, not built now.)

The existing web app is the **functional spec**: the iOS app should reach feature parity
with its four screens, reuse its scoring rules exactly, and stay **data-compatible** with
its exported JSON so a plan can move between web and phone.

## Prerequisites on the Mac (one-time)

- **Xcode** (Mac App Store), then `xcode-select --install`.
- **Homebrew**, then `brew install xcodegen` — generates `ios/GoalPlan.xcodeproj` from a
  `project.yml` instead of hand-writing the project file.
- No Apple Developer account ($99/yr) is needed to run on the Simulator or side-load to your
  own iPhone for 7-day testing; it's required only for App Store release.

## Architecture

- **Location:** new `ios/` folder in this repo (keeps the web app + Pages deploy untouched;
  the web app remains the reference implementation).
- **Project:** `ios/GoalPlan.xcodeproj` (via XcodeGen `project.yml`) with two targets:
  - `GoalPlan` — the SwiftUI app.
  - `GoalPlanWidget` — a WidgetKit extension.
- **Min deployment target:** iOS 17 (enables the Observation `@Observable` macro; modern SwiftUI).
- **App Group entitlement** (`group.<bundle-id>`) on both targets so the widget can read the
  same data the app writes — the standard, only-supported way an app shares live data with its widget.

### Data model (Codable, JSON-compatible with the web app)

Mirror the web JSON shape exactly so files exported from the web app import cleanly and vice
versa. Source of truth = `script.js` `defaultPlan()` / persisted shape:

```
Plan   { owner, quarter, weeksInQuarter, vision, goals: [Goal], scores: [String: [String: Double]] }
Goal   { id, emoji, name, why, habits: [Habit] }
Habit  { id, name, unit, target: Double }
```

- `scores` keyed by week-number-as-string → `habitId` → value, identical to the web app.
- Persist as a single `plan.json` file **in the App Group shared container** (so the widget
  reads it too). Chosen over SwiftData because it gives free web-app JSON interop, trivial
  export/import, and zero-setup widget sharing for this small, document-shaped dataset.

### Scoring (port `script.js` verbatim — pure functions, unit-tested)

Reuse the exact rules so numbers match the web app (e.g. seeded Week 1 = 89%):
- `habitPct = value == nil ? nil : min(value/target, 1)`
- `goalPct(week)` = average of its habits' non-nil pcts
- `weekPct(week)` = average of goals' non-nil pcts
- `quarterPct` = average of `weekPct` over logged weeks
- plus `loggedWeeks`, `nextWeekToLog`

### State

- `PlanStore` (`@Observable`, injected via environment): loads/saves `plan.json`, seeds the
  default plan (same Jules seed + Week 1 scores as the web app), exposes scoring + mutations,
  and calls `WidgetCenter.shared.reloadAllTimelines()` after every save.

## Screens (TabView — parity with the web app's four tabs)

1. **Dashboard** — quarter score, latest/best week, per-goal progress, vision, **+ current streak**.
2. **Plan** — edit vision, goals (emoji/name/why), habits + weekly targets; plan settings
   (name, quarter, # weeks). Mirrors the web "My Plan" tab incl. add/edit/delete goal.
3. **Tracker** — week picker + live score entry per habit; goal/week percentages update as you type.
4. **Progress** — bar chart of weekly scores + the habits×weeks score sheet (color-coded cells),
   plus a Share button to export `plan.json`.
5. **Settings** (new, small) — notification toggles/times, streak threshold, export/import.

Reuse the web theme for visual continuity: green `#2f6f5e` / gold `#d9a441` accent
(see `styles.css` `:root`), set as Asset Catalog colors.

## Priority feature 1 — Streaks & momentum

- **Overall weekly streak:** count of most-recent *consecutive logged weeks* with
  `weekPct ≥ threshold` (default **80%**, configurable in Settings), counting backward from
  the latest logged week. Shown prominently on the Dashboard.
- **Per-goal streak:** same rule on `goalPct`, shown on each goal card.
- Pure, unit-tested logic in `Streaks.swift`. Surfaced on Dashboard + (compact) in the widget.

## Priority feature 2 — Reminders / notifications (`UserNotifications`)

- `NotificationManager`: request authorization on first enable; schedule/cancel on changes.
- **Weekly log reminder:** `UNCalendarNotificationTrigger` repeating (default **Sunday 6pm**);
  weekday + time pickable in Settings.
- **Optional daily habit reminder:** daily repeating at a chosen time.
- Tapping a notification deep-links into the Tracker for the current week.

## Priority feature 3 — Home-screen widget (`WidgetKit`)

- `GoalPlanWidget` extension; shares `Models`/`Scoring`/`Streaks`/shared-container code with the
  app via target membership, and reads `plan.json` from the **App Group** container.
- **Small:** quarter score + current week score + current streak.
- **Medium:** adds per-goal mini progress bars.
- `TimelineProvider` returns one entry, refreshed via `reloadAllTimelines()` on app save plus a
  periodic timeline; `widgetURL` deep-links into the app on tap.

## Export / Import (backup — chosen data model)

- **Export:** share sheet (`ShareLink`) emitting `plan.json` — same format as the web app's export.
- **Import:** `fileImporter` to load a `plan.json` (from the web app or another device);
  validate shape, then replace the current plan.

## Files to create

Under `ios/GoalPlan/`:
- App: `GoalPlanApp.swift`, `RootTabView.swift`
- Model/logic: `Models.swift`, `Scoring.swift`, `Streaks.swift`, `PlanStore.swift`, `SharedContainer.swift`
- Views: `DashboardView.swift`, `PlanView.swift` (+ goal edit), `TrackerView.swift`,
  `ProgressView.swift`, `SettingsView.swift`
- Notifications: `NotificationManager.swift`
- Assets: `Assets.xcassets` (app icon + accent colors from `styles.css`)

Under `ios/GoalPlanWidget/`:
- `GoalPlanWidget.swift` (Provider/Entry/Views); shares Models/Scoring/SharedContainer via target membership.

Under `ios/GoalPlanTests/`:
- `ScoringTests.swift`, `StreakTests.swift`

Project root `ios/`:
- `project.yml` (XcodeGen), entitlements/Info plists for the App Group on both targets.

Reference (spec source, unchanged): `index.html`, `script.js`, `styles.css`.

## Milestones (implementation order)

1. **M1 — Parity core:** XcodeGen `project.yml` + targets + App Group; `Models`/`Scoring`/`PlanStore`
   + the 4 screens reaching feature parity with the web app (incl. seeded plan).
2. **M2 — Streaks:** `Streaks.swift` + Dashboard/goal-card display + tests.
3. **M3 — Notifications:** `NotificationManager` + Settings toggles/times + deep link.
4. **M4 — Widget:** extension, shared-container reads, small + medium, deep link.
5. **M5 — Backup + polish:** export/import, app icon, accent colors, empty/edge states.

## Verification (on the Mac)

1. `xcodegen generate` (in `ios/`), open `ios/GoalPlan.xcodeproj`; build & run in the iOS
   Simulator (iPhone 16).
2. **Unit tests (`xcodebuild test` / ⌘U):** scoring matches the web app (seeded **Week 1 = 89%**,
   quarter math, `nextWeekToLog`); streak rules (consecutive ≥ threshold, breaks on a miss/gap).
3. **Parity pass:** click through all four screens; confirm behavior matches the live web app.
4. **Notifications:** enable in Settings; confirm the scheduled local notification fires in the
   Simulator and deep-links to the Tracker.
5. **Widget:** add small + medium widgets to the Simulator home screen; log a score and confirm
   the widget refreshes; tap to confirm it opens the app.
6. **Interop:** export `plan.json` from the web app, import it into the iOS app, confirm scores
   render identically.

## Notes / future options

- **Face ID lock** (deferred): later, gate launch behind `LocalAuthentication` with a Settings toggle.
- **iCloud sync** would be the natural next step for multi-device; it would swap the local
  `plan.json` for an iCloud/CloudKit-backed store without changing the screens.
