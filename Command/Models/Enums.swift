// Placeholder — Backend agent will replace this with full enum definitions
import Foundation

enum MissionSource: String, Codable { case manual, googleClassroom }
enum MissionCategory: String, Codable, CaseIterable { case school, work, personal }
enum MissionStatus: String, Codable { case pending, inProgress, completed, abandoned }
enum MissionPriority: String, Codable, CaseIterable { case low, medium, high, critical }
enum AggressionLevel: String, Codable, CaseIterable { case gentle, moderate, aggressive, nuclear }
enum CognitiveLoad: String, Codable, CaseIterable { case light, moderate, heavy, extreme }
enum ResourceType: String, Codable { case video, article, documentation, tool }
enum StreakCategory: String, Codable, CaseIterable { case school, work, personal, overall }
