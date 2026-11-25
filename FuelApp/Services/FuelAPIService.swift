import Foundation
import CoreLocation
import CoreFoundation

/// Locates UK fuel forecourts from OpenStreetMap.
/// Forecourt prices require a verified provider site ID and provenance.
/// Never infer a pump price from a matching retailer name or postcode.
actor FuelAPIService {

    static let shared = FuelAPIService()

    /// Fetches station locations only while no verified OSM-to-provider ID
    /// crosswalk exists. Do not attribute prices by brand/postcode.
    /// A future provider integration must validate site IDs, fuel grades,
    /// units and source observation timestamps before populating prices.
    func fetchStations(near location: CLLocation, radiusMetres: Double = 16093) async throws -> [FuelStation] {
        return try await fetchNearbyStations(location: location, radius: radiusMetres)
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

        try Task.checkCancellation()
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FuelAPIError.serverError
        }

        return try Self.parseOverpassResponse(data: data)
    }

    // Internal pure parser for deterministic fixtures; no network needed.
    static func parseOverpassResponse(data: Data) throws -> [FuelStation] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let elements = json["elements"] as? [[String: Any]] else {
            throw FuelAPIError.parsingError
        }

        // Overpass may return HTTP 200 with partial elements and a runtime remark.
        // Fail closed rather than publish incomplete results as a successful search.
        guard json["remark"] == nil, json["error"] == nil else {
            throw FuelAPIError.incompleteResponse
        }

        var stations: [FuelStation] = []
        var seenIDs = Set<String>()
        let now = Date()

        func coordinateValue(_ value: Any?) -> Double? {
            guard let number = value as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
            let result = number.doubleValue
            return result.isFinite ? result : nil
        }

        for element in elements {
            let tags = element["tags"] as? [String: String] ?? [:]

            // Get coordinates - for 'way' types, use 'center'
            var lat: Double?
            var lon: Double?

            if let center = element["center"] as? [String: Any] {
                lat = coordinateValue(center["lat"])
                lon = coordinateValue(center["lon"])
            } else {
                lat = coordinateValue(element["lat"])
                lon = coordinateValue(element["lon"])
            }

            guard let latitude = lat, let longitude = lon,
                  CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
                throw FuelAPIError.incompleteResponse
            }

            // OSM node and way numbers occupy independent ID namespaces.
            // Reject malformed identity instead of generating unstable IDs.
            guard let elementType = element["type"] as? String,
                  (elementType == "node" || elementType == "way"),
                  let numericID = element["id"] as? NSNumber,
                  CFGetTypeID(numericID) != CFBooleanGetTypeID(),
                  let positiveID = Int64(numericID.stringValue), positiveID > 0 else {
                throw FuelAPIError.incompleteResponse
            }
            let id = "osm:\(elementType):\(positiveID)"
            guard seenIDs.insert(id).inserted else { continue }
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
                prices: [], // No validated provider forecourt match exists yet
                lastUpdated: now
            )

            stations.append(station)
        }

        return stations
    }

}

// MARK: - Supporting types

enum FuelAPIError: LocalizedError {
    case invalidURL
    case serverError
    case parsingError
    case incompleteResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request"
        case .serverError: return "Server unavailable. Try again."
        case .parsingError: return "Could not read fuel data"
        case .incompleteResponse: return "Station data was incomplete. Please retry."
        case .noData: return "No fuel stations found nearby"
        }
    }
}
