import SwiftUI

struct PressureRadarView: View {
    let missions: [Mission]
    let onMissionTap: (Mission) -> Void

    @State private var sweepAngle: Double = 0
    @State private var appeared = false

    private let ringCount = 3
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
            .glow(CommandColors.categoryColor(mission.category), radius: mission.isOverdue ? 8 : 4, intensity: urgency)
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
        let hash = mission.id.hashValue
        let angle = Double(abs(hash) % 360) * .pi / 180
        let distance = distanceFromCenter
        return CGPoint(x: distance * cos(angle), y: distance * sin(angle))
    }
}
