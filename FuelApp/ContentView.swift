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
                Label("Stations", systemImage: "fuelpump.fill")
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
            // Covers a location fix that was already available before this view appeared.
            if let location = locationManager.lookupLocation,
               let reservationID = viewModel.reserveLocationRefreshIfNeeded(for: location) {
                Task { await viewModel.fetchStations(near: location, locationReservationID: reservationID, locationManager: locationManager) }
            }
        }
        // Keep relocation refresh at the tab root so it also works while Map is visible.
        .onChange(of: locationManager.userLocation) { _, newLocation in
            guard locationManager.canUseLocation, let location = newLocation,
                  let reservationID = viewModel.reserveLocationRefreshIfNeeded(for: location) else { return }
            Task { await viewModel.fetchStations(near: location, locationReservationID: reservationID, locationManager: locationManager) }
        }
        .onReceive(locationManager.$authorizationStatus) { status in
            if !LocationManager.isAuthorized(status) {
                viewModel.invalidateLocationSearch()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            locationManager.synchronizeAuthorization()
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
