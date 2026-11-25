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
    private var activeLookup: Task<[FuelStation], Error>?
    // An older overlapping lookup must never replace the latest location's result.
    private var latestRequestID = UUID()
    // Identifies the most recent LOCATION EVENT, not the order queued Tasks start.
    private var latestLocationReservationID: UUID?
    // Compare GPS updates with the centre of the most recently attempted lookup,
    // including failed/in-flight requests, so tiny GPS changes don't flood Overpass.
    private(set) var lastRequestedSearchLocation: CLLocation?
    // Only a completed successful response (including zero stations) advances this centre.
    private(set) var lastSuccessfulSearchLocation: CLLocation?
    static let relocationRefreshDistanceMetres: CLLocationDistance = 2_000

    // Reserve the search centre synchronously before a Task is scheduled:
    // two GPS callbacks arriving in one UI cycle should not queue duplicate lookups.
    func reserveLocationRefreshIfNeeded(for location: CLLocation) -> UUID? {
        if let previous = lastRequestedSearchLocation,
           location.distance(from: previous) < Self.relocationRefreshDistanceMetres {
            return nil
        }
        let reservationID = UUID()
        latestLocationReservationID = reservationID
        lastRequestedSearchLocation = location
        // Invalidate a running lookup immediately; the newest Task might start later.
        latestRequestID = UUID()
        activeLookup?.cancel()
        // Mark the old results stale immediately, even before the queued Task starts.
        isLoading = true
        errorMessage = nil
        return reservationID
    }

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

    // Consistent list, map and detail paywall policy; rank counts priced stations.
    // Missing rank fails closed for a station that has a reported price.
    func canViewReportedPrice(for station: FuelStation, pricedRank: Int?, isSubscribed: Bool) -> Bool {
        guard station.price(for: selectedFuelType) != nil else { return true }
        return isSubscribed || (pricedRank.map { $0 <= 3 } ?? false)
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

    func invalidateLocationSearch() {
        latestRequestID = UUID()
        latestLocationReservationID = nil
        lastRequestedSearchLocation = nil
        lastSuccessfulSearchLocation = nil
        activeLookup?.cancel()
        activeLookup = nil
        stations = []
        lastRefreshed = nil
        errorMessage = nil
        isLoading = false
    }

    // Production callers provide the manager; nil retains the injected lookup test seam.
    func fetchStations(near location: CLLocation, locationReservationID: UUID? = nil, locationManager: LocationManager? = nil) async {
        // Reject superseded reservations before any state changes.
        if let locationReservationID {
            guard locationReservationID == latestLocationReservationID else { return }
        }
        let searchLocation: CLLocation
        if let locationManager {
            guard let currentLocation = locationManager.lookupLocation else {
                if locationReservationID != nil { invalidateLocationSearch() }
                return
            }
            // Manual tasks may have been queued before permission changed.
            searchLocation = locationReservationID == nil ? currentLocation : location
        } else {
            searchLocation = location
        }
        let permissionEpoch = locationManager?.permissionEpoch
        // Reject an older queued location event BEFORE it can change state.
        guard !Task.isCancelled else {
            if let locationReservationID, locationReservationID == latestLocationReservationID {
                latestLocationReservationID = nil
                activeLookup = nil
                isLoading = false
                // Keep the attempted centre to prevent repeated automatic retries
                // from GPS jitter; the explicit retry and timer remain available.
                errorMessage = "The latest station search was interrupted. Retry to load current results."
            }
            return
        }
        if let locationReservationID {
            guard locationReservationID == latestLocationReservationID else { return }
        } else {
            // Explicit/manual/timer refreshes take precedence over pending auto events.
            latestLocationReservationID = nil
        }
        lastRequestedSearchLocation = searchLocation

        // Calls may overlap when a location change, manual refresh and timer coincide.
        // Snapshot the radius and only publish results from the newest request.
        let requestID = UUID()
        latestRequestID = requestID
        let radiusMetres = searchRadiusMetres
        activeLookup?.cancel()
        isLoading = true
        errorMessage = nil
        // Only the current request may complete or mark its results incomplete.
        // A cancelled latest request must not look like a successful search.
        var completed = false
        defer {
            if latestRequestID == requestID {
                if let locationManager,
                   locationManager.lookupLocation == nil || locationManager.permissionEpoch != permissionEpoch {
                    invalidateLocationSearch()
                } else {
                    if !completed {
                        errorMessage = "The latest station search was interrupted. Retry to load current results."
                    }
                    isLoading = false
                    activeLookup = nil
                }
            }
        }

        do {
            let lookup = Task { [stationLookup] in
                try Task.checkCancellation()
                if let locationManager {
                    guard locationManager.lookupLocation != nil,
                          locationManager.permissionEpoch == permissionEpoch else { throw CancellationError() }
                }
                return try await stationLookup(searchLocation, radiusMetres)
            }
            activeLookup = lookup
            let results = try await withTaskCancellationHandler {
                try await lookup.value
            } onCancel: {
                lookup.cancel()
            }
            guard latestRequestID == requestID, !Task.isCancelled else { return }
            if let locationManager {
                guard locationManager.lookupLocation != nil,
                      locationManager.permissionEpoch == permissionEpoch else { return }
            }

            // A successful empty response is still the latest station list.
            // Clear results from the previous location/radius rather than
            // displaying stations that are no longer in range.
            stations = results
            lastSuccessfulSearchLocation = searchLocation
            lastRefreshed = Date()
            completed = true

        } catch is CancellationError {
            // The defer marks only a still-current request as interrupted.
        } catch let error as URLError where error.code == .cancelled {
            // URLSession can express cancellation as URLError.cancelled.
        } catch {
            guard latestRequestID == requestID, !Task.isCancelled else { return }
            if let locationManager {
                guard locationManager.lookupLocation != nil,
                      locationManager.permissionEpoch == permissionEpoch else { return }
            }
            errorMessage = error.localizedDescription
            completed = true
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
                if let location = locationManager.lookupLocation {
                    await fetchStations(near: location, locationManager: locationManager)
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
