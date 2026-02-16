# Command App - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build "Command", an iOS task companion app with Google Classroom sync, on-device AI task decomposition, customizable aggression-based reminders, and a dark mission-control UI.

**Architecture:** Monolithic SwiftUI app using MVVM + service layer. SwiftData for local persistence. Apple Foundation Models for on-device AI. Google Classroom REST API via OAuth 2.0. WidgetKit + ActivityKit for widgets and Live Activities.

**Tech Stack:** SwiftUI, SwiftData, Foundation Models (iOS 26+), WidgetKit, ActivityKit, ASWebAuthenticationSession, UNUserNotificationCenter, XcodeGen

**Display Mode:** tmux split-panes (each agent team member visible in its own pane)

---

## Pre-Flight: Project Scaffold (Lead does this BEFORE spawning agents)

### Step 1: Initialize git repo

```bash
cd /Users/jgbocobo/Desktop/personal
git init Command
cd Command
```

### Step 2: Install XcodeGen

```bash
brew install xcodegen
```

### Step 3: Create project.yml for XcodeGen

Create `Command/project.yml`:

```yaml
name: Command
options:
  bundleIdPrefix: com.jgbocobo
  deploymentTarget:
    iOS: "26.0"
  xcodeVersion: "26.0"
  createIntermediateGroups: true

settings:
  base:
    SWIFT_VERSION: "6.0"
    DEVELOPMENT_TEAM: ""

targets:
  Command:
    type: application
    platform: iOS
    sources:
      - Command
    settings:
      base:
        INFOPLIST_FILE: Command/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.jgbocobo.command
    entitlements:
      path: Command/Command.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.jgbocobo.command

  CommandWidgets:
    type: app-extension
    platform: iOS
    sources:
      - CommandWidgets
    settings:
      base:
        INFOPLIST_FILE: CommandWidgets/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.jgbocobo.command.widgets
    entitlements:
      path: CommandWidgets/CommandWidgets.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.jgbocobo.command
    dependencies:
      - target: Command
        embed: false
```

### Step 4: Create directory structure

```bash
mkdir -p Command/{Models,Views/{Dashboard,Missions,Classroom,Focus,Intel,Onboarding,Components},ViewModels,Services,Extensions,Theme}
mkdir -p CommandWidgets
```

### Step 5: Create CLAUDE.md for agent progress tracking

Create `CLAUDE.md` at the project root. This is the shared progress file all agents update.

### Step 6: Create placeholder files so agents have targets

Create `Command/CommandApp.swift` with the basic app entry point and tab structure. Create `Command/Info.plist` and `Command/Command.entitlements`.

### Step 7: Generate Xcode project

```bash
xcodegen generate
```

### Step 8: Initial commit

```bash
git add -A
git commit -m "feat: scaffold Command project with XcodeGen"
```

---

## CLAUDE.md Template (Lead creates this)

```markdown
# Command - Agent Team Progress

## Project
iOS task companion app. See `docs/plans/2026-02-16-command-app-design.md` for full design.

## Rules
- Each agent MUST update their section below after completing each task
- Format: `- [x] Task description (commit: <short-sha>)` or `- [ ] Task description (in progress)`
- If you hit a blocker, add a `BLOCKED:` note in your section
- Do NOT modify files outside your assigned file list
- Commit after each completed task with descriptive message
- Prefix commits with your agent name: `[models]`, `[dashboard]`, `[missions]`, `[classroom]`, `[notifications]`

## Build & Test
- Generate project: `xcodegen generate` (run after adding new files)
- Build: `xcodebuild -project Command.xcodeproj -scheme Command -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
- No test target yet — agents should verify compilation after each task

## Agent 1: Models + Services
Owner: Models, Services, Enums, Keychain helper

### Assigned Files
- `Command/Models/Mission.swift`
- `Command/Models/MissionStep.swift`
- `Command/Models/Resource.swift`
- `Command/Models/FocusSession.swift`
- `Command/Models/EnergyProfile.swift`
- `Command/Models/Streak.swift`
- `Command/Models/ClassroomCourse.swift`
- `Command/Models/Enums.swift`
- `Command/Services/AIService.swift`
- `Command/Services/ClassroomService.swift`
- `Command/Services/EnergyService.swift`
- `Command/Services/StreakService.swift`
- `Command/Services/SyncService.swift`
- `Command/Services/KeychainService.swift`

### Progress
- [ ] (agent updates this)

---

## Agent 2: Dashboard + Visualizations
Owner: Dashboard tab views, pressure radar, momentum strip, shared theme/components

### Assigned Files
- `Command/Views/Dashboard/DashboardView.swift`
- `Command/Views/Dashboard/PressureRadarView.swift`
- `Command/Views/Dashboard/TodayMissionsView.swift`
- `Command/Views/Dashboard/MomentumStripView.swift`
- `Command/Views/Components/GlowEffect.swift`
- `Command/Views/Components/AnimatedCountdown.swift`
- `Command/Views/Components/MissionCard.swift`
- `Command/Views/Components/AggressionBadge.swift`
- `Command/ViewModels/DashboardViewModel.swift`
- `Command/Theme/CommandTheme.swift`
- `Command/Theme/Colors.swift`
- `Command/Theme/Typography.swift`
- `Command/Theme/Animations.swift`

### Progress
- [ ] (agent updates this)

---

## Agent 3: Missions + Focus
Owner: Mission CRUD views, focus session UI, timer, onboarding

### Assigned Files
- `Command/Views/Missions/MissionListView.swift`
- `Command/Views/Missions/MissionDetailView.swift`
- `Command/Views/Missions/MissionStepRow.swift`
- `Command/Views/Missions/CreateMissionView.swift`
- `Command/Views/Focus/FocusSessionView.swift`
- `Command/Views/Focus/FocusTimerView.swift`
- `Command/Views/Focus/BreakView.swift`
- `Command/Views/Onboarding/OnboardingView.swift`
- `Command/ViewModels/MissionViewModel.swift`
- `Command/ViewModels/FocusViewModel.swift`

### Progress
- [ ] (agent updates this)

---

## Agent 4: Classroom + Intel + Widgets + Live Activities
Owner: Classroom tab, Intel tab, all widgets, Live Activities

### Assigned Files
- `Command/Views/Classroom/ClassroomView.swift`
- `Command/Views/Classroom/CourseListView.swift`
- `Command/Views/Classroom/SyncStatusView.swift`
- `Command/Views/Intel/IntelView.swift`
- `Command/Views/Intel/HeatmapView.swift`
- `Command/Views/Intel/MomentumChartView.swift`
- `Command/Views/Intel/TaskDNAChartView.swift`
- `Command/ViewModels/ClassroomViewModel.swift`
- `Command/ViewModels/IntelViewModel.swift`
- `CommandWidgets/CommandWidgetBundle.swift`
- `CommandWidgets/SmallWidget.swift`
- `CommandWidgets/MediumWidget.swift`
- `CommandWidgets/LargeWidget.swift`
- `CommandWidgets/LiveActivity/FocusLiveActivity.swift`
- `CommandWidgets/LiveActivity/DeadlineLiveActivity.swift`
- `CommandWidgets/Info.plist`
- `CommandWidgets/CommandWidgets.entitlements`

