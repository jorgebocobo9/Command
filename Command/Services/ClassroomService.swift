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
