import SwiftUI

struct ProgressScreen: View {
    @EnvironmentObject private var store: LiftLogStore

    var stats: [ExerciseStat] {
        Array(store.exerciseStats().prefix(6))
    }

    var body: some View {
        AppScreen(title: "Progress") {
            if store.hasActiveWorkout {
                ActiveWorkoutBanner {
                    store.resumeActiveWorkout()
                }
            }

            if stats.isEmpty {
                EmptyStateCard(
                    title: "Progress gets useful after your first few workouts",
                    subtitle: "LiftLog will surface your best weights and recent trends automatically as soon as you build a little history.",
                    systemImage: "chart.bar.fill",
                    footnote: "The more consistently you log, the easier it becomes to see if you're moving up.",
                    actionTitle: store.hasActiveWorkout ? "Continue Workout" : "Start Workout"
                ) {
                    if store.hasActiveWorkout {
                        store.resumeActiveWorkout()
                    } else {
                        store.startWorkout()
                    }
                }
            } else {
                AppCard {
                    Text("Keep showing up")
                        .font(.headline)
                    Text("The biggest win here is consistency. LiftLog keeps your last lift and best lift easy to find so your next workout feels automatic.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                AppCard {
                    Text("Personal Bests")
                        .font(.headline)
                    ForEach(stats) { stat in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(stat.name)
                                Spacer()
                                Text(store.formattedWeight(stat.maxWeight))
                                    .fontWeight(.semibold)
                            }
                            ProgressBar(value: stat.recentWeight, maxValue: max(stat.maxWeight, 1))
                            Text("Recent: \(store.formattedWeight(stat.recentWeight))")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                AppCard {
                    Text("Recent Trends")
                        .font(.headline)
                    ForEach(stats) { stat in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stat.name)
                                Text("\(stat.totalReps) total reps logged")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Text(store.formattedWeight(stat.maxWeight))
                                .foregroundStyle(AppTheme.accent)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }
}

private struct ProgressBar: View {
    let value: Double
    let maxValue: Double

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width * CGFloat(value / maxValue), 12)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.cardSecondary)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(width: width)
            }
        }
        .frame(height: 12)
    }
}
