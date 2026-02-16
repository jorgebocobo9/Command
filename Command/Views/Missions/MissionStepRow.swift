import SwiftUI
import SwiftData

struct MissionStepRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var step: MissionStep
    let index: Int
    let accentColor: Color
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            // Step number / check
            Button {
                Haptic.selection()
                withAnimation(CommandAnimations.springQuick) {
                    step.isCompleted.toggle()
                    try? context.save()
                }
            } label: {
                ZStack {
                    if step.isCompleted {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accentColor)
                    } else {
                        Circle()
                            .stroke(CommandColors.surfaceBorder, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(CommandColors.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)

            // Step content
            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(CommandTypography.body)
                    .foregroundStyle(step.isCompleted ? CommandColors.textTertiary : CommandColors.textPrimary)
                    .strikethrough(step.isCompleted, color: CommandColors.textTertiary.opacity(0.5))
                    .lineLimit(2)

                if let minutes = step.estimatedMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text("\(minutes) min")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(CommandColors.textTertiary)
                }
            }

            Spacer(minLength: 4)

            if !step.resources.isEmpty {
                Image(systemName: "paperclip")
                    .font(.system(size: 11))
                    .foregroundStyle(CommandColors.textTertiary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(step.isCompleted ? CommandColors.surface.opacity(0.4) : Color.clear)
    }
}
