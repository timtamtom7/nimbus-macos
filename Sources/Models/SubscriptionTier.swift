import Foundation

/// R16: Subscription tiers for Nimbus
public enum NimbusSubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case team = "team"
    
    public var displayName: String {
        switch self { case .free: return "Free"; case .pro: return "Nimbus Pro"; case .team: return "Nimbus Team" }
    }
    public var monthlyPrice: Decimal? {
        switch self { case .free: return nil; case .pro: return 4.99; case .team: return 9.99 }
    }
    public var maxNotebooks: Int? {
        switch self { case .free: return 5; case .pro: return nil; case .team: return nil }
    }
    public var supportsWidgets: Bool { self != .free }
    public var supportsShortcuts: Bool { self != .free }
    public var supportsTeam: Bool { self == .team }
    public var trialDays: Int { self == .free ? 0 : 14 }
}

public struct NimbusSubscription: Codable {
    public let tier: NimbusSubscriptionTier
    public let status: String
    public let expiresAt: Date?
    public init(tier: NimbusSubscriptionTier, status: String = "active", expiresAt: Date? = nil) {
        self.tier = tier; self.status = status; self.expiresAt = expiresAt
    }
}
