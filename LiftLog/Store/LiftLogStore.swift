import Foundation

@MainActor
final class LiftLogStore: ObservableObject {
    @Published private(set) var exercises: [ExerciseDefinition] = []
    @Published private(set) var workouts: [Workout] = []
    @Published private(set) var activeWorkout: WorkoutDraft?
    @Published private(set) var prRecords: [PRRecord] = []
    @Published var tier: AppTier = .free

    private let persistence = PersistenceController()

    init() {
        load()
    }

    var recentWorkouts: [Workout] {
        workouts.sorted { $0.startedAt > $1.startedAt }
    }

    var favoriteExercises: [ExerciseDefinition] {
        exercises.filter(\.isFavorite).sorted { $0.name < $1.name }
    }

    var sortedExercises: [ExerciseDefinition] {
        exercises.sorted { $0.name < $1.name }
    }

    func exercises(for category: ExerciseCategory) -> [ExerciseDefinition] {
        sortedExercises.filter { $0.category == category }
    }

    var hasActiveWorkout: Bool {
        activeWorkout != nil
    }

    var sortedPRRecords: [PRRecord] {
        prRecords.sorted {
            if $0.weight == $1.weight {
                return $0.date > $1.date
            }
            return $0.weight > $1.weight
        }
    }

    func startWorkout(copyLastWorkout: Bool = false) {
        if copyLastWorkout, let lastWorkout = recentWorkouts.first {
            let draftLogs = lastWorkout.exerciseLogs.map { log in
                WorkoutExerciseLog(
                    id: UUID(),
                    exerciseID: log.exerciseID,
                    exerciseName: log.exerciseName,
                    category: log.category,
                    notes: log.notes,
                    sets: log.sets.map { ExerciseSet(id: UUID(), weight: $0.weight, reps: $0.reps) }
                )
            }

            activeWorkout = WorkoutDraft(id: UUID(), startedAt: Date(), exerciseLogs: draftLogs, notes: "")
        } else {
            activeWorkout = WorkoutDraft(id: UUID(), startedAt: Date(), exerciseLogs: [], notes: "")
        }
        persist()
    }

    func discardActiveWorkout() {
        activeWorkout = nil
        persist()
    }

    func finishWorkout() {
        guard let draft = activeWorkout, !draft.exerciseLogs.isEmpty else { return }
        let workout = Workout(
            id: draft.id,
            startedAt: draft.startedAt,
            endedAt: Date(),
            exerciseLogs: draft.exerciseLogs,
            notes: draft.notes
        )
        workouts.append(workout)
        activeWorkout = nil
        persist()
    }

    func addExerciseToActiveWorkout(exercise: ExerciseDefinition) {
        guard activeWorkout != nil else { return }
        if activeWorkout?.exerciseLogs.contains(where: { $0.exerciseID == exercise.id }) == true {
            return
        }

        let defaultSet = lastPerformance(for: exercise.id)
            .map { ExerciseSet(id: UUID(), weight: $0.weight, reps: $0.reps) }
            ?? ExerciseSet.empty

        let log = WorkoutExerciseLog(
            id: UUID(),
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            category: exercise.category,
            notes: exercise.notes,
            sets: [defaultSet]
        )

        activeWorkout?.exerciseLogs.append(log)
        persist()
    }

    func createExercise(name: String, category: ExerciseCategory, notes: String, favorite: Bool = false) -> ExerciseDefinition {
        let exercise = ExerciseDefinition(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            notes: notes,
            isFavorite: favorite,
            createdAt: Date()
        )
        exercises.append(exercise)
        exercises.sort { $0.name < $1.name }
        persist()
        return exercise
    }

