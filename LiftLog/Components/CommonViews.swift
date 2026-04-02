import SwiftUI

struct AppScreen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(title)
    }
}

struct AppCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.accent)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.cardSecondary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct LastTimeBanner: View {
    let performance: LastPerformance?
    var weightUnit: WeightUnit = .pounds

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(AppTheme.accent)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Last time")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(lastTimeText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var lastTimeText: String {
        guard let performance else { return "No previous workout yet" }
        return "\(AppFormat.weight(performance.weight, unit: weightUnit)) x \(performance.reps) on \(AppFormat.shortDate(performance.date))"
    }
}

struct CategoryPill: View {
    let category: ExerciseCategory

    var body: some View {
        Label(category.rawValue, systemImage: category.iconName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.accentMuted)
            .foregroundStyle(AppTheme.accent)
            .clipShape(Capsule())
    }
}

struct PRBanner: View {
    let personalRecord: PersonalRecord?
    var weightUnit: WeightUnit = .pounds

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("PR")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                if let personalRecord {
                    Text("\(AppFormat.weight(personalRecord.weight, unit: weightUnit)) x \(personalRecord.reps)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Best weight on \(AppFormat.shortDate(personalRecord.date))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("No PR yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.16), AppTheme.cardSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var footnote: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.accent)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                if let footnote, !footnote.isEmpty {
                    Text(footnote)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                if let actionTitle, let action {
                    PrimaryActionButton(title: actionTitle, systemImage: "arrow.right") {
                        action()
                    }
                }
            }
        }
    }
}

struct ActiveWorkoutBanner: View {
    @EnvironmentObject private var store: LiftLogStore
    let action: () -> Void

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(AppTheme.accent)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout in progress")
                        .font(.headline)
                    Text(resumeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
            }

            PrimaryActionButton(title: "Continue Workout", systemImage: "arrow.clockwise") {
                action()
            }
        }
    }

    private var resumeSubtitle: String {
        guard let activeWorkout = store.activeWorkout else {
            return "Your current workout is still open. Jump back in anytime and keep logging."
        }

        let exerciseCount = activeWorkout.exerciseLogs.count
        let exerciseText = exerciseCount == 0 ? "No exercises yet" : "\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s") logged"
        return "\(exerciseText) since \(AppFormat.shortTime(activeWorkout.startedAt))."
    }
}
