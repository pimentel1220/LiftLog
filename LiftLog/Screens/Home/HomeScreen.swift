import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var store: LiftLogStore

    var body: some View {
        AppScreen(title: "LiftLog") {
            AppCard {
                Text("A simple gym tracker that helps you remember exactly what you lifted last time.")
                    .font(.headline)
                PrimaryActionButton(title: "Start Workout", systemImage: "play.fill") {
                    store.startWorkout()
                }
                if store.hasActiveWorkout {
                    SecondaryActionButton(title: "Continue Last Workout", systemImage: "arrow.clockwise") {
                    }
                } else {
                    SecondaryActionButton(title: "Duplicate Last Workout", systemImage: "square.on.square") {
                        store.startWorkout(copyLastWorkout: true)
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
                            Text(log.exerciseName)
                            Spacer()
                            Text(log.sets.last.map { "\($0.reps) reps" } ?? "")
                                .foregroundStyle(AppTheme.textSecondary)
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
                NavigationLink("View History", destination: HistoryScreen())
                    .foregroundStyle(AppTheme.accent)
                NavigationLink("View Exercises", destination: ExercisesScreen())
                    .foregroundStyle(AppTheme.accent)
                NavigationLink("View Progress", destination: ProgressScreen())
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}
