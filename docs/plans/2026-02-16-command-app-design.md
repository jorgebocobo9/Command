# Command - iOS Task Companion App Design

**Date**: 2026-02-16
**Status**: Approved
**Platform**: iOS (SwiftUI, native)
**Architecture**: Monolithic SwiftUI App (MVVM + Services)

---

## 1. Vision

Command is a personal mission control app for tracking schoolwork and professional tasks. It pulls assignments from Google Classroom, breaks them into actionable steps with on-device AI, and persistently reminds you with customizable aggression levels. The aesthetic is a dark, minimalist mission-control dashboard with refined animations and subtle glow effects.

**Core differentiators**:
- Per-task aggression levels for notifications (gentle to nuclear)
- On-device AI task decomposition with resource linking
- Energy-aware smart scheduling
- Deadline pressure radar visualization
- Anti-procrastination behavioral interventions
- Task DNA difficulty fingerprinting that learns your patterns

---

## 2. App Structure

Tab-based navigation with 5 tabs:

| Tab | Purpose |
|-----|---------|
| **Dashboard** | War room. Pressure radar, today's missions, momentum strip |
| **Missions** | Full task list with filtering, sorting, search |
| **Classroom** | Google Classroom sync hub. Courses, assignments, auto-import |
| **Focus** | Smart Pomodoro+ focus session launcher |
| **Intel** | Personal analytics. Energy patterns, Task DNA, momentum waves |

---

## 3. Data Model (SwiftData, Local Only)

### Mission
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| title | String | |
| description | String | |
| source | Enum (.manual, .googleClassroom) | |
| category | Enum (.school, .work, .personal) | |
| status | Enum (.pending, .inProgress, .completed, .abandoned) | |
| priority | Enum (.low, .medium, .high, .critical) | |
| aggressionLevel | Enum (.gentle, .moderate, .aggressive, .nuclear) | |
| deadline | Date? | |
| createdAt | Date | |
| completedAt | Date? | |
| estimatedMinutes | Int? | AI-generated |
| actualMinutes | Int? | Tracked via focus sessions |
| cognitiveLoad | Enum (.light, .moderate, .heavy, .extreme) | AI-tagged |
| classroomCourseId | String? | For synced tasks |
| classroomAssignmentId | String? | For synced tasks |
| steps | [MissionStep] | AI-decomposed, editable |
| resources | [Resource] | AI-linked |

### MissionStep
| Field | Type |
|-------|------|
| id | UUID |
| title | String |
| isCompleted | Bool |
| orderIndex | Int |
| estimatedMinutes | Int? |
| resources | [Resource] |

### Resource
| Field | Type |
|-------|------|
| id | UUID |
| title | String |
| url | URL |
| type | Enum (.video, .article, .documentation, .tool) |
| stepId | UUID? |

### FocusSession
| Field | Type |
|-------|------|
| id | UUID |
| missionId | UUID |
| startedAt | Date |
| endedAt | Date? |
| plannedMinutes | Int |
| breaksTaken | Int |
| wasCompleted | Bool |

### EnergyProfile
| Field | Type | Notes |
|-------|------|-------|
| hourOfDay | Int (0-23) | |
| dayOfWeek | Int (1-7) | |
| averageProductivity | Double (0-1) | Learned over time |
| sampleCount | Int | |

### Streak
| Field | Type |
|-------|------|
| category | Enum (.school, .work, .personal, .overall) |
| currentCount | Int |
| longestCount | Int |
| lastActiveDate | Date |
| momentumScore | Double |

