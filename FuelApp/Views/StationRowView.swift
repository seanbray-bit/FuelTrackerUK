import SwiftUI
import CoreLocation

struct StationRowView: View {
    let station: FuelStation
    let fuelType: FuelType
    let userLocation: CLLocation?
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Station info
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                Text(station.brand)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                if let location = userLocation {
                    Text(station.distanceText(from: location))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Price and stock
            VStack(alignment: .trailing, spacing: 4) {
                if let price = station.price(for: fuelType) {
                    Text(price.formattedPrice)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(rank <= 3 ? .green : .primary)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(price.inStock ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(price.inStock ? "In Stock" : "Out of Stock")
                            .font(.system(size: 11))
                            .foregroundColor(price.inStock ? .green : .red)
                    }
                } else {
                    Text("N/A")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .green
        case 2: return .green.opacity(0.7)
        case 3: return .orange
        default: return .gray
        }
    }
}
