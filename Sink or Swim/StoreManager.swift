//
//  StoreManager.swift
//  Swim or Sink
//

import StoreKit

@Observable
class StoreManager {
    private(set) var isAdsRemoved: Bool = false
    private(set) var product: Product? = nil
    private(set) var purchaseState: PurchaseState = .idle

    static let productID = "com.sinkorswim.removeads"
    private static let userDefaultsKey = "adsRemoved"

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)
    }

    init() {
        isAdsRemoved = UserDefaults.standard.bool(forKey: Self.userDefaultsKey)
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase() async throws {
        guard let product else { return }
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                updatePurchaseStatus(true)
                purchaseState = .purchased
                await transaction.finish()
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            throw error
        }
    }

    func restorePurchases() async {
        purchaseState = .purchasing
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
            if isAdsRemoved {
                purchaseState = .purchased
            } else {
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed("Restore failed")
        }
    }

    func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.productID {
                    updatePurchaseStatus(transaction.revocationDate == nil)
                }
                await transaction.finish()
            }
        }
    }

    func checkCurrentEntitlements() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.productID {
                    updatePurchaseStatus(transaction.revocationDate == nil)
                    found = true
                }
            }
        }
        if !found {
            updatePurchaseStatus(false)
        }
    }

    private func updatePurchaseStatus(_ purchased: Bool) {
        isAdsRemoved = purchased
        UserDefaults.standard.set(purchased, forKey: Self.userDefaultsKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