    func findExercise(named name: String, category: ExerciseCategory) -> ExerciseDefinition? {
        exercises.first {
            $0.category == category && $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    func ensureExercise(from template: ExerciseTemplate) -> ExerciseDefinition {
        if let existing = findExercise(named: template.name, category: template.category) {
            return existing
        }

        return createExercise(
            name: template.name,
            category: template.category,
            notes: template.starterNotes
        )
    }

    func updateExerciseNotes(exerciseID: UUID, notes: String) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[index].notes = notes

        for workoutIndex in workouts.indices {
            for logIndex in workouts[workoutIndex].exerciseLogs.indices where workouts[workoutIndex].exerciseLogs[logIndex].exerciseID == exerciseID {
                workouts[workoutIndex].exerciseLogs[logIndex].notes = notes
            }
        }

        if activeWorkout != nil {
            for logIndex in activeWorkout!.exerciseLogs.indices where activeWorkout!.exerciseLogs[logIndex].exerciseID == exerciseID {
                activeWorkout!.exerciseLogs[logIndex].notes = notes
            }
        }

        persist()
    }

    func toggleFavorite(exerciseID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[index].isFavorite.toggle()
        persist()
    }

    func addSet(to logID: UUID) {
        guard let lastSet = activeWorkoutLog(logID)?.sets.last else { return }
        mutateLog(logID) { log in
            log.sets.append(ExerciseSet(id: UUID(), weight: lastSet.weight, reps: lastSet.reps))
        }
    }

    func addEmptySet(to logID: UUID) {
        mutateLog(logID) { log in
            log.sets.append(ExerciseSet.empty)
        }
    }

    func repeatPreviousSet(for logID: UUID) {
        addSet(to: logID)
    }

    func removeSet(logID: UUID, setID: UUID) {
        mutateLog(logID) { log in
            log.sets.removeAll { $0.id == setID }
            if log.sets.isEmpty {
                log.sets = [ExerciseSet.empty]
            }
        }
    }

    func deleteExerciseFromActiveWorkout(logID: UUID) {
        activeWorkout?.exerciseLogs.removeAll { $0.id == logID }
        persist()
    }

    func updateSetWeight(logID: UUID, setID: UUID, delta: Double) {
        mutateSet(logID: logID, setID: setID) { set in
            set.weight = max(0, set.weight + delta)
        }
    }

    func updateSetReps(logID: UUID, setID: UUID, delta: Int) {
        mutateSet(logID: logID, setID: setID) { set in
            set.reps = max(1, set.reps + delta)
        }
    }

    func updateSetReps(logID: UUID, setID: UUID, to value: Int) {
        mutateSet(logID: logID, setID: setID) { set in
            set.reps = max(1, value)
        }
    }

    func updateActiveWorkoutNotes(_ notes: String) {
        activeWorkout?.notes = notes
        persist()
    }

    func addPRRecord(name: String, weight: Double, date: Date, notes: String) {
        let record = PRRecord(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            weight: max(0, weight),
            date: date,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        prRecords.append(record)
        persist()
    }

    func deletePRRecord(_ id: UUID) {
        prRecords.removeAll { $0.id == id }
        persist()
    }

    func activeWorkoutLog(_ logID: UUID) -> WorkoutExerciseLog? {
        activeWorkout?.exerciseLogs.first { $0.id == logID }
    }

    func exercise(for id: UUID) -> ExerciseDefinition? {
        exercises.first { $0.id == id }
    }

    func lastPerformance(for exerciseID: UUID) -> LastPerformance? {
        recentWorkouts.compactMap { workout in
            guard let log = workout.exerciseLogs.first(where: { $0.exerciseID == exerciseID }),
                  let set = log.sets.last else { return nil }
            return LastPerformance(weight: set.weight, reps: set.reps, date: workout.startedAt)
        }.first
    }

    func history(for exerciseID: UUID) -> [(workout: Workout, log: WorkoutExerciseLog)] {
        recentWorkouts.compactMap { workout in
            guard let log = workout.exerciseLogs.first(where: { $0.exerciseID == exerciseID }) else { return nil }
            return (workout, log)
        }
    }

    func personalBest(for exerciseID: UUID) -> Double {
        history(for: exerciseID)
            .flatMap(\.log.sets)
            .map(\.weight)
            .max() ?? 0
    }

    func personalRecord(for exerciseID: UUID) -> PersonalRecord? {
        history(for: exerciseID)
            .flatMap { item in
                item.log.sets.map { set in
                    PersonalRecord(weight: set.weight, reps: set.reps, date: item.workout.startedAt)
                }
            }
            .max { lhs, rhs in
                if lhs.weight == rhs.weight {
                    if lhs.reps == rhs.reps {
                        return lhs.date < rhs.date
                    }
                    return lhs.reps < rhs.reps
                }
                return lhs.weight < rhs.weight
            }
    }

    func exerciseStats() -> [ExerciseStat] {
        exercises.compactMap { exercise in
            let logs = history(for: exercise.id)
            guard !logs.isEmpty,
                  let personalRecord = personalRecord(for: exercise.id) else { return nil }

            let allSets = logs.flatMap(\.log.sets)
            let recentWeight = logs.first?.log.sets.last?.weight ?? 0
            return ExerciseStat(
                exerciseID: exercise.id,
                name: exercise.name,
                maxWeight: allSets.map(\.weight).max() ?? 0,
                totalReps: allSets.map(\.reps).reduce(0, +),
                recentWeight: recentWeight,
                personalRecord: personalRecord
            )
        }
        .sorted { $0.maxWeight > $1.maxWeight }
    }

    func resetWithSampleData() {
        let state = SampleData.makeState()
        exercises = state.exercises
        workouts = state.workouts
        activeWorkout = state.activeWorkout
        prRecords = state.prRecords
        tier = state.tier
        persist()
    }

    private func load() {
        let state = persistence.load() ?? SampleData.makeState()
        exercises = state.exercises
        workouts = state.workouts
        activeWorkout = state.activeWorkout
        prRecords = state.prRecords
        tier = state.tier
        persist()
    }

    private func mutateLog(_ logID: UUID, change: (inout WorkoutExerciseLog) -> Void) {
        guard var draft = activeWorkout,
              let index = draft.exerciseLogs.firstIndex(where: { $0.id == logID }) else { return }
        change(&draft.exerciseLogs[index])
        activeWorkout = draft
        persist()
    }

    private func mutateSet(logID: UUID, setID: UUID, change: (inout ExerciseSet) -> Void) {
        guard var draft = activeWorkout,
              let logIndex = draft.exerciseLogs.firstIndex(where: { $0.id == logID }),
              let setIndex = draft.exerciseLogs[logIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
        change(&draft.exerciseLogs[logIndex].sets[setIndex])
        activeWorkout = draft
        persist()
    }

    private func persist() {
        persistence.save(
            PersistedAppState(
                exercises: exercises,
                workouts: workouts,
                activeWorkout: activeWorkout,
                prRecords: prRecords,
                tier: tier
            )
        )
    }
}
