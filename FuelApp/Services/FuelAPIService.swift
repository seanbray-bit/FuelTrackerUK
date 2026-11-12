import Foundation
import CoreLocation

/// Fetches UK fuel price data.
/// Currently uses the UK Government Open Data feed for fuel prices.
/// Unavailable prices must never become synthetic forecourt quotes.
actor FuelAPIService {

    static let shared = FuelAPIService()

    // MARK: - UK Government Open Data endpoint
    // The CMA (Competition and Markets Authority) requires major retailers to publish prices.
    // This is updated daily for the largest retailers.
    private let ukGovFuelURL = "https://www.gov.uk/guidance/access-fuel-price-data"

    /// Fetches stations near the user's location.
    /// Uses OpenStreetMap Overpass API for station locations + UK Gov data for prices.
    func fetchStations(near location: CLLocation, radiusMetres: Double = 16093) async throws -> [FuelStation] {
        // Step 1: Find fuel stations nearby using Overpass API (OpenStreetMap)
        let stations = try await fetchNearbyStations(location: location, radius: radiusMetres)

        // Step 2: Enrich with price data where available
        let enriched = try await enrichWithPrices(stations: stations)

        return enriched
    }

    // MARK: - OpenStreetMap Overpass API (free, no key needed)
    private func fetchNearbyStations(location: CLLocation, radius: Double) async throws -> [FuelStation] {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Overpass QL query for fuel stations within radius
        let query = """
        [out:json][timeout:25];
        (
          node["amenity"="fuel"](around:\(radius),\(lat),\(lon));
          way["amenity"="fuel"](around:\(radius),\(lat),\(lon));
        );
        out center body;
        """

        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://overpass-api.de/api/interpreter?data=\(encoded)"

        guard let url = URL(string: urlString) else {
            throw FuelAPIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FuelAPIError.serverError
        }

        return try parseOverpassResponse(data: data)
    }

    private func parseOverpassResponse(data: Data) throws -> [FuelStation] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let elements = json["elements"] as? [[String: Any]] else {
            throw FuelAPIError.parsingError
        }

        var stations: [FuelStation] = []
        let now = Date()

        for element in elements {
            let tags = element["tags"] as? [String: String] ?? [:]

            // Get coordinates - for 'way' types, use 'center'
            var lat: Double?
            var lon: Double?

            if let center = element["center"] as? [String: Any] {
                lat = center["lat"] as? Double
                lon = center["lon"] as? Double
            } else {
                lat = element["lat"] as? Double
                lon = element["lon"] as? Double
            }

            guard let latitude = lat, let longitude = lon else { continue }

            let id = "\(element["id"] ?? UUID().uuidString)"
            let name = tags["name"] ?? tags["brand"] ?? "Fuel Station"
            let brand = tags["brand"] ?? tags["operator"] ?? "Independent"

            // Build address from available tags
            let street = tags["addr:street"] ?? ""
            let city = tags["addr:city"] ?? tags["addr:town"] ?? ""
            let postcode = tags["addr:postcode"] ?? ""
            let address = [street, city].filter { !$0.isEmpty }.joined(separator: ", ")

            let station = FuelStation(
                id: id,
                name: name,
                brand: brand,
                address: address.isEmpty ? "Address unavailable" : address,
                postcode: postcode,
                latitude: latitude,
                longitude: longitude,
                prices: [], // Will be enriched with price data
                lastUpdated: now
            )

            stations.append(station)
        }

        return stations
    }

    // MARK: - Price enrichment
    // Attempts to fetch real prices from UK Gov open data.
    // Leave prices unavailable when no provider record matches.
    private func enrichWithPrices(stations: [FuelStation]) async throws -> [FuelStation] {
        // Try to fetch CMA mandatory price data
        let livePrices = await fetchCMAPrices()

        return stations.map { station in
            var enriched = station
            // Match reported provider data by brand/postcode
            if let matched = livePrices.first(where: {
                $0.brand.lowercased() == station.brand.lowercased() &&
                $0.postcode.lowercased().replacingOccurrences(of: " ", with: "") ==
                station.postcode.lowercased().replacingOccurrences(of: " ", with: "")
            }) {
                enriched.prices = matched.prices
            } // Otherwise retain this station without a price.

            return enriched
        }
    }

    // MARK: - CMA Open Data
    // UK's Competition and Markets Authority requires top 7 retailers to publish daily prices.
    // Retailers: Asda, BP, Esso, Morrisons, Sainsbury's, Shell, Tesco
    private func fetchCMAPrices() async -> [StationPriceData] {
        // CMA road fuel price data endpoint
        guard let url = URL(string: "https://assets.publishing.service.gov.uk/media/fuel-prices/current-fuel-prices.csv") else {
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return [] }
            return parseCMACSV(data: data)
        } catch {
            return []
        }
    }

    private func parseCMACSV(data: Data) -> [StationPriceData] {
        guard let csv = String(data: data, encoding: .utf8) else { return [] }

        var results: [StationPriceData] = []
        let lines = csv.components(separatedBy: .newlines)
        // Reject unexpected CSV layouts (including HTML error pages) rather than misprice.
        guard let header = lines.first else { return [] }
        let columns = header.lowercased().components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard Array(columns.prefix(4)) == ["brand", "postcode", "unleaded_price", "diesel_price"] else {
            return []
        }
        let retrievedAt = Date()

        // Skip validated header row
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            // Expected: brand, postcode, unleaded_price, diesel_price, ...
            guard columns.count >= 4 else { continue }

            let brand = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let postcode = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let unlPrice = Double(columns[2].trimmingCharacters(in: .whitespacesAndNewlines))
            let dslPrice = Double(columns[3].trimmingCharacters(in: .whitespacesAndNewlines))

            var prices: [FuelPrice] = []

            if let p = unlPrice, p > 0 {
                prices.append(FuelPrice(fuelType: .unleaded, pricePerLitre: p, inStock: nil, lastUpdated: retrievedAt))
            }
            if let p = dslPrice, p > 0 {
                prices.append(FuelPrice(fuelType: .diesel, pricePerLitre: p, inStock: nil, lastUpdated: retrievedAt))
            }

            results.append(StationPriceData(brand: brand, postcode: postcode, prices: prices))
        }

        return results
    }


}

// MARK: - Supporting types

struct StationPriceData {
    let brand: String
    let postcode: String
    let prices: [FuelPrice]
}

enum FuelAPIError: LocalizedError {
    case invalidURL
    case serverError
    case parsingError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request"
        case .serverError: return "Server unavailable. Try again."
        case .parsingError: return "Could not read fuel data"
        case .noData: return "No fuel stations found nearby"
        }
    }
}
