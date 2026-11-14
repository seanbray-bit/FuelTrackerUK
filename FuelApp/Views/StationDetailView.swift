import SwiftUI
import MapKit
import CoreLocation

struct StationDetailView: View {
    let station: FuelStation
    let userLocation: CLLocation?
    // A free user may view only the selected fuel. Unpriced stations must not
    // disclose other fuels' prices via this detail screen.
    let visibleFuelType: FuelType?

    init(station: FuelStation, userLocation: CLLocation?, visibleFuelType: FuelType? = nil) {
        self.station = station
        self.userLocation = userLocation
        self.visibleFuelType = visibleFuelType
    }

    private var displayedPrices: [FuelPrice] {
        guard let visibleFuelType else { return station.prices }
        return station.prices.filter { $0.fuelType == visibleFuelType }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Map
                Map {
                    Marker(station.name, coordinate: station.coordinate)
                        .tint(.green)
                }
                .frame(height: 200)
                .cornerRadius(12)

                // Station header
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .font(.title2.bold())
                    Text(station.brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if !station.address.isEmpty {
                        Text(station.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if !station.postcode.isEmpty {
                        Text(station.postcode)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let location = userLocation {
                        Label(station.distanceText(from: location), systemImage: "car.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                    }
                }

                Divider()

                // All fuel prices
                Text("Fuel Prices")
                    .font(.headline)

                if displayedPrices.isEmpty {
                    Text("No reported prices. Fuel availability is unknown.")
                        .foregroundColor(.secondary)
                }
                ForEach(displayedPrices) { price in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(price.fuelType.rawValue)
                                .font(.system(size: 16, weight: .medium))
                            Text("per litre")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // A price feed does not confirm fuel stock.
                        Text(price.inStock == nil ? "Stock unknown" : (price.inStock == true ? "In stock" : "Out of stock"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        Text(price.formattedPrice)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(minWidth: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // Last updated
                HStack {
                    Image(systemName: "clock")
                    Text("Station listing retrieved: \(station.lastUpdated.formatted(.relative(presentation: .named)))")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Divider()

                // Directions button
                Button {
                    openInMaps()
                } label: {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Station Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: station.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = station.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
