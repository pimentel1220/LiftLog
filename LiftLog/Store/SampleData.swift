import Foundation

enum SampleData {
    static func makeState() -> PersistedAppState {
        let legPress = ExerciseDefinition(id: UUID(), name: "Leg Press", category: .machines, notes: "Seat 4, feet shoulder-width.", isFavorite: true, createdAt: daysAgo(40))
        let chestPress = ExerciseDefinition(id: UUID(), name: "Chest Press", category: .machines, notes: "Seat 6. Keep shoulders down.", isFavorite: true, createdAt: daysAgo(38))
        let cableRow = ExerciseDefinition(id: UUID(), name: "Seated Cable Row", category: .cables, notes: "Use neutral grip. Pin at 7.", isFavorite: true, createdAt: daysAgo(36))
        let dumbbellCurl = ExerciseDefinition(id: UUID(), name: "Dumbbell Curl", category: .freeWeights, notes: "Slow lower. Avoid swinging.", isFavorite: false, createdAt: daysAgo(35))
        let assistedDip = ExerciseDefinition(id: UUID(), name: "Assisted Dip", category: .bodyweight, notes: "Machine level 5.", isFavorite: false, createdAt: daysAgo(30))

        let workoutOne = Workout(
            id: UUID(),
            startedAt: daysAgo(10),
            endedAt: daysAgo(10).addingTimeInterval(45 * 60),
            exerciseLogs: [
                WorkoutExerciseLog(
                    id: UUID(),
                    exerciseID: legPress.id,
                    exerciseName: legPress.name,
                    category: legPress.category,
                    notes: legPress.notes,
                    sets: [
                        ExerciseSet(id: UUID(), weight: 180, reps: 12),
                        ExerciseSet(id: UUID(), weight: 180, reps: 12),
                        ExerciseSet(id: UUID(), weight: 200, reps: 10),
                    ]
                ),
                WorkoutExerciseLog(
                    id: UUID(),
                    exerciseID: chestPress.id,
                    exerciseName: chestPress.name,
                    category: chestPress.category,
                    notes: chestPress.notes,
                    sets: [
                        ExerciseSet(id: UUID(), weight: 70, reps: 12),
                        ExerciseSet(id: UUID(), weight: 80, reps: 10),
                        ExerciseSet(id: UUID(), weight: 80, reps: 9),
                    ]
                ),
            ],
            notes: "Felt good getting back into it."
        )

        let workoutTwo = Workout(
            id: UUID(),
            startedAt: daysAgo(5),
            endedAt: daysAgo(5).addingTimeInterval(42 * 60),
            exerciseLogs: [
                WorkoutExerciseLog(
                    id: UUID(),
                    exerciseID: cableRow.id,
                    exerciseName: cableRow.name,
                    category: cableRow.category,
                    notes: cableRow.notes,
                    sets: [
                        ExerciseSet(id: UUID(), weight: 70, reps: 12),
                        ExerciseSet(id: UUID(), weight: 80, reps: 10),
                        ExerciseSet(id: UUID(), weight: 80, reps: 10),
                    ]
                ),
                WorkoutExerciseLog(
                    id: UUID(),
                    exerciseID: dumbbellCurl.id,
                    exerciseName: dumbbellCurl.name,
                    category: dumbbellCurl.category,
                    notes: dumbbellCurl.notes,
                    sets: [
                        ExerciseSet(id: UUID(), weight: 20, reps: 12),
                        ExerciseSet(id: UUID(), weight: 20, reps: 10),
                        ExerciseSet(id: UUID(), weight: 25, reps: 8),
                    ]
                ),
                WorkoutExerciseLog(
                    id: UUID(),
                    exerciseID: assistedDip.id,
                    exerciseName: assistedDip.name,
                    category: assistedDip.category,
                    notes: assistedDip.notes,
                    sets: [
                        ExerciseSet(id: UUID(), weight: 0, reps: 12),
                        ExerciseSet(id: UUID(), weight: 0, reps: 11),
                        ExerciseSet(id: UUID(), weight: 0, reps: 10),
                    ]
                ),
            ],
            notes: "Short session before work."
        )

        let workoutThree = Workout(
            id: UUID(),
            startedAt: daysAgo(2),
            endedAt: daysAgo(2).addingTimeInterval(50 * 60),
            exerciseLogs: [
                WorkoutExerciseLog(
                    id: UUID(),
                    exerciseID: legPress.id,
                    exerciseName: legPress.name,
                    category: legPress.category,
                    notes: "Seat 4, heels planted.",
                    sets: [
                        ExerciseSet(id: UUID(), weight: 200, reps: 12),
                        ExerciseSet(id: UUID(), weight: 220, reps: 10),
                        ExerciseSet(id: UUID(), weight: 220, reps: 10),
                    ]
                ),
                WorkoutExerciseLog(
                    id: UUID(),
                    exerciseID: cableRow.id,
                    exerciseName: cableRow.name,
                    category: cableRow.category,
                    notes: cableRow.notes,
                    sets: [
                        ExerciseSet(id: UUID(), weight: 80, reps: 12),
                        ExerciseSet(id: UUID(), weight: 90, reps: 10),
                        ExerciseSet(id: UUID(), weight: 90, reps: 9),
                    ]
                ),
            ],
            notes: "Added weight on leg press."
        )

        return PersistedAppState(
            exercises: [legPress, chestPress, cableRow, dumbbellCurl, assistedDip],
            workouts: [workoutOne, workoutTwo, workoutThree],
            activeWorkout: nil,
            prRecords: [
                PRRecord(id: UUID(), name: "Bench Press", weight: 185, date: daysAgo(14), notes: "Gym flat bench"),
                PRRecord(id: UUID(), name: "Deadlift", weight: 315, date: daysAgo(21), notes: "Straps off"),
                PRRecord(id: UUID(), name: "Leg Press", weight: 360, date: daysAgo(8), notes: "Full depth"),
            ],
            tier: .free
        )
    }

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}