### ClassroomCourse
| Field | Type |
|-------|------|
| id | String (Google's ID) |
| name | String |
| section | String? |
| lastSyncedAt | Date |
| isActive | Bool |

---

## 4. Notification & Aggression System

Four levels, each with escalating behavior:

### Gentle
- Single notification at scheduled time
- Friendly tone
- Badge count updates
- No repeat if dismissed

### Moderate
- Notifications at 24h, 6h, 1h before deadline
- Firmer tone
- Re-notifies 30 min after dismiss (up to 2x)
- Lock screen widget countdown

### Aggressive
- Notifications at 48h, 24h, 12h, 6h, 3h, 1h, 30min, 15min
- Urgent tone with progress callout
- Live Activity on Dynamic Island with countdown
- Banner overlay on app open for urgent/overdue tasks
- Escalating notification sounds

### Nuclear
- Everything from Aggressive, plus:
- Notifications every 15 minutes when overdue
- Full-screen interstitial on app open (must acknowledge)
- Anti-procrastination micro-start suggestions
- Persistent Dynamic Island with red pulsing countdown
- Morning summary prioritizes nuclear missions

### Smart Escalation
- If a task is Gentle but user keeps dismissing near deadline, the app **suggests** (never auto-escalates) upgrading: "You've dismissed this 3 times. Want to turn up the pressure?"

---

## 5. Google Classroom Integration

### Authentication
- `ASWebAuthenticationSession` for Google OAuth 2.0
- Scopes: `classroom.courses.readonly`, `classroom.coursework.me.readonly`, `classroom.student-submissions.me.readonly`
- Tokens stored in Keychain

### Sync Behavior
- Manual pull-to-refresh on Classroom tab
- Background app refresh every 2-4 hours
- On app launch if last sync > 1 hour ago

### Auto-Import Rules
- New assignments create Missions with `source: .googleClassroom`, `category: .school`, `aggressionLevel: .moderate`
- Deadline pulled from assignment due date
- Course name as label

### Conflict Resolution
- Classroom updates (deadline, description) sync to Mission
- User modifications (title, steps) are preserved
- Completed assignments in Classroom mark Mission as completed

### Scope
- Synced: courses, assignment title/description/due date/max points/status
- Not synced (v1): attachments (linked only), announcements, class stream

---

## 6. On-Device AI Engine

### Technology
- Apple Foundation Models framework (iOS 26+, requires A17 Pro+ or M1+ chip, Apple Intelligence enabled)
- Falls back gracefully: if Apple Intelligence unavailable, all AI features become manual

### Capabilities
1. **Task Decomposition**: Generate 3-8 actionable steps from mission title + description
2. **Resource Suggestions**: Generate search queries for YouTube, Google Scholar, etc. per step. User taps to open in Safari.
3. **Difficulty Fingerprinting (Task DNA)**: Tag estimated time, cognitive load, creativity needed, tools required
4. **Anti-procrastination prompts**: Contextual "just do this tiny thing" micro-starts

### Learning Loop
```
Mission created/imported
    -> AI processes title + description
    -> Generates: steps[], estimatedMinutes, cognitiveLoad, resources[]
    -> User reviews & edits AI output
    -> Over time: actual vs estimated data improves predictions
```

### Extensibility
- AI service defined as a protocol (`AIServiceProtocol`)
- Apple Intelligence is the default implementation
- Cloud providers (Claude, GPT) can be added as alternative implementations with a single-file change

---

## 7. Dashboard & Visualizations

### Pressure Radar (Dashboard top)
- Circular sonar/radar visualization
- Center = NOW. Rings outward = today, this week, this month
- Missions are blips: color-coded by category (cyan/school, magenta/work, green/personal)
- Blip size = cognitive load. Brightness = urgency (pulsing glow when critical)
- Blips move toward center as deadlines approach
- Tap blip to open mission detail
- Refined thin strokes, smooth spring animations, subtle glow — not flashy

### Today's Missions (Dashboard middle)
- Sorted by AI-suggested optimal order (energy + deadline + difficulty)
- Shows: title, time estimate, aggression indicator, step progress bar
- Swipe actions: complete, snooze, start focus session

### Momentum Strip (Dashboard bottom)
- Horizontal streak bars per category
- Current streak count with subtle flame animation when hot
- Tap to expand into full momentum wave chart

### Focus Session UI
- Full-screen dark interface, large circular timer
- Accent ring depletes as time passes
- Current mission and step displayed
- Dynamic Island shows remaining time + mission
- Adaptive breaks: shorter for light tasks, longer + movement prompts for heavy cognitive load

### Widgets
- **Small**: Next deadline countdown + streak count
- **Medium**: Mini pressure radar + top 3 upcoming missions
- **Large**: Full today's mission list with progress

### Live Activities
- **Focus session**: Timer countdown + current mission (lock screen + Dynamic Island)
- **Approaching deadline**: Countdown for nuclear/aggressive missions within 1 hour

---

## 8. Energy-Aware Scheduling

### Initial Setup (Onboarding)
- User sets: wake time, sleep time, peak hours preference (morning/afternoon/evening)

### Learning
- Refines profile using focus session data: completion speed, session abandonment, snooze frequency per hour/day
- Stored as EnergyProfile entries per hour/day combination

### Smart Scheduling
- Dashboard sorts missions by optimal order: heavy tasks during peak, light tasks during slumps
- Deadlines always override energy suggestions
- Subtle indicator: "Peak focus time" / "Low energy — try light tasks"

---

## 9. Analytics (Intel Tab)

- **Productivity heatmap**: GitHub-style contribution grid by hour and day
- **Task DNA accuracy**: AI estimates vs actual time, trending over weeks
- **Momentum waves**: Line chart of streak scores per category over time
- **Category breakdown**: Time split between school/work/personal
- All charts: smooth animations, thin lines, subtle gradients, minimalist-intense aesthetic

---

## 10. Visual Identity

- **Theme**: Dark mission control. Minimalist but intense.
- **Color palette**: Deep black/charcoal backgrounds. Neon accents used sparingly — cyan (school), magenta (work), green (personal). Subtle glow effects, no heavy saturation.
- **Typography**: SF Pro with weight variations for hierarchy. Clean, readable.
- **Animations**: Spring animations, smooth transitions, subtle pulsing for urgency. Beautiful but not flashy.
- **Philosophy**: Luxury car dashboard meets Bloomberg terminal. Clean lines, generous spacing, information-dense without feeling cluttered.

---

## 11. Project Structure

```
Command/
├── CommandApp.swift
├── Models/
│   ├── Mission.swift
│   ├── MissionStep.swift
│   ├── Resource.swift
│   ├── FocusSession.swift
│   ├── EnergyProfile.swift
│   ├── Streak.swift
│   ├── ClassroomCourse.swift
│   └── Enums.swift
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── PressureRadarView.swift
│   │   ├── TodayMissionsView.swift
│   │   └── MomentumStripView.swift
│   ├── Missions/
│   │   ├── MissionListView.swift
│   │   ├── MissionDetailView.swift
│   │   ├── MissionStepRow.swift
│   │   └── CreateMissionView.swift
│   ├── Classroom/
│   │   ├── ClassroomView.swift
│   │   ├── CourseListView.swift
│   │   └── SyncStatusView.swift
│   ├── Focus/
│   │   ├── FocusSessionView.swift
│   │   ├── FocusTimerView.swift
│   │   └── BreakView.swift
│   ├── Intel/
│   │   ├── IntelView.swift
│   │   ├── HeatmapView.swift
│   │   ├── MomentumChartView.swift
│   │   └── TaskDNAChartView.swift
│   ├── Onboarding/
│   │   └── OnboardingView.swift
│   └── Components/
│       ├── AggressionBadge.swift
│       ├── MissionCard.swift
│       ├── GlowEffect.swift
│       └── AnimatedCountdown.swift
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── MissionViewModel.swift
│   ├── ClassroomViewModel.swift
│   ├── FocusViewModel.swift
│   └── IntelViewModel.swift
├── Services/
│   ├── AIService.swift
│   ├── ClassroomService.swift
│   ├── NotificationService.swift
│   ├── EnergyService.swift
│   ├── StreakService.swift
│   └── SyncService.swift
├── Extensions/
├── Widgets/
│   ├── CommandWidgetBundle.swift
│   ├── SmallWidget.swift
│   ├── MediumWidget.swift
│   └── LargeWidget.swift
└── LiveActivity/
    ├── FocusLiveActivity.swift
    └── DeadlineLiveActivity.swift
```

---

## 12. Technical Constraints

- **Minimum iOS**: 26.0 (required for Apple Foundation Models framework)
- **Xcode**: 26+
- **Data**: SwiftData, local only, no cloud sync
- **Auth tokens**: Keychain (not SwiftData)
- **Background tasks**: BGAppRefreshTask for Classroom sync
- **Notifications**: UNUserNotificationCenter with time-interval and calendar triggers
- **Live Activities**: ActivityKit
- **Widgets**: WidgetKit with timeline providers

---

## 13. Agent Team Plan

This project is scoped for an agent team with the following division:

| Agent | Responsibility |
|-------|---------------|
| **Lead** | Coordination, integration, app entry point, tab navigation |
| **Agent 1: Models + Services** | SwiftData models, all service layer code, Google OAuth |
| **Agent 2: Dashboard + Visualizations** | Dashboard tab, pressure radar, momentum strip, all custom animations |
| **Agent 3: Missions + Focus** | Mission CRUD views, detail view, focus session UI, timer logic |
| **Agent 4: Classroom + Intel + Widgets** | Classroom tab, Intel tab charts, widget extensions, Live Activities |
| **Agent 5: Notifications** | Full aggression system, notification scheduling, escalation logic |

Each agent works on independent files with minimal merge conflicts.