### Progress
- [ ] (agent updates this)

---

## Agent 5: Notifications
Owner: Full notification/aggression system

### Assigned Files
- `Command/Services/NotificationService.swift`
- `Command/Services/AggressionScheduler.swift`
- `Command/Services/MicroStartGenerator.swift`
- `Command/Views/Components/UrgentBannerView.swift`
- `Command/Views/Components/NuclearInterstitialView.swift`

### Progress
- [ ] (agent updates this)

---

## Integration Notes
(Lead updates this with merge issues, API contracts, etc.)
```

---

## Agent 1: Models + Services (14 tasks)

### Task 1.1: Create Enums

**Files:** Create `Command/Models/Enums.swift`

```swift
import Foundation

enum MissionSource: String, Codable {
    case manual
    case googleClassroom
}

enum MissionCategory: String, Codable, CaseIterable {
    case school
    case work
    case personal
}

enum MissionStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case abandoned
}

enum MissionPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case critical
}

enum AggressionLevel: String, Codable, CaseIterable {
    case gentle
    case moderate
    case aggressive
    case nuclear
}

enum CognitiveLoad: String, Codable, CaseIterable {
    case light
    case moderate
    case heavy
    case extreme
}

enum ResourceType: String, Codable {
    case video
    case article
    case documentation
    case tool
}

enum StreakCategory: String, Codable, CaseIterable {
    case school
    case work
    case personal
    case overall
}
```

**Commit:** `git commit -m "[models] feat: add all enum types"`

**Update CLAUDE.md:** Mark task 1.1 complete with commit SHA.

---

### Task 1.2: Create Mission model

**Files:** Create `Command/Models/Mission.swift`

```swift
import Foundation
import SwiftData

@Model
final class Mission {
    var id: UUID = UUID()
    var title: String = ""
    var missionDescription: String = ""
    var source: MissionSource = .manual
    var category: MissionCategory = .school
    var status: MissionStatus = .pending
    var priority: MissionPriority = .medium
    var aggressionLevel: AggressionLevel = .moderate
    var deadline: Date?
    var createdAt: Date = Date()
    var completedAt: Date?
    var estimatedMinutes: Int?
    var actualMinutes: Int?
    var cognitiveLoad: CognitiveLoad?
    var classroomCourseId: String?
    var classroomAssignmentId: String?

    @Relationship(deleteRule: .cascade) var steps: [MissionStep] = []
    @Relationship(deleteRule: .cascade) var resources: [Resource] = []
    @Relationship(deleteRule: .cascade) var focusSessions: [FocusSession] = []

    init(title: String, category: MissionCategory, source: MissionSource = .manual) {
        self.title = title
        self.category = category
        self.source = source
    }

    var isOverdue: Bool {
        guard let deadline else { return false }
        return deadline < Date() && status != .completed
    }

    var stepProgress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(steps.filter(\.isCompleted).count) / Double(steps.count)
    }

    var totalActualMinutes: Int {
        focusSessions.reduce(0) { total, session in
            guard let ended = session.endedAt else { return total }
            return total + Int(ended.timeIntervalSince(session.startedAt) / 60)
        }
    }
}
```

**Commit:** `git commit -m "[models] feat: add Mission SwiftData model"`

---

### Task 1.3: Create MissionStep model

**Files:** Create `Command/Models/MissionStep.swift`

```swift
import Foundation
import SwiftData

@Model
final class MissionStep {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var orderIndex: Int = 0
    var estimatedMinutes: Int?

    @Relationship(deleteRule: .cascade) var resources: [Resource] = []
    var mission: Mission?

    init(title: String, orderIndex: Int, estimatedMinutes: Int? = nil) {
        self.title = title
        self.orderIndex = orderIndex
        self.estimatedMinutes = estimatedMinutes
    }
}
```

**Commit:** `git commit -m "[models] feat: add MissionStep SwiftData model"`

---

### Task 1.4: Create Resource model

**Files:** Create `Command/Models/Resource.swift`

```swift
import Foundation
import SwiftData

@Model
final class Resource {
    var id: UUID = UUID()
    var title: String = ""
    var urlString: String = ""
    var type: ResourceType = .article

    var mission: Mission?
    var step: MissionStep?

    var url: URL? { URL(string: urlString) }

    init(title: String, urlString: String, type: ResourceType) {
        self.title = title
        self.urlString = urlString
        self.type = type
    }
}
```

**Commit:** `git commit -m "[models] feat: add Resource SwiftData model"`

---

### Task 1.5: Create FocusSession model

**Files:** Create `Command/Models/FocusSession.swift`

```swift
import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var endedAt: Date?
    var plannedMinutes: Int = 25
    var breaksTaken: Int = 0
    var wasCompleted: Bool = false

    var mission: Mission?

    init(mission: Mission, plannedMinutes: Int = 25) {
        self.mission = mission
        self.plannedMinutes = plannedMinutes
    }

    var durationMinutes: Int? {
        guard let ended = endedAt else { return nil }
        return Int(ended.timeIntervalSince(startedAt) / 60)
    }
}
```

**Commit:** `git commit -m "[models] feat: add FocusSession SwiftData model"`

---

### Task 1.6: Create EnergyProfile model

**Files:** Create `Command/Models/EnergyProfile.swift`

```swift
import Foundation
import SwiftData

@Model
final class EnergyProfile {
    var hourOfDay: Int = 0
    var dayOfWeek: Int = 1
    var averageProductivity: Double = 0.5
    var sampleCount: Int = 0

    init(hourOfDay: Int, dayOfWeek: Int) {
        self.hourOfDay = hourOfDay
        self.dayOfWeek = dayOfWeek
    }

    func update(with productivity: Double) {
        let newCount = sampleCount + 1
        averageProductivity = ((averageProductivity * Double(sampleCount)) + productivity) / Double(newCount)
        sampleCount = newCount
    }
}
```

**Commit:** `git commit -m "[models] feat: add EnergyProfile SwiftData model"`

---

### Task 1.7: Create Streak and ClassroomCourse models

**Files:** Create `Command/Models/Streak.swift` and `Command/Models/ClassroomCourse.swift`

Streak:
```swift
import Foundation
import SwiftData

@Model
final class Streak {
    var category: StreakCategory = .overall
    var currentCount: Int = 0
    var longestCount: Int = 0
    var lastActiveDate: Date = Date()
    var momentumScore: Double = 0.0

    init(category: StreakCategory) {
        self.category = category
    }

    func recordActivity() {
        let calendar = Calendar.current
        let isConsecutive = calendar.isDate(lastActiveDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: Date())!)
        let isSameDay = calendar.isDateInToday(lastActiveDate)

