import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var store: LiftLogStore

    var body: some View {
        AppScreen(title: "LiftLog") {
            AppCard {
                Text("A simple gym tracker that helps you remember exactly what you lifted last time.")
                    .font(.headline)

                if store.hasActiveWorkout {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(AppTheme.accent)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Workout in progress")
                                .font(.headline)
                            Text("Jump back in and keep logging.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                    Text("Your workout is already open. Jump back in and keep logging.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    PrimaryActionButton(title: "Start Workout", systemImage: "play.fill") {
                        store.startWorkout()
                    }
                    if store.recentWorkouts.first != nil {
                        SecondaryActionButton(title: "Duplicate Last Workout", systemImage: "square.on.square") {
                            store.startWorkout(copyLastWorkout: true)
                        }
                    }
                }
            }

            if let recentWorkout = store.recentWorkouts.first {
                AppCard {
                    Text("Recent Workout")
                        .font(.headline)
                    Text(AppFormat.shortDate(recentWorkout.startedAt))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\(recentWorkout.exerciseLogs.count) exercises logged")
                        .font(.subheadline)
                    ForEach(recentWorkout.exerciseLogs.prefix(3)) { log in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.exerciseName)
                                Text(log.sets.last.map { "\($0.weight == 0 ? "Bodyweight" : AppFormat.weight($0.weight)) x \($0.reps)" } ?? "No sets")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .font(.subheadline)
                    }
                }
            }

            AppCard {
                Text("Favorite Exercises")
                    .font(.headline)

                if store.favoriteExercises.isEmpty {
                    Text("Favorite a few exercises to keep them one tap away.")
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(store.favoriteExercises.prefix(4)) { exercise in
                        NavigationLink {
                            ExerciseDetailScreen(exerciseID: exercise.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .foregroundStyle(.white)
                                    Text(store.lastPerformance(for: exercise.id)?.summaryText ?? "No history yet")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            AppCard {
                Text("Quick Access")
                    .font(.headline)
                NavigationLink {
                    ExercisesScreen()
                } label: {
                    HomeShortcutRow(title: "Exercises", subtitle: "See saved lifts and last used weight")
                }

                NavigationLink {
                    HistoryScreen()
                } label: {
                    HomeShortcutRow(title: "History", subtitle: "Review past workouts by date")
                }

                NavigationLink {
                    ProgressScreen()
                } label: {
                    HomeShortcutRow(title: "Progress", subtitle: "Check personal bests and trends")
                }
            }
        }
    }
}

private struct HomeShortcutRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 2)
    }
}
