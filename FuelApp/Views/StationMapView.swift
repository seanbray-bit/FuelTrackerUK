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
                Map(position: $cameraPosition, selection: $selectedStation) {
                    UserAnnotation()

                    let sorted = viewModel.sortedStations(from: locationManager.userLocation)

                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, station in
                        let rank = index + 1
                        if let price = station.price(for: viewModel.selectedFuelType) {
                            Annotation(price.formattedPrice, coordinate: station.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(rank <= 3 ? Color.green : Color.orange)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "fuelpump.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                                .onTapGesture {
                                    selectedStation = station
                                }
                            }
                            .tag(station)
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }

                // Fuel type picker overlay
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
                NavigationStack {
                    StationDetailView(
                        station: station,
                        userLocation: locationManager.userLocation
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                selectedStation = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
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
