# Nag - iOS Task Companion App

## Project Overview
"Nag" (bundle name: Command) is an iOS mission control app for tracking schoolwork and professional tasks. Features Google Classroom sync, on-device AI task decomposition, customizable aggression-based reminders, focus sessions with Live Activities, and a dark minimalist UI.

**App is fully built and functional.** All models, services, views, widgets, and Live Activities are implemented. The app runs on simulator and physical device (iPhone 17 Pro Max).

## Design & Plan Docs
- Design: `docs/plans/2026-02-16-command-app-design.md`
- Implementation Plan: `docs/plans/2026-02-16-command-implementation-plan.md`

## Tech Stack
- SwiftUI, SwiftData (local only), Swift 6, iOS 26+
- Apple Foundation Models (on-device AI) via `import FoundationModels`
- Google Classroom REST API + OAuth 2.0
- WidgetKit, ActivityKit (Live Activities)
- XcodeGen for project generation (`project.yml`)
- No third-party dependencies

## Build Commands
```bash
xcodegen generate
xcodebuild -project Command.xcodeproj -scheme Command -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Important**: Run `xcodegen generate` after creating/deleting any `.swift` file so Xcode picks it up.

## Physical Device
- Device: Jorge17PM (iPhone 17 Pro Max)
- Team ID: `63ZPJW7K2C`
- Bundle ID: `com.jgbocobo.command`

## Simulator
- Available: iPhone 17 Pro (ID: `3BA75808-2C03-477B-9CB6-230425658660`), iPhone 17 Pro Max, iPhone 17, iPad variants
- **No iPhone 16 Pro** — use iPhone 17 Pro for builds

---

## App Architecture

### Tab Structure (ContentView in CommandApp.swift)
1. **Dashboard** — main view with urgency-sorted missions, overdue/due today/upcoming sections, settings gear, search
2. **Classroom** — Google Classroom sync, course list, hide/show courses
3. **Focus** — select a mission to start a Pomodoro-style focus session with Live Activity
4. **Intel** — analytics dashboard with heatmap, momentum chart, task DNA chart

### Key Patterns
- **@Observable ViewModels** — `DashboardViewModel`, `MissionViewModel`, `ClassroomViewModel`, `FocusViewModel`, `IntelViewModel`
- **SwiftData @Model** — `Mission`, `MissionStep`, `Resource`, `FocusSession`, `EnergyProfile`, `Streak`, `ClassroomCourse`
- **@AppStorage for settings** — haptics, sounds, quiet hours, default aggression/category, accent color, aggression configs
- **Dark theme only** — all views use `CommandColors.background` as base, `.preferredColorScheme(.dark)`
- **NO emojis in UI**

### Notification System
- `AppDelegate` in CommandApp.swift handles foreground notifications and action buttons (Complete, Snooze, Start Focus)
- Uses `@preconcurrency import UserNotifications`, `@unchecked Sendable`, `nonisolated` for Swift 6 concurrency
- `NotificationService` schedules via `UNUserNotificationCenter`
- `AggressionScheduler` generates notification schedules per level, now fully configurable

### Aggression System (Customizable)
Each aggression level (gentle/moderate/aggressive/nuclear) has configurable:
- **Notification count** (how many reminders before deadline)
- **First reminder timing** (how early before deadline)
- **Nuclear-only**: overdue repeat interval + overdue notification count

Config stored in UserDefaults via `AggressionConfigStore`. Defaults:
- Gentle: 1 notification, 24h before
- Moderate: 5 notifications, 48h before
- Aggressive: 8 notifications, 72h before
- Nuclear: 8 pre-deadline (72h), + 8 overdue every 15min

### Urgent Mission Handling
- **Nuclear overdue** → full-screen `NuclearInterstitialView` via `fullScreenCover(item: $nuclearMission)`
- **Aggressive overdue** → `UrgentBannerView` banner at top
- Uses `onChange(of: allMissions.count)` + 300ms delay in `.task` to handle @Query timing

### Settings (SettingsView)
Accessible via gear icon in DashboardView header. Sections:
- Feedback: vibrations toggle, notification sounds
- Quiet hours: toggle + start/end time pickers
- Default aggression: AggressionSlider
- Notification schedule: per-level customization → pushes to `AggressionConfigView`
- Default category: school/work/personal
- Accent color: 6 color options
- Data: delete test data, reset all

### Live Activities
- `FocusLiveActivity` — shows during focus sessions on Lock Screen + Dynamic Island
- `DeadlineLiveActivity` — shows approaching deadlines
- Widget extension embedded in main app via `project.yml` dependency
- Attributes defined in `Shared/ActivityAttributes.swift`

---

## File Structure

### Command/ (Main App Target)
```
CommandApp.swift          — App entry, ContentView with tabs, AppDelegate, FocusLauncherView

Models/
  Enums.swift             — MissionSource, MissionCategory, MissionStatus, MissionPriority,
                            AggressionLevel, CognitiveLoad, ResourceType, StreakCategory
  Mission.swift           — @Model with computed: isOverdue, stepProgress, urgencyScore
  MissionStep.swift       — @Model for sub-tasks
  Resource.swift          — @Model with URL computed property
  FocusSession.swift      — @Model with durationMinutes
  EnergyProfile.swift     — @Model with rolling average update
  Streak.swift            — @Model with consecutive day logic
  ClassroomCourse.swift   — @Model for Google Classroom courses

