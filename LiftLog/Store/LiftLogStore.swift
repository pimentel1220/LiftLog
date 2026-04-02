import Foundation

@MainActor
final class LiftLogStore: ObservableObject {
    @Published private(set) var exercises: [ExerciseDefinition] = []
    @Published private(set) var workouts: [Workout] = []
    @Published private(set) var activeWorkout: WorkoutDraft?
    @Published private(set) var prRecords: [PRRecord] = []
    @Published private(set) var lastSavedAt: Date?
    @Published private(set) var hasSaveError = false
    @Published private(set) var preferences = AppPreferences()
    @Published var shouldPresentActiveWorkout = false
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

    func recentExercises(for category: ExerciseCategory? = nil, limit: Int = 6) -> [ExerciseDefinition] {
        var seen = Set<UUID>()
        var results: [ExerciseDefinition] = []

        for workout in recentWorkouts {
            for log in workout.exerciseLogs {
                guard seen.insert(log.exerciseID).inserted,
                      let exercise = exercise(for: log.exerciseID) else { continue }
                if let category, exercise.category != category {
                    continue
                }
                results.append(exercise)
                if results.count >= limit {
                    return results
                }
            }
        }

        return results
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

    var syncPRsWithWorkoutsEnabled: Bool {
        preferences.syncPRsWithWorkouts
    }

    var weightUnit: WeightUnit {
        preferences.weightUnit
    }

    var quickPRWeightSuggestions: [Double] {
        switch weightUnit {
        case .pounds:
            [45, 95, 135, 185, 225]
        case .kilograms:
            [20, 40, 60, 80, 100]
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
        shouldPresentActiveWorkout = true
        persist()
    }

    func discardActiveWorkout() {
        activeWorkout = nil
        shouldPresentActiveWorkout = false
        persist()
    }

    func finishWorkout() {
        guard let draft = activeWorkout, !draft.exerciseLogs.isEmpty else { return }
        let workout = Workout(
            id: draft.id,
            startedAt: draft.startedAt,
            endedAt: Date(),
            exerciseLogs: draft.exerciseLogs,
            notes: draft.notes,
            updatedAt: Date()
        )
        workouts.append(workout)
        if preferences.syncPRsWithWorkouts {
            syncPRsFromWorkout(workout)
        }
        activeWorkout = nil
        shouldPresentActiveWorkout = false
        persist()
    }

    func addExerciseToActiveWorkout(exercise: ExerciseDefinition) {
        guard var draft = activeWorkout else { return }
        if draft.exerciseLogs.contains(where: { $0.exerciseID == exercise.id }) {
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

        draft.exerciseLogs.append(log)
        draft.updatedAt = Date()
        activeWorkout = draft
        persist()
    }

    func createExercise(name: String, category: ExerciseCategory, notes: String, favorite: Bool = false) -> ExerciseDefinition {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = findExercise(named: trimmedName, category: category) {
            return existing
        }

        let exercise = ExerciseDefinition(
            id: UUID(),
            name: trimmedName,
            category: category,
            notes: notes,
            isFavorite: favorite,
            createdAt: Date(),
            updatedAt: Date()
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
        exercises[index].updatedAt = Date()

        if var draft = activeWorkout {
            for logIndex in draft.exerciseLogs.indices where draft.exerciseLogs[logIndex].exerciseID == exerciseID {
                draft.exerciseLogs[logIndex].notes = notes
            }
            draft.updatedAt = Date()
            activeWorkout = draft
        }

        persist()
    }

    func toggleFavorite(exerciseID: UUID) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        exercises[index].isFavorite.toggle()
        exercises[index].updatedAt = Date()
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
        guard var draft = activeWorkout else { return }
        draft.exerciseLogs.removeAll { $0.id == logID }
        draft.updatedAt = Date()
        activeWorkout = draft
        persist()
    }

    func updateSetWeight(logID: UUID, setID: UUID, delta: Double) {
        mutateSet(logID: logID, setID: setID) { set in
            set.weight = max(0, set.weight + delta)
        }
    }

    func updateSetWeightDisplayDelta(logID: UUID, setID: UUID, delta: Double) {
        mutateSet(logID: logID, setID: setID) { set in
            let currentValue = weightUnit.displayWeight(fromStoredPounds: set.weight)
            let nextValue = max(0, currentValue + delta)
            set.weight = weightUnit.storedPounds(fromDisplayWeight: nextValue)
        }
    }

    func updateSetWeight(logID: UUID, setID: UUID, toDisplayValue value: Double) {
        mutateSet(logID: logID, setID: setID) { set in
            set.weight = max(0, weightUnit.storedPounds(fromDisplayWeight: value))
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
        guard var draft = activeWorkout else { return }
        draft.notes = notes
        draft.updatedAt = Date()
        activeWorkout = draft
        persist()
    }

    func addPRRecord(exerciseID: UUID? = nil, name: String, weight: Double, date: Date, notes: String) {
        let record = PRRecord(
            id: UUID(),
            exerciseID: exerciseID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            weight: max(0, weight),
            date: date,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date(),
            updatedAt: Date()
        )
        prRecords.append(record)
        persist()
    }

    func setSyncPRsWithWorkouts(_ isEnabled: Bool) {
        preferences.syncPRsWithWorkouts = isEnabled
        persist()
    }

    func setWeightUnit(_ unit: WeightUnit) {
        preferences.weightUnit = unit
        persist()
    }

    func resumeActiveWorkout() {
        guard hasActiveWorkout else { return }
        shouldPresentActiveWorkout = true
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

    func formattedWeight(_ storedPounds: Double) -> String {
        AppFormat.weight(storedPounds, unit: weightUnit)
    }

    func editableWeight(_ storedPounds: Double) -> String {
        AppFormat.editableWeight(storedPounds, unit: weightUnit)
    }

    func formattedDisplayWeight(_ value: Double) -> String {
        AppFormat.displayWeight(value, unit: weightUnit)
    }

    func formattedLastPerformance(_ performance: LastPerformance) -> String {
        "Last time: \(formattedWeight(performance.weight)) x \(performance.reps) on \(AppFormat.shortDate(performance.date))"
    }

    func lastPerformanceSummary(for exerciseID: UUID) -> String? {
        guard let performance = lastPerformance(for: exerciseID) else { return nil }
        return formattedLastPerformance(performance)
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
        preferences = state.preferences
        shouldPresentActiveWorkout = false
        tier = state.tier
        persist()
    }

    private func load() {
        let state = persistence.load() ?? SampleData.makeState()
        exercises = state.exercises
        workouts = state.workouts
        activeWorkout = state.activeWorkout
        prRecords = state.prRecords
        preferences = state.preferences
        shouldPresentActiveWorkout = false
        tier = state.tier
        persist()
    }

    private func mutateLog(_ logID: UUID, change: (inout WorkoutExerciseLog) -> Void) {
        guard var draft = activeWorkout,
              let index = draft.exerciseLogs.firstIndex(where: { $0.id == logID }) else { return }
        change(&draft.exerciseLogs[index])
        draft.updatedAt = Date()
        activeWorkout = draft
        persist()
    }

    private func mutateSet(logID: UUID, setID: UUID, change: (inout ExerciseSet) -> Void) {
        guard var draft = activeWorkout,
              let logIndex = draft.exerciseLogs.firstIndex(where: { $0.id == logID }),
              let setIndex = draft.exerciseLogs[logIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
        change(&draft.exerciseLogs[logIndex].sets[setIndex])
        draft.updatedAt = Date()
        activeWorkout = draft
        persist()
    }

    private func persist() {
        let didSave = persistence.save(
            PersistedAppState(
                exercises: exercises,
                workouts: workouts,
                activeWorkout: activeWorkout,
                prRecords: prRecords,
                tier: tier,
                preferences: preferences
            )
        )
        hasSaveError = !didSave
        if didSave {
            lastSavedAt = Date()
        }
    }

    private func syncPRsFromWorkout(_ workout: Workout) {
        for log in workout.exerciseLogs {
            guard let bestSet = log.sets.max(by: { lhs, rhs in
                if lhs.weight == rhs.weight {
                    return lhs.reps < rhs.reps
                }
                return lhs.weight < rhs.weight
            }) else { continue }

            guard let recordIndex = prRecords.firstIndex(where: {
                if let exerciseID = $0.exerciseID {
                    return exerciseID == log.exerciseID
                }
                return $0.name.caseInsensitiveCompare(log.exerciseName) == .orderedSame
            }) else { continue }

            if bestSet.weight > prRecords[recordIndex].weight {
                prRecords[recordIndex].weight = bestSet.weight
                prRecords[recordIndex].date = workout.startedAt
                prRecords[recordIndex].updatedAt = Date()
            }
        }
    }
}
