import SwiftUI

struct ExercisesScreen: View {
    @EnvironmentObject private var store: LiftLogStore
    @State private var searchText = ""

    var filteredExercises: [ExerciseDefinition] {
        if searchText.isEmpty { return store.sortedExercises }
        return store.sortedExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        AppScreen(title: "Exercises") {
            if store.hasActiveWorkout {
                ActiveWorkoutBanner {
                    store.resumeActiveWorkout()
                }
            }

            if filteredExercises.isEmpty {
                if store.sortedExercises.isEmpty {
                    EmptyStateCard(
                        title: "Your exercise list builds as you log",
                        subtitle: "Start a workout, add an exercise, and LiftLog will keep it here with your last lift and setup notes.",
                        systemImage: "dumbbell",
                        footnote: "This becomes your easy-to-scan reference list for machines, cables, free weights, and bodyweight movements.",
                        actionTitle: store.hasActiveWorkout ? "Continue Workout" : "Start Workout"
                    ) {
                        if store.hasActiveWorkout {
                            store.resumeActiveWorkout()
                        } else {
                            store.startWorkout()
                        }
                    }
                } else {
                    EmptyStateCard(
                        title: "No exercises found",
                        subtitle: "Try a different search to find an exercise already in your list.",
                        systemImage: "magnifyingglass"
                    )
                }
            } else {
                ForEach(filteredExercises) { exercise in
                    NavigationLink {
                        ExerciseDetailScreen(exerciseID: exercise.id)
                    } label: {
                        AppCard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    CategoryPill(category: exercise.category)
                                    Text(store.exerciseSummary(for: exercise))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                if exercise.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
    }
}
