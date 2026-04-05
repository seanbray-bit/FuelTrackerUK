import Foundation

enum FuelType: String, CaseIterable, Codable, Identifiable {
    case unleaded = "Unleaded"
    case diesel = "Diesel"
    case superUnleaded = "Super Unleaded"
    case premiumDiesel = "Premium Diesel"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .unleaded: return "UNL"
        case .diesel: return "DSL"
        case .superUnleaded: return "SUP"
        case .premiumDiesel: return "P.DSL"
        }
    }
}
