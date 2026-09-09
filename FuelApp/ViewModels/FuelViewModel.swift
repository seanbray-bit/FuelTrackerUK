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

    /// Number of litres the user wants to fill up (drives the cost calculator).
    /// Persisted so the choice survives app launches.
    @Published var fillLitres: Double {
        didSet {
            UserDefaults.standard.set(fillLitres, forKey: Self.fillLitresKey)
        }
    }

    static let minFillLitres: Double = 1
    static let maxFillLitres: Double = 100
    static let defaultFillLitres: Double = 40
    private static let fillLitresKey = "fillLitres"

    private let apiService = FuelAPIService.shared
    private var refreshTask: Task<Void, Never>?

    init() {
        let saved = UserDefaults.standard.double(forKey: Self.fillLitresKey)
        fillLitres = saved > 0 ? saved : Self.defaultFillLitres
    }

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
        isLoading = true
        errorMessage = nil

        do {
            let results = try await apiService.fetchStations(
                near: location,
                radiusMetres: searchRadiusMetres
            )

            if results.isEmpty {
                errorMessage = "No fuel stations found nearby. Try increasing your search radius."
            } else {
                stations = results
                lastRefreshed = Date()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

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

    // MARK: - Fill-up cost stats

    /// All available fill costs (£) for the selected fuel type at the current litres.
    private var fillCosts: [Double] {
        stations.compactMap { $0.fillCost(for: selectedFuelType, litres: fillLitres) }
    }

    /// Cost (£) to fill up at the cheapest station nearby.
    var cheapestFillCost: Double? {
        fillCosts.min()
    }

    /// Average fill cost (£) across nearby stations.
    var averageFillCost: Double? {
        let costs = fillCosts
        guard !costs.isEmpty else { return nil }
        return costs.reduce(0, +) / Double(costs.count)
    }

    /// Cost (£) to fill up at the most expensive station nearby.
    var mostExpensiveFillCost: Double? {
        fillCosts.max()
    }

    /// How much a driver saves (£) filling up at the cheapest station vs the local average.
    var savingsVsAverage: Double? {
        guard let cheapest = cheapestFillCost, let avg = averageFillCost else { return nil }
        return max(0, avg - cheapest)
    }
}
