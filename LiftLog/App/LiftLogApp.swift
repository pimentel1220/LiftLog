import SwiftUI

@main
struct LiftLogApp: App {
    @StateObject private var store = LiftLogStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
