//
//  SinkOrSwimApp.swift
//  Sink or Swim
//
//  Created by Brayden Weismantel on 17/3/2026.
//

import SwiftUI

@main
struct SinkOrSwimApp: App {
    @State private var storeManager = StoreManager()
    @State private var adManager = AdManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
                .environment(adManager)
                .task {
                    if StoreManager.adsFeatureAvailable {
                        await storeManager.loadProducts()
                        await storeManager.checkCurrentEntitlements()
                    }
                }
                .task {
                    if StoreManager.adsFeatureAvailable {
                        await storeManager.listenForTransactions()
                    }
                }
        }
    }
}