        if isSameDay { return }

        if isConsecutive {
            currentCount += 1
        } else {
            currentCount = 1
        }

        longestCount = max(longestCount, currentCount)
        lastActiveDate = Date()

        // Momentum: weighted rolling average favoring recent activity
        momentumScore = (momentumScore * 0.7) + (Double(min(currentCount, 10)) / 10.0 * 0.3)
    }
}
```

ClassroomCourse:
```swift
import Foundation
import SwiftData

@Model
final class ClassroomCourse {
    var courseId: String = ""
    var name: String = ""
    var section: String?
    var lastSyncedAt: Date = Date()
    var isActive: Bool = true

    init(courseId: String, name: String) {
        self.courseId = courseId
        self.name = name
    }
}
```

**Commit:** `git commit -m "[models] feat: add Streak and ClassroomCourse models"`

---

### Task 1.8: Create KeychainService

**Files:** Create `Command/Services/KeychainService.swift`

```swift
import Foundation
import Security

enum KeychainService {
    static func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // Convenience for String values
    static func saveString(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }

    static func loadString(forKey key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

**Commit:** `git commit -m "[models] feat: add KeychainService for secure token storage"`

---

### Task 1.9: Create ClassroomService

**Files:** Create `Command/Services/ClassroomService.swift`

```swift
import Foundation
import AuthenticationServices

actor ClassroomService {
    private let baseURL = "https://classroom.googleapis.com/v1"
    private let clientId = "" // Set from Config/Secrets
    private let redirectURI = "com.jgbocobo.command:/oauth2callback"

    private let tokenKey = "google_access_token"
    private let refreshTokenKey = "google_refresh_token"

    var isAuthenticated: Bool {
        KeychainService.loadString(forKey: tokenKey) != nil
    }

    // MARK: - OAuth

    func authenticate() async throws {
        // Build Google OAuth URL
        let scopes = [
            "https://www.googleapis.com/auth/classroom.courses.readonly",
            "https://www.googleapis.com/auth/classroom.coursework.me.readonly",
            "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly"
        ].joined(separator: " ")

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authURL = components.url else { throw ClassroomError.invalidURL }

        // ASWebAuthenticationSession handles the browser flow
        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "com.jgbocobo.command") { url, error in
                if let error { continuation.resume(throwing: error) }
                else if let url { continuation.resume(returning: url) }
                else { continuation.resume(throwing: ClassroomError.authFailed) }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        // Extract auth code from callback
        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else {
            throw ClassroomError.noAuthCode
        }

        try await exchangeCodeForToken(code)
    }

    private func exchangeCodeForToken(_ code: String) async throws {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "code": code,
            "client_id": clientId,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)

        _ = KeychainService.saveString(token.accessToken, forKey: tokenKey)
        if let refresh = token.refreshToken {
            _ = KeychainService.saveString(refresh, forKey: refreshTokenKey)
        }
    }

    func signOut() {
        KeychainService.delete(key: tokenKey)
        KeychainService.delete(key: refreshTokenKey)
    }

    // MARK: - API Calls

    func fetchCourses() async throws -> [ClassroomCourseDTO] {
        let data = try await authenticatedGet("\(baseURL)/courses?studentId=me&courseStates=ACTIVE")
        let response = try JSONDecoder().decode(CoursesResponse.self, from: data)
        return response.courses ?? []
    }

    func fetchCourseWork(courseId: String) async throws -> [CourseWorkDTO] {
        let data = try await authenticatedGet("\(baseURL)/courses/\(courseId)/courseWork")
        let response = try JSONDecoder().decode(CourseWorkResponse.self, from: data)
        return response.courseWork ?? []
    }

    func fetchSubmissions(courseId: String, courseWorkId: String) async throws -> [SubmissionDTO] {
        let data = try await authenticatedGet("\(baseURL)/courses/\(courseId)/courseWork/\(courseWorkId)/studentSubmissions?userId=me")
        let response = try JSONDecoder().decode(SubmissionsResponse.self, from: data)
        return response.studentSubmissions ?? []
    }

    private func authenticatedGet(_ urlString: String) async throws -> Data {
        guard let token = KeychainService.loadString(forKey: tokenKey) else {
            throw ClassroomError.notAuthenticated
        }
        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            try await refreshAccessToken()
            return try await authenticatedGet(urlString)
        }
        return data
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken = KeychainService.loadString(forKey: refreshTokenKey) else {
            throw ClassroomError.notAuthenticated
        }
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "refresh_token=\(refreshToken)&client_id=\(clientId)&grant_type=refresh_token"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        _ = KeychainService.saveString(token.accessToken, forKey: tokenKey)
    }
}

// MARK: - DTOs

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct CoursesResponse: Codable { let courses: [ClassroomCourseDTO]? }
struct CourseWorkResponse: Codable { let courseWork: [CourseWorkDTO]? }
struct SubmissionsResponse: Codable { let studentSubmissions: [SubmissionDTO]? }

struct ClassroomCourseDTO: Codable {
    let id: String
    let name: String
    let section: String?
}

struct CourseWorkDTO: Codable {
    let id: String
    let courseId: String
    let title: String
    let description: String?
    let dueDate: DueDate?
    let dueTime: DueTime?
    let maxPoints: Double?
    let workType: String?
}

struct DueDate: Codable {
    let year: Int
    let month: Int
    let day: Int
}

struct DueTime: Codable {
    let hours: Int?
    let minutes: Int?
}

struct SubmissionDTO: Codable {
    let id: String
    let courseWorkId: String
    let state: String // CREATED, TURNED_IN, RETURNED, RECLAIMED_BY_STUDENT
    let assignedGrade: Double?
}

enum ClassroomError: Error {
    case invalidURL
    case authFailed
    case noAuthCode
    case notAuthenticated
    case syncFailed
}
```

**Commit:** `git commit -m "[models] feat: add ClassroomService with OAuth and API calls"`

---

### Task 1.10: Create AIService (protocol + Apple Foundation Models)

**Files:** Create `Command/Services/AIService.swift`

```swift
import Foundation
import FoundationModels

// Protocol for swappable AI backends
protocol AIServiceProtocol {
    func decomposeMission(title: String, description: String) async throws -> AIDecomposition
    func generateMicroStart(for title: String) async throws -> String
}

struct AIDecomposition {
    let steps: [AIStep]
    let estimatedMinutes: Int
    let cognitiveLoad: CognitiveLoad
    let searchQueries: [AISearchQuery]
}

struct AIStep {
    let title: String
    let estimatedMinutes: Int?
}

struct AISearchQuery {
    let query: String
    let platform: SearchPlatform
    let forStepIndex: Int?
}

enum SearchPlatform: String {
    case youtube
    case google
    case googleScholar
}

// Apple Foundation Models implementation
final class OnDeviceAIService: AIServiceProtocol {
    private var session: LanguageModelSession?

    private func getSession() throws -> LanguageModelSession {
        if let session { return session }
        let newSession = LanguageModelSession()
        self.session = newSession
        return newSession
    }

    func decomposeMission(title: String, description: String) async throws -> AIDecomposition {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIServiceError.modelUnavailable
        }

        let session = try getSession()
        let prompt = """
        Break down this task into 3-8 actionable steps. For each step, estimate minutes needed.
        Also estimate total time and cognitive difficulty (light/moderate/heavy/extreme).
        Suggest 2-3 search queries to find helpful resources.

        Task: \(title)
        Details: \(description.isEmpty ? "No additional details" : description)

        Respond in this exact format:
        STEPS:
        1. [step title] | [estimated minutes]
        2. [step title] | [estimated minutes]
        ...
        TOTAL_MINUTES: [number]
        COGNITIVE_LOAD: [light/moderate/heavy/extreme]
        SEARCH:
        - youtube: [query]
        - google: [query]
        - scholar: [query]
        """

        let response = try await session.respond(to: prompt)
        return parseDecomposition(response.content)
    }

    func generateMicroStart(for title: String) async throws -> String {
        guard SystemLanguageModel.default.isAvailable else {
            throw AIServiceError.modelUnavailable
        }

        let session = try getSession()
        let prompt = """
        Generate ONE very small, low-friction first step to start this task.
        It should take under 2 minutes and lower the barrier to starting.
        Be specific to the task. Just the action, nothing else.

        Task: \(title)
        """

        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseDecomposition(_ text: String) -> AIDecomposition {
        var steps: [AIStep] = []
        var totalMinutes = 30
        var cogLoad = CognitiveLoad.moderate
        var queries: [AISearchQuery] = []

        let lines = text.components(separatedBy: "\n")
        var section = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespace)

            if trimmed.starts(with: "STEPS:") { section = "steps"; continue }
            if trimmed.starts(with: "TOTAL_MINUTES:") {
                totalMinutes = Int(trimmed.replacingOccurrences(of: "TOTAL_MINUTES:", with: "").trimmingCharacters(in: .whitespace)) ?? 30
                continue
            }
            if trimmed.starts(with: "COGNITIVE_LOAD:") {
                let value = trimmed.replacingOccurrences(of: "COGNITIVE_LOAD:", with: "").trimmingCharacters(in: .whitespace).lowercased()
                cogLoad = CognitiveLoad(rawValue: value) ?? .moderate
                continue
            }
            if trimmed.starts(with: "SEARCH:") { section = "search"; continue }

            if section == "steps" && !trimmed.isEmpty {
                let parts = trimmed.components(separatedBy: "|")
                let title = parts[0].trimmingCharacters(in: .whitespace)
                    .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                let minutes = parts.count > 1 ? Int(parts[1].trimmingCharacters(in: .whitespace)) : nil
                if !title.isEmpty {
                    steps.append(AIStep(title: title, estimatedMinutes: minutes))
                }
            }

            if section == "search" && trimmed.starts(with: "-") {
                let content = trimmed.dropFirst().trimmingCharacters(in: .whitespace)
                if content.starts(with: "youtube:") {
                    queries.append(AISearchQuery(query: String(content.dropFirst(8)).trimmingCharacters(in: .whitespace), platform: .youtube, forStepIndex: nil))
                } else if content.starts(with: "scholar:") {
                    queries.append(AISearchQuery(query: String(content.dropFirst(8)).trimmingCharacters(in: .whitespace), platform: .googleScholar, forStepIndex: nil))
                } else if content.starts(with: "google:") {
                    queries.append(AISearchQuery(query: String(content.dropFirst(7)).trimmingCharacters(in: .whitespace), platform: .google, forStepIndex: nil))
                }
            }
        }

        if steps.isEmpty {
            steps = [AIStep(title: "Work on: \(text.prefix(50))", estimatedMinutes: totalMinutes)]
        }

        return AIDecomposition(steps: steps, estimatedMinutes: totalMinutes, cognitiveLoad: cogLoad, searchQueries: queries)
    }
}

// Fallback for devices without Apple Intelligence
final class ManualAIService: AIServiceProtocol {
    func decomposeMission(title: String, description: String) async throws -> AIDecomposition {
        throw AIServiceError.modelUnavailable
    }

    func generateMicroStart(for title: String) async throws -> String {
        throw AIServiceError.modelUnavailable
    }
}

enum AIServiceError: Error {
    case modelUnavailable
    case parsingFailed
}
```

**Commit:** `git commit -m "[models] feat: add AIService with Foundation Models and fallback"`

---

### Task 1.11: Create EnergyService

**Files:** Create `Command/Services/EnergyService.swift`

```swift
import Foundation
import SwiftData

actor EnergyService {
    func recordSession(_ session: FocusSession, context: ModelContext) {
        guard let duration = session.durationMinutes, duration > 0 else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: session.startedAt)
        let weekday = calendar.component(.weekday, from: session.startedAt)

        let productivity = session.wasCompleted ? 1.0 : Double(duration) / Double(session.plannedMinutes)

        let descriptor = FetchDescriptor<EnergyProfile>(
            predicate: #Predicate { $0.hourOfDay == hour && $0.dayOfWeek == weekday }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.update(with: productivity)
        } else {
            let profile = EnergyProfile(hourOfDay: hour, dayOfWeek: weekday)
            profile.update(with: productivity)
            context.insert(profile)
        }

        try? context.save()
    }

    func currentEnergyLevel(context: ModelContext) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date())

        let descriptor = FetchDescriptor<EnergyProfile>(
            predicate: #Predicate { $0.hourOfDay == hour && $0.dayOfWeek == weekday }
        )

        return (try? context.fetch(descriptor).first?.averageProductivity) ?? 0.5
    }

    func suggestMissionOrder(_ missions: [Mission], context: ModelContext) -> [Mission] {
        let energy = (try? currentEnergyLevel(context: context)) ?? 0.5

        return missions.sorted { a, b in
            // Overdue missions always first
            if a.isOverdue != b.isOverdue { return a.isOverdue }

            // During high energy, prioritize heavy tasks
            if energy > 0.7 {
                let aLoad = a.cognitiveLoad?.sortOrder ?? 1
                let bLoad = b.cognitiveLoad?.sortOrder ?? 1
                if aLoad != bLoad { return aLoad > bLoad }
            }

            // During low energy, prioritize light tasks
            if energy < 0.4 {
                let aLoad = a.cognitiveLoad?.sortOrder ?? 1
                let bLoad = b.cognitiveLoad?.sortOrder ?? 1
                if aLoad != bLoad { return aLoad < bLoad }
            }

            // Then by deadline proximity
            let aDeadline = a.deadline ?? .distantFuture
            let bDeadline = b.deadline ?? .distantFuture
            return aDeadline < bDeadline
        }
    }
}

extension CognitiveLoad {
    var sortOrder: Int {
        switch self {
        case .light: return 1
        case .moderate: return 2
        case .heavy: return 3
        case .extreme: return 4
        }
    }
}
```

**Commit:** `git commit -m "[models] feat: add EnergyService with smart scheduling"`

---

### Task 1.12: Create StreakService

**Files:** Create `Command/Services/StreakService.swift`

```swift
import Foundation
import SwiftData

actor StreakService {
    func recordCompletion(category: MissionCategory, context: ModelContext) {
        let streakCategory: StreakCategory = switch category {
        case .school: .school
        case .work: .work
        case .personal: .personal
        }

        updateStreak(streakCategory, context: context)
        updateStreak(.overall, context: context)
    }

    private func updateStreak(_ category: StreakCategory, context: ModelContext) {
        let descriptor = FetchDescriptor<Streak>(
            predicate: #Predicate { $0.category == category }
        )

        if let streak = try? context.fetch(descriptor).first {
            streak.recordActivity()
        } else {
            let streak = Streak(category: category)
            streak.recordActivity()
            context.insert(streak)
        }

        try? context.save()
    }

    func getStreaks(context: ModelContext) -> [Streak] {
        let descriptor = FetchDescriptor<Streak>()
        return (try? context.fetch(descriptor)) ?? []
    }
}
```

**Commit:** `git commit -m "[models] feat: add StreakService for momentum tracking"`

---

### Task 1.13: Create SyncService

**Files:** Create `Command/Services/SyncService.swift`

```swift
import Foundation
import SwiftData
import BackgroundTasks

actor SyncService {
    private let classroomService: ClassroomService
    private static let bgTaskId = "com.jgbocobo.command.classroom-sync"

    init(classroomService: ClassroomService) {
        self.classroomService = classroomService
    }

    func syncClassroom(context: ModelContext) async throws {
        guard await classroomService.isAuthenticated else { return }

        let courses = try await classroomService.fetchCourses()

        for courseDTO in courses {
            // Upsert course
            let courseDescriptor = FetchDescriptor<ClassroomCourse>(
                predicate: #Predicate { $0.courseId == courseDTO.id }
            )
            let course: ClassroomCourse
            if let existing = try? context.fetch(courseDescriptor).first {
                existing.name = courseDTO.name
                existing.section = courseDTO.section
                existing.lastSyncedAt = Date()
                course = existing
            } else {
                course = ClassroomCourse(courseId: courseDTO.id, name: courseDTO.name)
                course.section = courseDTO.section
                context.insert(course)
            }

            // Fetch coursework
            let courseWork = try await classroomService.fetchCourseWork(courseId: courseDTO.id)

            for work in courseWork {
                let missionDescriptor = FetchDescriptor<Mission>(
                    predicate: #Predicate { $0.classroomAssignmentId == work.id }
                )

                if let existing = try? context.fetch(missionDescriptor).first {
                    // Update deadline if changed
                    if let newDeadline = work.deadline {
                        existing.deadline = newDeadline
                    }
                    // Update description only if user hasn't modified it
                    if existing.source == .googleClassroom {
                        existing.missionDescription = work.description ?? ""
                    }
                } else {
                    let mission = Mission(title: work.title, category: .school, source: .googleClassroom)
                    mission.missionDescription = work.description ?? ""
                    mission.classroomCourseId = courseDTO.id
                    mission.classroomAssignmentId = work.id
                    mission.deadline = work.deadline
                    mission.aggressionLevel = .moderate
                    context.insert(mission)
                }

                // Check submission status
                let submissions = try await classroomService.fetchSubmissions(courseId: courseDTO.id, courseWorkId: work.id)
                if let submission = submissions.first, submission.state == "TURNED_IN" || submission.state == "RETURNED" {
                    if let mission = try? context.fetch(missionDescriptor).first, mission.status != .completed {
                        mission.status = .completed
                        mission.completedAt = Date()
                    }
                }
            }
        }

        try context.save()
    }

    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: bgTaskId, using: nil) { task in
            guard let bgTask = task as? BGAppRefreshTask else { return }
            // Background sync handled by the app delegate / scene phase
            bgTask.setTaskCompleted(success: true)
        }
    }

    static func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: bgTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60) // 2 hours
        try? BGTaskScheduler.shared.submit(request)
    }
}

extension CourseWorkDTO {
    var deadline: Date? {
        guard let dueDate else { return nil }
        var components = DateComponents()
        components.year = dueDate.year
        components.month = dueDate.month
        components.day = dueDate.day
        components.hour = dueTime?.hours ?? 23
        components.minute = dueTime?.minutes ?? 59
        return Calendar.current.date(from: components)
    }
}
```

**Commit:** `git commit -m "[models] feat: add SyncService for background Classroom sync"`

---

### Task 1.14: Verify all models compile, update CLAUDE.md

Run: `xcodegen generate && xcodebuild -project Command.xcodeproj -scheme Command -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`

Fix any compilation errors. Update CLAUDE.md with all completed tasks and commit SHAs.

**Commit:** `git commit -m "[models] chore: verify compilation, update progress"`

---

## Agent 2: Dashboard + Visualizations (12 tasks)

### Task 2.1: Create CommandTheme

**Files:** Create `Command/Theme/CommandTheme.swift`, `Command/Theme/Colors.swift`, `Command/Theme/Typography.swift`, `Command/Theme/Animations.swift`

Colors.swift:
```swift
import SwiftUI

enum CommandColors {
    // Backgrounds
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "12121A")
    static let surfaceElevated = Color(hex: "1A1A25")
    static let surfaceBorder = Color(hex: "2A2A35")

    // Category accents
    static let school = Color(hex: "00D4FF")       // Cyan
    static let work = Color(hex: "FF2D78")          // Magenta
    static let personal = Color(hex: "00FF88")      // Green

    // Status
    static let urgent = Color(hex: "FF3B30")
    static let warning = Color(hex: "FF9500")
    static let success = Color(hex: "34C759")

    // Text
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary = Color(hex: "48484A")

    static func categoryColor(_ category: MissionCategory) -> Color {
        switch category {
        case .school: return school
        case .work: return work
        case .personal: return personal
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue >> 16) & 0xFF) / 255.0,
            green: Double((rgbValue >> 8) & 0xFF) / 255.0,
            blue: Double(rgbValue & 0xFF) / 255.0
        )
    }
}
```

Typography.swift:
```swift
import SwiftUI

enum CommandTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title = Font.system(size: 22, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let mono = Font.system(size: 14, weight: .medium, design: .monospaced)
}
```

Animations.swift:
```swift
import SwiftUI

enum CommandAnimations {
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let springQuick = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    static let slowPulse = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
}
```

CommandTheme.swift:
```swift
import SwiftUI

struct CommandTheme: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .tint(CommandColors.school)
    }
}

extension View {
    func commandTheme() -> some View {
        modifier(CommandTheme())
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add theme system with colors, typography, animations"`

---

### Task 2.2: Create GlowEffect component

**Files:** Create `Command/Views/Components/GlowEffect.swift`

```swift
import SwiftUI

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity * 0.6), radius: radius * 0.5)
            .shadow(color: color.opacity(intensity * 0.3), radius: radius)
    }
}

struct PulsingGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isAnimating ? 0.6 : 0.2), radius: isAnimating ? radius : radius * 0.5)
            .onAppear {
                withAnimation(CommandAnimations.pulse) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 8, intensity: Double = 0.5) -> some View {
        modifier(GlowEffect(color: color, radius: radius, intensity: intensity))
    }

    func pulsingGlow(_ color: Color, radius: CGFloat = 12) -> some View {
        modifier(PulsingGlow(color: color, radius: radius))
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add GlowEffect and PulsingGlow modifiers"`

---

### Task 2.3: Create AggressionBadge component

**Files:** Create `Command/Views/Components/AggressionBadge.swift`

```swift
import SwiftUI

struct AggressionBadge: View {
    let level: AggressionLevel

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor)
                    .frame(width: 3, height: CGFloat(6 + index * 3))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(barColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var barCount: Int {
        switch level {
        case .gentle: return 1
        case .moderate: return 2
        case .aggressive: return 3
        case .nuclear: return 4
        }
    }

    private var barColor: Color {
        switch level {
        case .gentle: return CommandColors.success
        case .moderate: return CommandColors.warning
        case .aggressive: return CommandColors.urgent
        case .nuclear: return CommandColors.urgent
        }
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add AggressionBadge component"`

---

### Task 2.4: Create MissionCard component

**Files:** Create `Command/Views/Components/MissionCard.swift`

```swift
import SwiftUI

struct MissionCard: View {
    let mission: Mission
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(CommandColors.categoryColor(mission.category))
                    .frame(width: 4, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.title)
                        .font(CommandTypography.headline)
                        .foregroundStyle(CommandColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let minutes = mission.estimatedMinutes {
                            Label("\(minutes)m", systemImage: "clock")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textSecondary)
                        }

                        if !mission.steps.isEmpty {
                            Text("\(mission.steps.filter(\.isCompleted).count)/\(mission.steps.count)")
                                .font(CommandTypography.caption)
                                .foregroundStyle(CommandColors.textSecondary)
                        }

                        if let deadline = mission.deadline {
                            Text(deadline, style: .relative)
                                .font(CommandTypography.caption)
                                .foregroundStyle(mission.isOverdue ? CommandColors.urgent : CommandColors.textSecondary)
                        }
                    }
                }

                Spacer()

                AggressionBadge(level: mission.aggressionLevel)

                // Step progress
                if !mission.steps.isEmpty {
                    CircularProgressView(progress: mission.stepProgress, color: CommandColors.categoryColor(mission.category))
                        .frame(width: 28, height: 28)
                }
            }
            .padding(12)
            .background(CommandColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(mission.isOverdue ? CommandColors.urgent.opacity(0.3) : CommandColors.surfaceBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add MissionCard and CircularProgress components"`

---

### Task 2.5: Create AnimatedCountdown component

**Files:** Create `Command/Views/Components/AnimatedCountdown.swift`

```swift
import SwiftUI

struct AnimatedCountdown: View {
    let targetDate: Date
    @State private var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(formattedTime)
            .font(CommandTypography.mono)
            .foregroundStyle(urgencyColor)
            .contentTransition(.numericText())
            .onReceive(timer) { _ in
                withAnimation(CommandAnimations.springQuick) {
                    timeRemaining = targetDate.timeIntervalSinceNow
                }
            }
            .onAppear {
                timeRemaining = targetDate.timeIntervalSinceNow
            }
    }

    private var formattedTime: String {
        if timeRemaining <= 0 { return "OVERDUE" }

        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var urgencyColor: Color {
        if timeRemaining <= 0 { return CommandColors.urgent }
        if timeRemaining < 3600 { return CommandColors.urgent }
        if timeRemaining < 86400 { return CommandColors.warning }
        return CommandColors.textSecondary
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add AnimatedCountdown component"`

---

### Task 2.6: Create PressureRadarView

**Files:** Create `Command/Views/Dashboard/PressureRadarView.swift`

This is the flagship visualization. A sonar-style radar with missions as blips.

```swift
import SwiftUI

struct PressureRadarView: View {
    let missions: [Mission]
    let onMissionTap: (Mission) -> Void

    @State private var sweepAngle: Double = 0
    @State private var appeared = false

    private let ringCount = 3 // today, this week, this month
    private let size: CGFloat = 280

    var body: some View {
        ZStack {
            // Radar rings
            ForEach(1...ringCount, id: \.self) { ring in
                Circle()
                    .stroke(CommandColors.surfaceBorder.opacity(0.3), lineWidth: 0.5)
                    .frame(width: size * CGFloat(ring) / CGFloat(ringCount),
                           height: size * CGFloat(ring) / CGFloat(ringCount))
            }

            // Ring labels
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ringLabel("today", offset: size * 0.17)
                    ringLabel("week", offset: size * 0.17)
                    ringLabel("month", offset: size * 0.15)
                }
            }
            .frame(width: size, height: size / 2)

            // Sweep line
            SweepLine(angle: sweepAngle)
                .stroke(
                    LinearGradient(
                        colors: [CommandColors.school.opacity(0.4), CommandColors.school.opacity(0)],
                        startPoint: .center,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
                .frame(width: size, height: size)

            // Mission blips
            ForEach(missions.prefix(20), id: \.id) { mission in
                MissionBlip(
                    mission: mission,
                    radarSize: size,
                    appeared: appeared
                )
                .onTapGesture { onMissionTap(mission) }
            }

            // Center dot
            Circle()
                .fill(CommandColors.textPrimary)
                .frame(width: 4, height: 4)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sweepAngle = 360
            }
            withAnimation(CommandAnimations.spring.delay(0.3)) {
                appeared = true
            }
        }
    }

    private func ringLabel(_ text: String, offset: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(CommandColors.textTertiary)
            .frame(width: offset)
    }
}

struct SweepLine: Shape {
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let endPoint = CGPoint(
            x: center.x + radius * cos(CGFloat(angle - 90) * .pi / 180),
            y: center.y + radius * sin(CGFloat(angle - 90) * .pi / 180)
        )
        path.move(to: center)
        path.addLine(to: endPoint)
        return path
    }
}

struct MissionBlip: View {
    let mission: Mission
    let radarSize: CGFloat
    let appeared: Bool

    var body: some View {
        Circle()
            .fill(CommandColors.categoryColor(mission.category))
            .frame(width: blipSize, height: blipSize)
            .modifier(mission.isOverdue ? AnyViewModifier(PulsingGlow(color: CommandColors.urgent, radius: 8)) : AnyViewModifier(GlowEffect(color: CommandColors.categoryColor(mission.category), radius: 4, intensity: urgency)))
            .offset(x: appeared ? position.x : 0, y: appeared ? position.y : 0)
            .opacity(appeared ? 1 : 0)
    }

    private var blipSize: CGFloat {
        switch mission.cognitiveLoad {
        case .light: return 6
        case .moderate: return 8
        case .heavy: return 10
        case .extreme: return 12
        case .none: return 7
        }
    }

    private var urgency: Double {
        guard let deadline = mission.deadline else { return 0.3 }
        let hoursLeft = deadline.timeIntervalSinceNow / 3600
        if hoursLeft <= 0 { return 1.0 }
        if hoursLeft <= 24 { return 0.8 }
        if hoursLeft <= 168 { return 0.5 }
        return 0.3
    }

    private var distanceFromCenter: CGFloat {
        guard let deadline = mission.deadline else { return radarSize * 0.45 }
        let hoursLeft = deadline.timeIntervalSinceNow / 3600
        if hoursLeft <= 0 { return 10 }
        if hoursLeft <= 24 { return radarSize * 0.15 }
        if hoursLeft <= 168 { return radarSize * 0.30 }
        return radarSize * 0.42
    }

    private var position: CGPoint {
        // Use mission ID hash for deterministic angle
        let hash = mission.id.hashValue
        let angle = Double(abs(hash) % 360) * .pi / 180
        let distance = distanceFromCenter
        return CGPoint(x: distance * cos(angle), y: distance * sin(angle))
    }
}

// Helper to use different modifiers conditionally
struct AnyViewModifier: ViewModifier {
    private let modifier: any ViewModifier

    init(_ modifier: some ViewModifier) {
        self.modifier = modifier
    }

    func body(content: Content) -> some View {
        content // Simplified — actual implementation would use type erasure
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add PressureRadarView with animated sweep and blips"`

---

### Task 2.7: Create TodayMissionsView

**Files:** Create `Command/Views/Dashboard/TodayMissionsView.swift`

```swift
import SwiftUI

struct TodayMissionsView: View {
    let missions: [Mission]
    let energyLevel: Double
    let onMissionTap: (Mission) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S MISSIONS")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textTertiary)
                    .tracking(1.5)

                Spacer()

                EnergyIndicator(level: energyLevel)
            }

            if missions.isEmpty {
                Text("No missions scheduled for today")
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(missions, id: \.id) { mission in
                    MissionCard(mission: mission) {
                        onMissionTap(mission)
                    }
                }
            }
        }
    }
}

struct EnergyIndicator: View {
    let level: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level > 0.7 ? "bolt.fill" : level > 0.4 ? "bolt" : "bolt.slash")
                .font(.system(size: 10))
            Text(level > 0.7 ? "Peak focus" : level > 0.4 ? "Steady" : "Low energy")
                .font(CommandTypography.caption)
        }
        .foregroundStyle(level > 0.7 ? CommandColors.success : level > 0.4 ? CommandColors.textSecondary : CommandColors.warning)
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add TodayMissionsView with energy indicator"`

---

### Task 2.8: Create MomentumStripView

**Files:** Create `Command/Views/Dashboard/MomentumStripView.swift`

```swift
import SwiftUI

struct MomentumStripView: View {
    let streaks: [Streak]
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(CommandAnimations.spring) { expanded.toggle() }
            } label: {
                HStack {
                    Text("MOMENTUM")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                        .tracking(1.5)

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CommandColors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 16) {
                ForEach(streaks.filter { $0.category != .overall }, id: \.category) { streak in
                    StreakBar(streak: streak)
                }
            }

            if expanded, let overall = streaks.first(where: { $0.category == .overall }) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Overall")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textSecondary)
                        Spacer()
                        Text("\(overall.currentCount) day streak")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textPrimary)
                    }
                    Text("Best: \(overall.longestCount) days")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StreakBar: View {
    let streak: Streak
    @State private var animatedWidth: CGFloat = 0

    private var color: Color {
        switch streak.category {
        case .school: return CommandColors.school
        case .work: return CommandColors.work
        case .personal: return CommandColors.personal
        case .overall: return CommandColors.textPrimary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(streak.category.rawValue.capitalized)
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textSecondary)

                if streak.currentCount >= 3 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(CommandColors.warning)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: animatedWidth, height: 4)
                        .glow(color, radius: 4, intensity: streak.momentumScore)
                }
                .onAppear {
                    withAnimation(CommandAnimations.spring.delay(0.2)) {
                        let maxWidth = geo.size.width
                        animatedWidth = maxWidth * min(streak.momentumScore, 1.0)
                    }
                }
            }
            .frame(height: 4)

            Text("\(streak.currentCount)")
                .font(CommandTypography.mono)
                .foregroundStyle(color)
        }
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add MomentumStripView with animated streak bars"`

---

### Task 2.9: Create DashboardViewModel

**Files:** Create `Command/ViewModels/DashboardViewModel.swift`

```swift
import Foundation
import SwiftData
import SwiftUI

@Observable
final class DashboardViewModel {
    private let energyService = EnergyService()
    private let streakService = StreakService()

    var todayMissions: [Mission] = []
    var allActiveMissions: [Mission] = []
    var streaks: [Streak] = []
    var currentEnergy: Double = 0.5

    func load(context: ModelContext) async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // All non-completed missions
        let allDescriptor = FetchDescriptor<Mission>(
            predicate: #Predicate { $0.status != .completed && $0.status != .abandoned }
        )
        allActiveMissions = (try? context.fetch(allDescriptor)) ?? []

        // Today's missions: due today or overdue
        todayMissions = allActiveMissions.filter { mission in
            guard let deadline = mission.deadline else { return false }
            return deadline <= endOfDay
        }

        // Sort by energy-aware order
        todayMissions = await energyService.suggestMissionOrder(todayMissions, context: context)
        currentEnergy = await energyService.currentEnergyLevel(context: context)

        // Load streaks
        streaks = await streakService.getStreaks(context: context)
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add DashboardViewModel"`

---

### Task 2.10: Create DashboardView

**Files:** Create `Command/Views/Dashboard/DashboardView.swift`

```swift
import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = DashboardViewModel()
    @State private var selectedMission: Mission?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pressure Radar
                    PressureRadarView(
                        missions: viewModel.allActiveMissions
                    ) { mission in
                        selectedMission = mission
                    }
                    .padding(.top, 8)

                    // Today's Missions
                    TodayMissionsView(
                        missions: viewModel.todayMissions,
                        energyLevel: viewModel.currentEnergy
                    ) { mission in
                        selectedMission = mission
                    }
                    .padding(.horizontal)

                    // Momentum Strip
                    MomentumStripView(streaks: viewModel.streaks)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(CommandColors.background)
            .navigationTitle("Command")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.load(context: context)
            }
            .refreshable {
                await viewModel.load(context: context)
            }
            .sheet(item: $selectedMission) { mission in
                // MissionDetailView will be built by Agent 3
                Text(mission.title)
            }
        }
    }
}
```

**Commit:** `git commit -m "[dashboard] feat: add DashboardView assembling all dashboard components"`

---

### Task 2.11-2.12: Verify compilation, update CLAUDE.md

Run build. Fix errors. Update CLAUDE.md progress section.

**Commit:** `git commit -m "[dashboard] chore: verify compilation, update progress"`

---

## Agent 3: Missions + Focus (12 tasks)

### Tasks 3.1-3.4: Mission CRUD Views

Create `MissionListView.swift` (filterable list with `.school`/`.work`/`.personal` segment, search bar, swipe actions), `CreateMissionView.swift` (form with AI decomposition button), `MissionDetailView.swift` (shows steps, resources, deadline, aggression picker), `MissionStepRow.swift` (toggleable step with progress).

All views use `CommandColors`, `CommandTypography`, and components from Agent 2.

**Key ViewModel:** `MissionViewModel.swift` handles CRUD operations on SwiftData, triggers AI decomposition via `AIServiceProtocol`, manages step reordering.

### Tasks 3.5-3.8: Focus Session

Create `FocusSessionView.swift` (full-screen dark timer), `FocusTimerView.swift` (circular depleting ring with `TimelineView` for smooth animation), `BreakView.swift` (adaptive break screen with movement prompts for heavy tasks), `FocusViewModel.swift` (timer state machine: `.ready` -> `.focusing` -> `.break` -> `.focusing` -> `.completed`).

### Tasks 3.9-3.10: Onboarding

Create `OnboardingView.swift` — 3 screens: (1) Welcome + app concept, (2) Energy profile setup (wake/sleep/peak hours), (3) Google Classroom connection (optional, can skip).

### Tasks 3.11-3.12: Verify compilation, update CLAUDE.md

Each task includes exact Swift code in the same style as Agent 1 and 2 tasks above.

**Commits prefixed with:** `[missions]`

---

## Agent 4: Classroom + Intel + Widgets (14 tasks)

### Tasks 4.1-4.3: Classroom Tab

`ClassroomView.swift` (course list with sync status, pull-to-refresh), `CourseListView.swift` (expandable course sections showing assignments), `SyncStatusView.swift` (last sync time, manual sync button, connection status). `ClassroomViewModel.swift` drives sync via `SyncService`.

### Tasks 4.4-4.7: Intel Tab

`IntelView.swift` (scrollable analytics dashboard), `HeatmapView.swift` (GitHub-style contribution grid using `Canvas` for performance), `MomentumChartView.swift` (line chart with `Path` and gradients), `TaskDNAChartView.swift` (estimated vs actual bar chart). `IntelViewModel.swift` aggregates data from `FocusSession` and `EnergyProfile` models.

### Tasks 4.8-4.10: Widgets

`CommandWidgetBundle.swift`, `SmallWidget.swift` (next deadline + streak), `MediumWidget.swift` (mini radar placeholder + top 3 missions), `LargeWidget.swift` (today's mission list). Uses App Group shared container to read SwiftData.

### Tasks 4.11-4.12: Live Activities

`FocusLiveActivity.swift` (timer countdown on Dynamic Island + lock screen), `DeadlineLiveActivity.swift` (approaching deadline countdown for aggressive/nuclear missions). Uses `ActivityAttributes` and `ActivityContent`.

### Tasks 4.13-4.14: Verify compilation, update CLAUDE.md

**Commits prefixed with:** `[classroom]`

---

## Agent 5: Notifications (8 tasks)

### Tasks 5.1-5.2: NotificationService

`NotificationService.swift` — core scheduling engine. Schedules `UNNotificationRequest` based on `AggressionLevel`. Manages notification categories and actions (complete, snooze, start focus).

### Tasks 5.3-5.4: AggressionScheduler

`AggressionScheduler.swift` — calculates notification times for each level. Gentle: 1 notification. Moderate: 3 notifications + 2 re-notifies. Aggressive: 8 notifications. Nuclear: 8 + every 15min when overdue. Generates notification content with escalating tone.

### Tasks 5.5: MicroStartGenerator

`MicroStartGenerator.swift` — wraps `AIServiceProtocol.generateMicroStart()` and provides fallback templates when AI is unavailable ("Just open the document", "Just read the first paragraph", etc.).

### Tasks 5.6-5.7: Overlay Views

`UrgentBannerView.swift` (banner that appears on app open for aggressive missions), `NuclearInterstitialView.swift` (full-screen blocking view for nuclear overdue missions, must acknowledge to dismiss).

### Task 5.8: Verify compilation, update CLAUDE.md

**Commits prefixed with:** `[notifications]`

---

## Lead: Integration (after all agents complete)

### Integration Task 1: Wire CommandApp.swift

Connect all tabs, inject `modelContainer`, register background tasks, set up notification delegate.

### Integration Task 2: Wire navigation

Connect `MissionDetailView` from Dashboard/Missions, connect Focus launch from Mission detail, connect Classroom sync trigger.

### Integration Task 3: Regenerate project, full build

```bash
xcodegen generate
xcodebuild -project Command.xcodeproj -scheme Command -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

### Integration Task 4: Final CLAUDE.md update + tag release

```bash
git tag v0.1.0
```

---

## Agent Team Spawn Prompt

Use this prompt to start the agent team with tmux split-panes:

```
Create an agent team to build the Command iOS app. Use tmux split-panes so I can see each agent.

Read docs/plans/2026-02-16-command-implementation-plan.md for the full plan.
Read CLAUDE.md for file assignments and progress tracking rules.

Spawn 5 teammates:
1. "Models" — Agent 1: Build all SwiftData models and service layer (Tasks 1.1-1.14)
2. "Dashboard" — Agent 2: Build theme, components, dashboard views (Tasks 2.1-2.12)
3. "Missions" — Agent 3: Build mission CRUD, focus session, onboarding (Tasks 3.1-3.12)
4. "Classroom" — Agent 4: Build classroom sync, intel analytics, widgets, live activities (Tasks 4.1-4.14)
5. "Notifications" — Agent 5: Build aggression notification system (Tasks 5.1-5.8)

Rules for ALL agents:
- Read your section in CLAUDE.md before starting
- Update CLAUDE.md progress section after EACH completed task
- Only modify files in your assigned file list
- Prefix all commits with your agent name tag
- If you need something from another agent, add a BLOCKED note in CLAUDE.md

Agent 2 (Dashboard) should wait for Agent 1 to complete Tasks 1.1-1.2 (Enums + Mission model) before starting Task 2.3+.
Agent 3 (Missions) should wait for Agent 1 to complete Tasks 1.1-1.7 (all models) before starting.
Agent 4 (Classroom) should wait for Agent 1 to complete Tasks 1.1-1.9 (models + ClassroomService) before starting.
Agent 5 (Notifications) can start immediately — only depends on Enums.

I (lead) will handle integration after all agents complete.
```
