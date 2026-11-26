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
                    if locationManager.canUseLocation { UserAnnotation() }
                    let sorted = viewModel.sortedStations(from: locationManager.userLocation)
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, station in
                        let price = station.price(for: viewModel.selectedFuelType)
                        // sortedStations places all priced stations ahead of unpriced ones.
                        let pricedRank: Int? = price == nil ? nil : index + 1
                        let unlocked = viewModel.canViewReportedPrice(
                            for: station,
                            pricedRank: pricedRank,
                            isSubscribed: subscriptionManager.canRevealPremium
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
                            .accessibilityHint(unlocked ? "Opens station details" : "Opens information about restoring an existing subscription")
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Fuel Type", selection: $viewModel.selectedFuelType) {
                        ForEach(FuelType.allCases) { type in
                            Text(type.shortName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Map pins from a previous area must not appear current during a lookup.
                    if locationManager.lookupLocation == nil {
                        LocationLookupStatusView(locationManager: locationManager)
                            .padding(10)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    } else if viewModel.isLoading && viewModel.stations.isEmpty {
                        ProgressView("Finding nearby stations…")
                            .padding(10)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    } else if viewModel.isLoading {
                        Label(
                            "Updating nearby stations — showing previous locations until the search finishes.",
                            systemImage: "arrow.clockwise"
                        )
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    }

                    if locationManager.lookupLocation != nil, let error = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Station update incomplete", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.semibold))
                            Text(viewModel.stations.isEmpty ? error : "Showing previously loaded station locations. \(error)")
                                .font(.footnote)
                            Button("Retry station update") {
                                if let location = locationManager.lookupLocation {
                                    Task { await viewModel.fetchStations(near: location, locationManager: locationManager) }
                                }
                            }
                            .buttonStyle(.bordered)
                            .accessibilityHint("Tries to load the latest nearby station locations.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityElement(children: .contain)
                    } else if locationManager.lookupLocation != nil, !viewModel.isLoading, viewModel.stations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            if viewModel.lastRefreshed != nil {
                                Text("No nearby fuel stations found.")
                            }
                            Button("Search nearby stations") {
                                if let location = locationManager.lookupLocation {
                                    Task { await viewModel.fetchStations(near: location, locationManager: locationManager) }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .font(.footnote)
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
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
        if locationManager.lookupLocation == nil {
            VStack(spacing: 12) {
                LocationLookupStatusView(locationManager: locationManager)
                if let onDismiss {
                    Button("Done", action: onDismiss)
                }
            }
            .padding()
        } else if let index = sorted.firstIndex(where: { $0.id == stationID }) {
            let currentStation = sorted[index]
            let pricedRank: Int? = currentStation.price(for: viewModel.selectedFuelType) == nil ? nil : index + 1

            if viewModel.canViewReportedPrice(
                for: currentStation,
                pricedRank: pricedRank,
                isSubscribed: subscriptionManager.canRevealPremium
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
            userLocation: locationManager.lookupLocation,
            visibleFuelType: subscriptionManager.canRevealPremium ? nil : viewModel.selectedFuelType,
            retainedSearchMessage: viewModel.isLoading
                ? "Updating nearby stations — showing a previously loaded station."
                : viewModel.errorMessage.map { "Showing a previously loaded station. \($0)" },
            retrySearch: viewModel.isLoading ? nil : {
                guard let location = locationManager.lookupLocation else { return }
                Task { await viewModel.fetchStations(near: location, locationManager: locationManager) }
            }
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
