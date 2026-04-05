import Foundation
import CoreLocation

struct FuelStation: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String
    let address: String
    let postcode: String
    let latitude: Double
    let longitude: Double
    var prices: [FuelPrice]
    let lastUpdated: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func price(for fuelType: FuelType) -> FuelPrice? {
        prices.first { $0.fuelType == fuelType }
    }

    func distanceText(from location: CLLocation) -> String {
        let stationLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distanceMetres = location.distance(from: stationLocation)
        let distanceMiles = distanceMetres / 1609.344
        return String(format: "%.1f mi", distanceMiles)
    }

    func distanceValue(from location: CLLocation) -> Double {
        let stationLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: stationLocation)
    }
}

struct FuelPrice: Codable, Identifiable {
    var id: String { fuelType.rawValue }
    let fuelType: FuelType
    let pricePerLitre: Double // pence per litre
    let inStock: Bool
    let lastUpdated: Date

    var formattedPrice: String {
        String(format: "%.1fp", pricePerLitre)
    }
}
