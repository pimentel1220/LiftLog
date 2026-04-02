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
                    Text("Your first workout takes about 30 seconds to start. Add one exercise, log a set, and LiftLog will remember it for next time.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    if store.recentWorkouts.first != nil {
                        SecondaryActionButton(title: "Duplicate Last Workout", systemImage: "square.on.square") {
                            store.startWorkout(copyLastWorkout: true)
                        }
                    }
                }
            }

            if store.recentWorkouts.isEmpty {
                EmptyStateCard(
                    title: "Ready for your first workout",
                    subtitle: "Start with one exercise, log the weight and reps, and LiftLog will keep your last lift easy to find next time.",
                    systemImage: "sparkles",
                    footnote: "Good first picks: Leg Press, Chest Press, Lat Pulldown, or Dumbbell Bench.",
                    actionTitle: store.hasActiveWorkout ? "Continue Workout" : "Start First Workout"
                ) {
                    if !store.hasActiveWorkout {
                        store.startWorkout()
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
                    Text("Tip: open any exercise and tap the star so your usual machines stay easy to reach.")
                        .font(.caption)
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
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsScreen()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}
