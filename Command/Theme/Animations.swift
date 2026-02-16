import SwiftUI

enum CommandAnimations {
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let springQuick = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    static let slowPulse = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
}
