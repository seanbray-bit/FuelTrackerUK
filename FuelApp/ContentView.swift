import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel = FuelViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some View {
        TabView {
            StationListView(
                viewModel: viewModel,
                locationManager: locationManager,
                subscriptionManager: subscriptionManager
            )
            .tabItem {
                Label("Cheapest", systemImage: "fuelpump.fill")
            }

            StationMapView(
                viewModel: viewModel,
                locationManager: locationManager,
                subscriptionManager: subscriptionManager
            )
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
        }
        .tint(.green)
        .onAppear {
            viewModel.startAutoRefresh(locationManager: locationManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            // Reconcile verified StoreKit entitlements on foreground entry;
            // Transaction.updates alone cannot be relied upon for expiry/revocation.
            // Preserve StoreKit's current-entitlement treatment of grace periods.
            // Publish the pending state before creating an asynchronous task,
            // so a previously paid user cannot see locked prices on resume.
            let checkID = subscriptionManager.beginEntitlementRevalidation()
            Task {
                await subscriptionManager.completeEntitlementRevalidation(for: checkID)
            }
        }
    }
}
