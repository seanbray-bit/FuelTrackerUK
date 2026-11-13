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

    // Injectable seams make request races and timer ticks deterministic in tests.
    // Production callers continue to use the shared live service and 300-second sleep.
    private let stationLookup: (CLLocation, Double) async throws -> [FuelStation]
    private let sleepFor: (Duration) async throws -> Void
    private var refreshTask: Task<Void, Never>?
    // An older overlapping lookup must never replace the latest location's result.
    private var latestRequestID = UUID()

    init(
        stationLookup: @escaping (CLLocation, Double) async throws -> [FuelStation] = { location, radius in
            try await FuelAPIService.shared.fetchStations(near: location, radiusMetres: radius)
        },
        sleepFor: @escaping (Duration) async throws -> Void = { duration in
            try await Task<Never, Never>.sleep(for: duration)
        }
    ) {
        self.stationLookup = stationLookup
        self.sleepFor = sleepFor
    }

    var searchRadiusMetres: Double {
        searchRadiusMiles * 1609.344
    }

    // MARK: - Sorted stations (reported prices first, then unpriced locations)

    func sortedStations(from location: CLLocation?) -> [FuelStation] {
        stations.sorted { a, b in
            let priceA = a.price(for: selectedFuelType)?.pricePerLitre
            let priceB = b.price(for: selectedFuelType)?.pricePerLitre

            // An unavailable price is not a reason to hide a real station.
            if let priceA, let priceB, priceA != priceB { return priceA < priceB }
            if priceA != nil && priceB == nil { return true }
            if priceA == nil && priceB != nil { return false }

            // Order equally priced and unpriced stations consistently.
            if let location {
                let distanceA = a.distanceValue(from: location)
                let distanceB = b.distanceValue(from: location)
                if distanceA != distanceB { return distanceA < distanceB }
            }
            let nameOrder = a.name.localizedCaseInsensitiveCompare(b.name)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return a.id < b.id
        }
    }

    // MARK: - Fetch stations

    func fetchStations(near location: CLLocation) async {
        // A stopped auto-refresh must not start an extra lookup.
        guard !Task.isCancelled else { return }

        // Calls may overlap when a location change, manual refresh and timer coincide.
        // Snapshot the radius and only publish results from the newest request.
        let requestID = UUID()
        latestRequestID = requestID
        let radiusMetres = searchRadiusMetres
        isLoading = true
        errorMessage = nil
        // A cancelled latest request still needs to release the spinner.
        // A superseded request must not hide the current request's spinner.
        defer {
            if latestRequestID == requestID { isLoading = false }
        }

        do {
            let results = try await stationLookup(location, radiusMetres)
            guard latestRequestID == requestID, !Task.isCancelled else { return }

            // A successful empty response is still the latest station list.
            // Clear results from the previous location/radius rather than
            // displaying stations that are no longer in range.
            stations = results
            lastRefreshed = Date()

            if results.isEmpty {
                errorMessage = "No fuel stations found nearby. Try increasing your search radius."
            }
        } catch is CancellationError {
            // Expected cancellation is not a user-visible network failure.
        } catch {
            guard latestRequestID == requestID, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Auto-refresh (every 5 minutes)

    func startAutoRefresh(locationManager: LocationManager) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                // Sleep throws when cancelled; never swallow it and fetch once more.
                do {
                    try await sleepFor(.seconds(300))
                } catch {
                    break
                }
                guard !Task.isCancelled else { break }
                if let location = locationManager.userLocation {
                    await fetchStations(near: location)
                }
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
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
