# Command - iOS Task Companion App

## Project Overview
iOS mission control app for tracking schoolwork and professional tasks. Google Classroom sync, on-device AI task decomposition, customizable aggression-based reminders, dark minimalist UI.

## Design & Plan Docs
- Design: `docs/plans/2026-02-16-command-app-design.md`
- Implementation Plan: `docs/plans/2026-02-16-command-implementation-plan.md`

## Tech Stack
- SwiftUI, SwiftData (local only), iOS 26+
- Apple Foundation Models (on-device AI)
- Google Classroom REST API + OAuth 2.0
- WidgetKit, ActivityKit (Live Activities)
- XcodeGen for project generation

## Build Commands
```bash
xcodegen generate
xcodebuild -project Command.xcodeproj -scheme Command -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Rules for All Agents
1. **Update your progress section** in this file after EACH completed task
2. **Only modify files in your assigned list** — never touch another agent's files
3. **Commit after each task** with prefix: `[backend]`, `[frontend]`, or `[manager]`
4. **If blocked**, add a `BLOCKED:` note in your section with what you need and from whom
5. **Run `xcodegen generate`** after creating new .swift files (so Xcode picks them up)
6. Format: `- [x] Task description (commit: <short-sha>)` or `- [ ] Task in progress`

---

## Manager (Lead)
Owner: CommandApp.swift, CLAUDE.md, integration, project config, conflict resolution

### Assigned Files
- `Command/CommandApp.swift`
- `CLAUDE.md`
- `project.yml`
- `docs/`

### Responsibilities
- Coordinate between Backend and Frontend agents
- Handle integration: wire views into CommandApp.swift tabs
- Resolve any build errors that span both domains
- Final build verification
- Update architecture decisions here

### Progress
- [x] Scaffold project structure
- [x] Create project.yml for XcodeGen
- [x] Create placeholder models and app entry point
- [ ] Wire real views into tab bar (after Frontend completes)
- [ ] Final integration build

---

## Backend Engineer
Owner: All Models and Services. Data layer and business logic.

### Assigned Files (ONLY touch these)
- `Command/Models/Enums.swift`
- `Command/Models/Mission.swift`
- `Command/Models/MissionStep.swift`
- `Command/Models/Resource.swift`
- `Command/Models/FocusSession.swift`
- `Command/Models/EnergyProfile.swift`
- `Command/Models/Streak.swift`
- `Command/Models/ClassroomCourse.swift`
- `Command/Services/AIService.swift` (create)
- `Command/Services/ClassroomService.swift` (create)
- `Command/Services/KeychainService.swift` (create)
- `Command/Services/NotificationService.swift` (create)
- `Command/Services/AggressionScheduler.swift` (create)
- `Command/Services/EnergyService.swift` (create)
- `Command/Services/StreakService.swift` (create)
- `Command/Services/SyncService.swift` (create)
- `Command/Services/MicroStartGenerator.swift` (create)

### Task List
1. Replace placeholder Enums.swift with full enum definitions + CognitiveLoad.sortOrder extension
2. Replace placeholder Mission.swift with full model (computed properties: isOverdue, stepProgress, totalActualMinutes)
3. Replace placeholder MissionStep.swift with full model
4. Replace placeholder Resource.swift with full model (URL computed property)
5. Replace placeholder FocusSession.swift with full model (durationMinutes computed property)
6. Replace placeholder EnergyProfile.swift with full model (update method with rolling average)
7. Replace placeholder Streak.swift with full model (recordActivity with consecutive day logic)
8. Replace placeholder ClassroomCourse.swift with full model
9. Create KeychainService.swift — save/load/delete from iOS Keychain, string convenience methods
10. Create ClassroomService.swift — Google OAuth via ASWebAuthenticationSession, REST API calls (fetchCourses, fetchCourseWork, fetchSubmissions), token refresh, DTOs
11. Create AIService.swift — AIServiceProtocol, OnDeviceAIService (Foundation Models), ManualAIService fallback, response parsing
12. Create NotificationService.swift — UNUserNotificationCenter scheduling, notification categories/actions (complete, snooze, start focus)
13. Create AggressionScheduler.swift — calculate notification times per AggressionLevel, generate escalating content/tone
14. Create MicroStartGenerator.swift — wrap AIService.generateMicroStart + fallback templates
15. Create EnergyService.swift — record sessions, calculate current energy, suggest mission order
16. Create StreakService.swift — record completions, get streaks
17. Create SyncService.swift — Classroom sync orchestration, background task registration, conflict resolution
18. Verify all services compile, update CLAUDE.md

### Progress
- [ ] (update as you go)

### Notes
- See implementation plan for full code for each service
- Classroom OAuth needs a Google Cloud project client ID (leave as empty string placeholder)
- Foundation Models import: `import FoundationModels` (iOS 26+)
- Notification scheduling: use UNTimeIntervalNotificationTrigger and UNCalendarNotificationTrigger

---

## Frontend Engineer
Owner: All Views, ViewModels, Theme, Widgets, Live Activities. UI and presentation layer.

### Assigned Files (ONLY touch these)
- `Command/Theme/Colors.swift` (create)
- `Command/Theme/Typography.swift` (create)
- `Command/Theme/Animations.swift` (create)
- `Command/Theme/CommandTheme.swift` (create)
- `Command/Views/Components/GlowEffect.swift` (create)
- `Command/Views/Components/AggressionBadge.swift` (create)
- `Command/Views/Components/MissionCard.swift` (create)
- `Command/Views/Components/AnimatedCountdown.swift` (create)
- `Command/Views/Components/UrgentBannerView.swift` (create)
- `Command/Views/Components/NuclearInterstitialView.swift` (create)
- `Command/Views/Dashboard/DashboardView.swift` (create)
- `Command/Views/Dashboard/PressureRadarView.swift` (create)
- `Command/Views/Dashboard/TodayMissionsView.swift` (create)
- `Command/Views/Dashboard/MomentumStripView.swift` (create)
- `Command/Views/Missions/MissionListView.swift` (create)
- `Command/Views/Missions/MissionDetailView.swift` (create)
- `Command/Views/Missions/MissionStepRow.swift` (create)
- `Command/Views/Missions/CreateMissionView.swift` (create)
- `Command/Views/Classroom/ClassroomView.swift` (create)
- `Command/Views/Classroom/CourseListView.swift` (create)
- `Command/Views/Classroom/SyncStatusView.swift` (create)
- `Command/Views/Focus/FocusSessionView.swift` (create)
- `Command/Views/Focus/FocusTimerView.swift` (create)
- `Command/Views/Focus/BreakView.swift` (create)
- `Command/Views/Intel/IntelView.swift` (create)
- `Command/Views/Intel/HeatmapView.swift` (create)
- `Command/Views/Intel/MomentumChartView.swift` (create)
- `Command/Views/Intel/TaskDNAChartView.swift` (create)
- `Command/Views/Onboarding/OnboardingView.swift` (create)
- `Command/ViewModels/DashboardViewModel.swift` (create)
- `Command/ViewModels/MissionViewModel.swift` (create)
- `Command/ViewModels/ClassroomViewModel.swift` (create)
- `Command/ViewModels/FocusViewModel.swift` (create)
- `Command/ViewModels/IntelViewModel.swift` (create)
- `CommandWidgets/CommandWidgetBundle.swift` (replace placeholder)
- `CommandWidgets/SmallWidget.swift` (create)
- `CommandWidgets/MediumWidget.swift` (create)
- `CommandWidgets/LargeWidget.swift` (create)
- `CommandWidgets/LiveActivity/FocusLiveActivity.swift` (create)
- `CommandWidgets/LiveActivity/DeadlineLiveActivity.swift` (create)

### Task List
1. Create Theme system: Colors.swift (hex init, all Command colors), Typography.swift (SF Pro scales), Animations.swift (spring/pulse/smooth), CommandTheme.swift (ViewModifier)
2. Create GlowEffect.swift — GlowEffect + PulsingGlow view modifiers
3. Create AggressionBadge.swift — signal-bar style indicator per aggression level
4. Create MissionCard.swift — card with category bar, title, metadata, aggression badge, circular progress
5. Create AnimatedCountdown.swift — live countdown with numericText transition, urgency colors
6. Create PressureRadarView.swift — sonar radar with rings, sweep line, mission blips, tap interaction
7. Create TodayMissionsView.swift — sorted mission list with energy indicator
8. Create MomentumStripView.swift — expandable streak bars with flame animation
9. Create DashboardViewModel.swift + DashboardView.swift — assemble dashboard tab
10. Create MissionListView.swift — filterable list with category segments, search, swipe actions
11. Create CreateMissionView.swift — form with AI decompose button
12. Create MissionDetailView.swift — full detail with steps, resources, deadline, aggression picker
13. Create MissionStepRow.swift — toggleable step row with progress
14. Create MissionViewModel.swift — CRUD, AI decomposition trigger, step management
15. Create FocusTimerView.swift — circular depleting ring timer with TimelineView
16. Create BreakView.swift — adaptive break screen with movement prompts
17. Create FocusSessionView.swift + FocusViewModel.swift — focus session state machine
18. Create ClassroomView.swift + CourseListView.swift + SyncStatusView.swift — Classroom tab
19. Create ClassroomViewModel.swift — drives sync via SyncService
20. Create IntelView.swift — scrollable analytics dashboard
21. Create HeatmapView.swift — GitHub-style contribution grid using Canvas
22. Create MomentumChartView.swift + TaskDNAChartView.swift — line/bar charts
23. Create IntelViewModel.swift — aggregate analytics data
24. Create OnboardingView.swift — 3 screens (welcome, energy setup, Classroom connect)
25. Create UrgentBannerView.swift + NuclearInterstitialView.swift — notification overlays
26. Replace CommandWidgetBundle.swift + create Small/Medium/Large widgets
27. Create FocusLiveActivity.swift + DeadlineLiveActivity.swift
28. Verify all views compile, update CLAUDE.md

### Progress
- [ ] (update as you go)

### Notes
- See implementation plan for full code for each component
- Import models directly (same target): `Mission`, `MissionStep`, etc.
- ViewModels use `@Observable` macro and `@Environment(\.modelContext)`
- All views must use CommandColors.background as base, dark theme only
- Aesthetic: dark mission control, minimalist, refined animations, subtle glows, SF Pro typography
- NO emojis anywhere in the UI

---

## Integration Log
(Manager updates with merge issues, API contract changes, build status)
