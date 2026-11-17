import SwiftUI
import MapKit

struct StationMapView: View {
    @ObservedObject var viewModel: FuelViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var subscriptionManager: SubscriptionManager

    // Keep only the stable ID; the selected station's prices can change on refresh.
    @State private var selectedStationID: StationSelection?
    @State private var showPaywall = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Native Map selection could bypass the paywall's Button handler.
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    let sorted = viewModel.sortedStations(from: locationManager.userLocation)
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, station in
                        let price = station.price(for: viewModel.selectedFuelType)
                        // sortedStations places all priced stations ahead of unpriced ones.
                        let pricedRank: Int? = price == nil ? nil : index + 1
                        let unlocked = viewModel.canViewReportedPrice(
                            for: station,
                            pricedRank: pricedRank,
                            isSubscribed: subscriptionManager.isSubscribed
                        )
                        let title = !unlocked
                            ? "Price locked"
                            : (price.map { "Reported \($0.formattedPrice)" } ?? "Price unavailable")
                        Annotation(title, coordinate: station.coordinate) {
                            Button {
                                if unlocked {
                                    selectedStationID = StationSelection(id: station.id)
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(!unlocked ? Color.orange : (price == nil ? Color.gray : ((pricedRank ?? 4) <= 3 ? Color.green : Color.orange)))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: unlocked ? "fuelpump.fill" : "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                !unlocked
                                ? "\(station.name), reported price locked"
                                : "\(station.name), \(price.map { "reported \($0.formattedPrice)" } ?? "price unavailable")"
                            )
                            .accessibilityHint(unlocked ? "Opens station details" : "Opens subscription options")
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                Picker("Fuel Type", selection: $viewModel.selectedFuelType) {
                    ForEach(FuelType.allCases) { type in
                        Text(type.shortName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Map")
            .sheet(item: $selectedStationID) { selection in
                // Observe live station data and subscription status INSIDE the sheet:
                // a retained FuelStation snapshot could show stale or locked prices.
                StationDetailDestination(
                    stationID: selection.id,
                    viewModel: viewModel,
                    locationManager: locationManager,
                    subscriptionManager: subscriptionManager,
                    onDismiss: { selectedStationID = nil }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscriptionManager: subscriptionManager)
            }
        }
    }
}


private struct StationSelection: Identifiable {
    let id: String
}

// This separate observed view recomputes entitlement, price and details whenever
// the live station list, selected fuel or StoreKit entitlement changes.
// Shared list/map destination: observe current station ID, selected fuel and
// entitlement while the detail is visible. A captured FuelStation isn't trusted.
struct StationDetailDestination: View {
    let stationID: String
    @ObservedObject var viewModel: FuelViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    // Map presents a sheet with Done; list navigation supplies nil and uses Back.
    let onDismiss: (() -> Void)?

    var body: some View {
        let sorted = viewModel.sortedStations(from: locationManager.userLocation)
        if let index = sorted.firstIndex(where: { $0.id == stationID }) {
            let currentStation = sorted[index]
            let pricedRank: Int? = currentStation.price(for: viewModel.selectedFuelType) == nil ? nil : index + 1

            if viewModel.canViewReportedPrice(
                for: currentStation,
                pricedRank: pricedRank,
                isSubscribed: subscriptionManager.isSubscribed
            ) {
                if let onDismiss {
                    NavigationStack {
                        currentDetail(for: currentStation)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done", action: onDismiss)
                                }
                            }
                    }
                } else {
                    currentDetail(for: currentStation)
                }
            } else {
                // A station can become locked after rank/price/entitlement updates.
                PaywallView(subscriptionManager: subscriptionManager)
            }
        } else {
            VStack(spacing: 12) {
                Text("Station results have changed. Select a station again.")
                    .multilineTextAlignment(.center)
                if let onDismiss {
                    Button("Done", action: onDismiss)
                }
            }
            .padding()
        }
    }

    private func currentDetail(for station: FuelStation) -> some View {
        StationDetailView(
            station: station,
            userLocation: locationManager.userLocation,
            visibleFuelType: subscriptionManager.isSubscribed ? nil : viewModel.selectedFuelType
        )
    }
}

extension FuelStation: Hashable {
    static func == (lhs: FuelStation, rhs: FuelStation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
