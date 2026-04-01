import Foundation

enum ExerciseCatalog {
    static let templates: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Leg Press", category: .machines, starterNotes: "Seat 4, feet shoulder-width."),
        ExerciseTemplate(name: "Chest Press", category: .machines, starterNotes: "Seat 6. Keep shoulders down."),
        ExerciseTemplate(name: "Shoulder Press Machine", category: .machines, starterNotes: "Seat low enough for handles at shoulder height."),
        ExerciseTemplate(name: "Lat Pulldown", category: .machines, starterNotes: "Thigh pad snug. Pull to upper chest."),
        ExerciseTemplate(name: "Seated Row Machine", category: .machines, starterNotes: "Chest tall. Neutral grip."),
        ExerciseTemplate(name: "Leg Extension", category: .machines, starterNotes: "Pad above ankles. Align knee with pivot."),
        ExerciseTemplate(name: "Hamstring Curl", category: .machines, starterNotes: "Pad just above heels."),
        ExerciseTemplate(name: "Hack Squat", category: .machines, starterNotes: "Shoulders under pads. Feet slightly forward."),
        ExerciseTemplate(name: "Smith Machine Squat", category: .machines, starterNotes: "Bar set just below shoulder height."),
        ExerciseTemplate(name: "Assisted Dip", category: .machines, starterNotes: "Machine level 5."),
        ExerciseTemplate(name: "Assisted Pull-Up", category: .machines, starterNotes: "Choose knee pad assist before stepping up."),
        ExerciseTemplate(name: "Pec Deck", category: .machines, starterNotes: "Seat so elbows line up with chest."),
        ExerciseTemplate(name: "Dumbbell Bench Press", category: .freeWeights, starterNotes: "Flat bench. Keep feet planted."),
        ExerciseTemplate(name: "Dumbbell Curl", category: .freeWeights, starterNotes: "Slow lower. Avoid swinging."),
        ExerciseTemplate(name: "Goblet Squat", category: .freeWeights, starterNotes: "Keep elbows close and chest tall."),
        ExerciseTemplate(name: "Romanian Deadlift", category: .freeWeights, starterNotes: "Soft knees. Push hips back."),
        ExerciseTemplate(name: "Barbell Bench Press", category: .freeWeights, starterNotes: "Eyes under bar. Use spotter if needed."),
        ExerciseTemplate(name: "Seated Cable Row", category: .cables, starterNotes: "Use neutral grip. Pin at 7."),
        ExerciseTemplate(name: "Cable Triceps Pushdown", category: .cables, starterNotes: "Elbows pinned by sides."),
        ExerciseTemplate(name: "Cable Lateral Raise", category: .cables, starterNotes: "Pulley low. Light weight."),
        ExerciseTemplate(name: "Cable Face Pull", category: .cables, starterNotes: "Pulley high. Pull toward eyes."),
        ExerciseTemplate(name: "Push-Up", category: .bodyweight, starterNotes: "Body in one straight line."),
        ExerciseTemplate(name: "Bodyweight Squat", category: .bodyweight, starterNotes: "Sit back and keep heels down."),
        ExerciseTemplate(name: "Walking Lunge", category: .bodyweight, starterNotes: "Long step and upright torso."),
        ExerciseTemplate(name: "Pull-Up", category: .bodyweight, starterNotes: "Full hang to chin over bar."),
    ]

    static func templates(for category: ExerciseCategory) -> [ExerciseTemplate] {
        templates.filter { $0.category == category }
    }
}
