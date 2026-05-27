//
//  AdManager.swift
//  Swim or Sink
//
//  Placeholder ad system. Replace with real AdMob integration when ready.
//

import SwiftUI

@Observable
class AdManager {
    var showingInterstitial: Bool = false
    private(set) var deathCount: Int = 0
    private let interstitialFrequency = 3

    func recordDeath() {
        deathCount += 1
    }

    func shouldShowInterstitial() -> Bool {
        deathCount > 0 && deathCount % interstitialFrequency == 0
    }

    func dismissInterstitial() {
        showingInterstitial = false
    }
}

// MARK: - Placeholder Banner Ad
/// Replace this with a real GADBannerView UIViewRepresentable when AdMob is configured
struct PlaceholderBannerAd: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.7))
            HStack(spacing: 8) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                Text("AD")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(height: 50)
    }
}

// MARK: - Placeholder Interstitial Ad
/// Replace this with a real GADInterstitialAd presentation when AdMob is configured
struct PlaceholderInterstitialAd: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.4))

                    Text("ADVERTISEMENT")
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))

                    Text("Real ads will appear here\nwhen AdMob is configured")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button(action: onDismiss) {
                    Text("CLOSE")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.white.opacity(0.35), lineWidth: 1.5)
                        )
                }

                Spacer().frame(height: 40)
            }
        }
    }
}
