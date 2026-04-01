import SwiftUI

struct HistoryScreen: View {
    @EnvironmentObject private var store: LiftLogStore

    var body: some View {
        AppScreen(title: "History") {
            if store.recentWorkouts.isEmpty {
                EmptyStateCard(
                    title: "No workouts yet",
                    subtitle: "Start a workout and your history will build automatically.",
                    systemImage: "clock.arrow.circlepath"
                )
            } else {
                ForEach(store.recentWorkouts) { workout in
                    NavigationLink {
                        WorkoutDetailScreen(workout: workout)
                    } label: {
                        AppCard {
                            Text(AppFormat.shortDate(workout.startedAt))
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("\(workout.exerciseLogs.count) exercises")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                            ForEach(workout.exerciseLogs.prefix(3)) { log in
                                HStack {
                                    Text(log.exerciseName)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(log.sets.last.map { "\(AppFormat.weight($0.weight)) x \($0.reps)" } ?? "")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct WorkoutDetailScreen: View {
    let workout: Workout

    var body: some View {
        AppScreen(title: AppFormat.shortDate(workout.startedAt)) {
            if !workout.notes.isEmpty {
                AppCard {
                    Text("Workout Notes")
                        .font(.headline)
                    Text(workout.notes)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            ForEach(workout.exerciseLogs) { log in
                AppCard {
                    Text(log.exerciseName)
                        .font(.headline)
                    CategoryPill(category: log.category)
                    if !log.notes.isEmpty {
                        Text(log.notes)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    ForEach(log.sets) { set in
                        HStack {
                            Text(AppFormat.weight(set.weight))
                            Spacer()
                            Text("\(set.reps) reps")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}
