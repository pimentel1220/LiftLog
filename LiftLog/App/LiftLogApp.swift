import SwiftUI

@main
struct LiftLogApp: App {
    @StateObject private var store = LiftLogStore()
    @StateObject private var premiumManager = PremiumManager.shared

    init() {
        PremiumManager.shared.grantBetaRewardIfEligible()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(premiumManager)
                .preferredColorScheme(.dark)
        }
    }
}
