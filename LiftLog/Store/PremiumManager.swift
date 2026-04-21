import Foundation

@MainActor
final class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    enum UnlockType: String, CaseIterable {
        case none
        case betaReward
        case purchase
        case adUnlock

        var displayName: String {
            switch self {
            case .none:
                "Free"
            case .betaReward:
                "Beta Premium"
            case .purchase:
                "Premium"
            case .adUnlock:
                "Ad Unlock"
            }
        }
    }

    private enum Keys {
        static let premiumUnlockType = "premiumUnlockType"
        static let hasShownBetaRewardMessage = "hasShownBetaRewardMessage"
    }

    @Published private(set) var unlockType: UnlockType
    @Published var shouldShowBetaRewardMessage = false

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        unlockType = UnlockType(rawValue: defaults.string(forKey: Keys.premiumUnlockType) ?? UnlockType.none.rawValue) ?? .none
    }

    func isTestFlightBuild() -> Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }

    func grantBetaRewardIfEligible() {
        guard isTestFlightBuild() else { return }

        let currentType = unlockType
        guard currentType == .none else { return }

        setUnlockType(.betaReward)

        if !defaults.bool(forKey: Keys.hasShownBetaRewardMessage) {
            shouldShowBetaRewardMessage = true
        }
    }

    func hasPremiumAccess() -> Bool {
        let type = defaults.string(forKey: Keys.premiumUnlockType)
        return type == UnlockType.betaReward.rawValue ||
            type == UnlockType.purchase.rawValue ||
            type == UnlockType.adUnlock.rawValue
    }

    func markBetaRewardMessageShown() {
        defaults.set(true, forKey: Keys.hasShownBetaRewardMessage)
        shouldShowBetaRewardMessage = false
    }

    func setPurchasedPremium() {
        setUnlockType(.purchase)
    }

    func setAdUnlockPremium() {
        setUnlockType(.adUnlock)
    }

    private func setUnlockType(_ type: UnlockType) {
        defaults.set(type.rawValue, forKey: Keys.premiumUnlockType)
        unlockType = type
    }
}
