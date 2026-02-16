import SwiftUI

struct MissionStepRow: View {
    @Bindable var step: MissionStep
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(CommandAnimations.springQuick) {
                    step.isCompleted.toggle()
                }
            } label: {
                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(step.isCompleted ? accentColor : CommandColors.textTertiary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(CommandTypography.body)
                    .foregroundStyle(step.isCompleted ? CommandColors.textTertiary : CommandColors.textPrimary)
                    .strikethrough(step.isCompleted, color: CommandColors.textTertiary)

                if let minutes = step.estimatedMinutes {
                    Text("\(minutes) min")
                        .font(CommandTypography.caption)
                        .foregroundStyle(CommandColors.textTertiary)
                }
            }

            Spacer()

            if !step.resources.isEmpty {
                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundStyle(CommandColors.textTertiary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(step.isCompleted ? CommandColors.surface.opacity(0.5) : CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
