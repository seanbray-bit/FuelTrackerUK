import SwiftUI
import MapKit
import CoreLocation

struct StationDetailView: View {
    let station: FuelStation
    let userLocation: CLLocation?

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

                ForEach(station.prices) { price in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(price.fuelType.rawValue)
                                .font(.system(size: 16, weight: .medium))
                            Text("per litre")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Stock status
                        HStack(spacing: 4) {
                            Circle()
                                .fill(price.inStock ? Color.green : Color.red)
                                .frame(width: 10, height: 10)
                            Text(price.inStock ? "In Stock" : "Out of Stock")
                                .font(.system(size: 13))
                                .foregroundColor(price.inStock ? .green : .red)
                        }

                        Text(price.formattedPrice)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(price.inStock ? .green : .secondary)
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
                    Text("Last updated: \(station.lastUpdated.formatted(.relative(presentation: .named)))")
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
