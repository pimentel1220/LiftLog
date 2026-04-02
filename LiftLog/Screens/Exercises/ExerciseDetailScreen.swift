import SwiftUI

struct ExerciseDetailScreen: View {
    @EnvironmentObject private var store: LiftLogStore
    let exerciseID: UUID
    @State private var editedNotes = ""

    var exercise: ExerciseDefinition? {
        store.exercise(for: exerciseID)
    }

    var body: some View {
        Group {
            if let exercise {
                AppScreen(title: exercise.name) {
                    AppCard {
                        HStack {
                            CategoryPill(category: exercise.category)
                            Spacer()
                            Button {
                                store.toggleFavorite(exerciseID: exercise.id)
                            } label: {
                                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(exercise.isFavorite ? .yellow : AppTheme.textSecondary)
                            }
                        }
                        LastTimeBanner(performance: store.lastPerformance(for: exercise.id), weightUnit: store.weightUnit)
                        PRBanner(personalRecord: store.personalRecord(for: exercise.id), weightUnit: store.weightUnit)
                    }

                    AppCard {
                        Text("Setup Notes")
                            .font(.headline)
                        Text("Save seat settings, machine levels, or form reminders so the next workout feels automatic.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Seat setting, pin level, form reminders", text: Binding(
                            get: { editedNotes },
                            set: { newValue in
                                editedNotes = newValue
                                store.updateExerciseNotes(exerciseID: exercise.id, notes: newValue)
                            }
                        ), axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(AppTheme.cardSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    AppCard {
                        Text("Workout History")
                            .font(.headline)
                        let history = store.history(for: exercise.id)
                        if history.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "clock.badge.questionmark")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.accent)
                                Text("No history for this exercise yet")
                                    .font(.subheadline.weight(.semibold))
                                Text("Once you log this exercise in a workout, LiftLog will show your last lift here so it is easy to repeat or beat next time.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("This is where the app becomes especially useful for machines and repeat exercises.")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        } else {
                            ForEach(history, id: \.workout.id) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(AppFormat.shortDate(item.workout.startedAt))
                                        .font(.subheadline.weight(.semibold))
                                    Text(item.log.sets.map { "\(store.formattedWeight($0.weight)) x \($0.reps)" }.joined(separator: "   "))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                if item.workout.id != history.last?.workout.id {
                                    Divider().overlay(AppTheme.border)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    editedNotes = exercise.notes
                }
            } else {
                Text("Exercise not found")
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}
