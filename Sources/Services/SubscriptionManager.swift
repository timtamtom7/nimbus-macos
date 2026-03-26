import Foundation
import StoreKit

@available(macOS 13.0, *)
public final class NimbusSubscriptionManager: ObservableObject {
    public static let shared = NimbusSubscriptionManager()
    @Published public private(set) var subscription: NimbusSubscription?
    @Published public private(set) var products: [Product] = []
    private init() {}
    public func loadProducts() async {
        do { products = try await Product.products(for: ["com.nimbus.macos.pro.monthly","com.nimbus.macos.pro.yearly","com.nimbus.macos.team.monthly","com.nimbus.macos.team.yearly"]) }
        catch { print("Failed to load products") }
    }
    public func canAccess(_ feature: NimbusFeature) -> Bool {
        guard let sub = subscription else { return false }
        switch feature {
        case .widgets: return sub.tier != .free
        case .shortcuts: return sub.tier != .free
        case .team: return sub.tier == .team
        }
    }
    public func updateStatus() async {
        var found: NimbusSubscription = NimbusSubscription(tier: .free)
        for await result in Transaction.currentEntitlements {
            do {
                let t = try checkVerified(result)
                if t.productID.contains("team") { found = NimbusSubscription(tier: .team, status: t.revocationDate == nil ? "active" : "expired") }
                else if t.productID.contains("pro") { found = NimbusSubscription(tier: .pro, status: t.revocationDate == nil ? "active" : "expired") }
            } catch { continue }
        }
        await MainActor.run { self.subscription = found }
    }
    public func restore() async throws { try await AppStore.sync(); await updateStatus() }
    private func checkVerified<T>(_ r: VerificationResult<T>) throws -> T { switch r { case .unverified: throw NSError(domain: "Nimbus", code: -1); case .verified(let s): return s } }
}
public enum NimbusFeature { case widgets, shortcuts, team }
