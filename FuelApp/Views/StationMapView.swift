import SwiftUI
import MapKit

struct StationMapView: View {
    @ObservedObject var viewModel: FuelViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var subscriptionManager: SubscriptionManager

    @State private var selectedStation: FuelStation?
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
                                    selectedStation = station
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
            .sheet(item: $selectedStation) { station in
                // Re-check entitlement and rank at the detail boundary.
                let sorted = viewModel.sortedStations(from: locationManager.userLocation)
                if let index = sorted.firstIndex(where: { $0.id == station.id }) {
                    let pricedRank: Int? = station.price(for: viewModel.selectedFuelType) == nil ? nil : index + 1
                    if viewModel.canViewReportedPrice(
                        for: station,
                        pricedRank: pricedRank,
                        isSubscribed: subscriptionManager.isSubscribed
                    ) {
                        NavigationStack {
                            StationDetailView(
                                station: station,
                                userLocation: locationManager.userLocation,
                                visibleFuelType: subscriptionManager.isSubscribed ? nil : viewModel.selectedFuelType
                            )
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") { selectedStation = nil }
                                }
                            }
                        }
                        .presentationDetents([.medium, .large])
                    } else {
                        PaywallView(subscriptionManager: subscriptionManager)
                    }
                } else {
                    Text("Station results have changed. Select a station again.")
                        .padding()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscriptionManager: subscriptionManager)
            }
        }
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
