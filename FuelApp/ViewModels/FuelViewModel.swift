import Foundation
import CoreLocation

@MainActor
final class FuelViewModel: ObservableObject {
    @Published var stations: [FuelStation] = []
    @Published var selectedFuelType: FuelType = .unleaded
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshed: Date?
    @Published var searchRadiusMiles: Double = 10

    private let apiService = FuelAPIService.shared
    private var refreshTask: Task<Void, Never>?
    // An older overlapping lookup must never replace the latest location's result.
    private var latestRequestID = UUID()

    var searchRadiusMetres: Double {
        searchRadiusMiles * 1609.344
    }

    // MARK: - Sorted stations (cheapest first, ALWAYS)

    func sortedStations(from location: CLLocation?) -> [FuelStation] {
        let withPrices = stations.filter { station in
            station.price(for: selectedFuelType) != nil
        }

        return withPrices.sorted { a, b in
            let priceA = a.price(for: selectedFuelType)?.pricePerLitre ?? .infinity
            let priceB = b.price(for: selectedFuelType)?.pricePerLitre ?? .infinity
            return priceA < priceB
        }
    }

    // MARK: - Fetch stations

    func fetchStations(near location: CLLocation) async {
        // Calls may overlap when a location change, manual refresh and timer coincide.
        // Snapshot the radius and only publish results from the newest request.
        let requestID = UUID()
        latestRequestID = requestID
        let radiusMetres = searchRadiusMetres
        isLoading = true
        errorMessage = nil

        do {
            let results = try await apiService.fetchStations(
                near: location,
                radiusMetres: radiusMetres
            )
            guard latestRequestID == requestID else { return }

            // A successful empty response is still the latest station list.
            // Clear results from the previous location/radius rather than
            // displaying stations that are no longer in range.
            stations = results
            lastRefreshed = Date()

            if results.isEmpty {
                errorMessage = "No fuel stations found nearby. Try increasing your search radius."
            }
        } catch {
            guard latestRequestID == requestID else { return }
            errorMessage = error.localizedDescription
        }

        // An older completion must not hide the newest request's spinner.
        isLoading = false
    }

    // MARK: - Auto-refresh (every 5 minutes)

    func startAutoRefresh(locationManager: LocationManager) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                if let location = locationManager.userLocation {
                    await fetchStations(near: location)
                }
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
    }

    // MARK: - Stats

    var cheapestPrice: String? {
        let sorted = stations.compactMap { $0.price(for: selectedFuelType)?.pricePerLitre }
        guard let cheapest = sorted.min() else { return nil }
        return String(format: "%.1fp", cheapest)
    }

    var averagePrice: String? {
        let prices = stations.compactMap { $0.price(for: selectedFuelType)?.pricePerLitre }
        guard !prices.isEmpty else { return nil }
        let avg = prices.reduce(0, +) / Double(prices.count)
        return String(format: "%.1fp", avg)
    }

    var stationsInStock: Int {
        stations.filter { station in
            station.price(for: selectedFuelType)?.inStock == true
        }.count
    }
}