Services/
  AggressionScheduler.swift   — AggressionLevelConfig, AggressionConfigStore, AggressionScheduler
  AIService.swift             — Foundation Models + ManualAIService fallback
  ClassroomService.swift      — OAuth + REST API + DTOs
  EnergyService.swift         — energy tracking + mission ordering
  HapticService.swift         — Haptic enum, respects hapticsEnabled toggle
  KeychainService.swift       — iOS Keychain wrapper
  MicroStartGenerator.swift   — AI micro-start + fallback templates
  NotificationService.swift   — UNUserNotificationCenter scheduling + categories
  StreakService.swift          — streak tracking
  SyncService.swift            — Classroom sync orchestration

Theme/
  Colors.swift            — CommandColors enum (hex init, all app colors)
  Typography.swift        — CommandTypography (SF Pro scales)
  Animations.swift        — CommandAnimations (spring/pulse/smooth)
  CommandTheme.swift      — ViewModifier for theme

ViewModels/
  MissionViewModel.swift     — CRUD, AI decomposition, notifications
  ClassroomViewModel.swift   — sync via SyncService
  FocusViewModel.swift       — focus session state machine + Live Activity
  IntelViewModel.swift       — analytics aggregation

Views/
  Components/
    AggressionBadge.swift       — signal-bar indicator per level
    AggressionSlider.swift      — segmented slider, reads config for sublabels
    AnimatedCountdown.swift     — live countdown with urgency colors
    EmptyStateView.swift        — reusable empty state
    GlowEffect.swift            — glow + pulsing view modifiers
    MissionCard.swift           — card with category bar, metadata, progress ring
    NuclearInterstitialView.swift — full-screen nuclear alert
    SectionHeader.swift         — reusable section header
    UrgentBannerView.swift      — top banner for aggressive overdue
  Dashboard/
    DashboardView.swift         — main dashboard with settings gear, search, sections
  Classroom/
    ClassroomView.swift         — Classroom tab
    CourseListView.swift        — course list
    SyncStatusView.swift        — sync status indicator
  Focus/
    FocusSessionView.swift      — focus session flow
    FocusTimerView.swift        — circular timer with TimelineView
    BreakView.swift             — break screen with prompts
  Intel/
    IntelView.swift             — analytics dashboard
    HeatmapView.swift           — GitHub-style grid via Canvas
    MomentumChartView.swift     — line chart
    TaskDNAChartView.swift      — bar chart
  Missions/
    CreateMissionView.swift     — form with AI decompose, reads default settings
    MissionDetailView.swift     — full detail with steps, resources
    MissionListView.swift       — filterable list (used within dashboard)
    MissionStepRow.swift        — toggleable step row
  Onboarding/
    OnboardingView.swift        — 3-screen onboarding
  Settings/
    SettingsView.swift          — full settings page
    AggressionConfigView.swift  — per-level aggression customization

Intents/
  AddMissionIntent.swift    — Siri shortcut to add mission
  NagShortcuts.swift        — AppShortcutsProvider
```

### CommandWidgets/ (Widget Extension Target)
```
CommandWidgetBundle.swift       — widget bundle registration
SmallWidget.swift               — small home screen widget
MediumWidget.swift              — medium widget
LargeWidget.swift               — large widget
LiveActivity/
  FocusLiveActivity.swift       — focus session Live Activity + Dynamic Island
  DeadlineLiveActivity.swift    — deadline Live Activity
```

### Shared/ (Both Targets)
```
ActivityAttributes.swift    — FocusActivityAttributes, DeadlineActivityAttributes
ColorHex.swift              — Color(hex:) extension
```

---

## Known Issues & Gotchas

### Swift 6 Concurrency
- `@Model` classes require fully qualified enum defaults (e.g., `MissionSource.manual` not `.manual`)
- `#Predicate` with `Optional<String>` needs local variable with matching optionality
- `UNUserNotificationCenterDelegate` needs `@preconcurrency import`, `@unchecked Sendable`, `nonisolated`
- Avoid `static let` for non-Sendable types (e.g., `UserDefaults.standard`) — use inline `UserDefaults.standard` calls

### SwiftData @Query Timing
- `@Query` results don't update instantly after `context.insert()` + `context.save()`
- Use `onChange(of: collection.count)` or small `Task.sleep` delay when checking newly inserted data
- `fullScreenCover(item:)` is preferred over `fullScreenCover(isPresented:)` + separate optional state

### XcodeGen
- Widget extension must be a dependency of the main app target (not the other way around)
- Both targets need `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` for device install
- Widget target needs `GENERATE_INFOPLIST_FILE: YES`

### Other
- Classroom OAuth client ID is empty string placeholder — needs real credentials
- Foundation Models: `import FoundationModels` (iOS 26+), has `ManualAIService` fallback
- `CharacterSet` uses `.whitespacesAndNewlines` in Swift 6 (not `.whitespace`)
- The app display name is "Nag" (set via `PRODUCT_NAME` and `INFOPLIST_KEY_CFBundleDisplayName`)

---

## What's Not Yet Wired Up
- **Quiet hours** — stored in UserDefaults but `NotificationService` doesn't check them before scheduling
- **Notification sound toggle** — `notificationSoundEnabled` AppStorage not checked in `NotificationService`
- **Accent color** — `accentColorHex` stored but `CommandColors` still uses hardcoded colors (only Settings uses it)
- **Classroom OAuth** — client ID is empty placeholder, needs real Google Cloud credentials
