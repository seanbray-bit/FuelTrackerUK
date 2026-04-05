import SwiftUI

struct ContentView: View {
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
    }
}
