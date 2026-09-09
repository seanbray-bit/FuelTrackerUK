import SwiftUI

/// Lets the user pick how many litres they want to fill up and shows the
/// real-money cost at nearby stations, plus how much the cheapest saves.
struct FillUpCalculatorView: View {
    @ObservedObject var viewModel: FuelViewModel
    @Environment(\.dismiss) private var dismiss

    private let presets: [Double] = [10, 20, 30, 40, 50, 60]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    fuelTypePicker
                    litreDisplay
                    litreControls
                    presetChips
                    summaryCard
                    savingsBanner
                }
                .padding()
            }
            .navigationTitle("Fill-Up Cost")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Fuel type

    private var fuelTypePicker: some View {
        Picker("Fuel Type", selection: $viewModel.selectedFuelType) {
            ForEach(FuelType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Litre display

    private var litreDisplay: some View {
        VStack(spacing: 2) {
            Text("\(Int(viewModel.fillLitres))")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.green)
                .contentTransition(.numericText())
                .animation(.snappy, value: viewModel.fillLitres)
            Text("litres of \(viewModel.selectedFuelType.rawValue)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Controls

    private var litreControls: some View {
        VStack(spacing: 12) {
            Slider(
                value: $viewModel.fillLitres,
                in: FuelViewModel.minFillLitres...FuelViewModel.maxFillLitres,
                step: 1
            )
            .tint(.green)

            Stepper(
                value: $viewModel.fillLitres,
                in: FuelViewModel.minFillLitres...FuelViewModel.maxFillLitres,
                step: 1
            ) {
                Text("Adjust litres")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Presets

    private var presetChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 10)], spacing: 10) {
            ForEach(presets, id: \.self) { litres in
                Button {
                    viewModel.fillLitres = litres
                } label: {
                    Text("\(Int(litres)) L")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSelected(litres) ? Color.green : Color(.systemGray6))
                        .foregroundColor(isSelected(litres) ? .white : .primary)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func isSelected(_ litres: Double) -> Bool {
        abs(viewModel.fillLitres - litres) < 0.5
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: 0) {
            if let cheapest = viewModel.cheapestFillCost {
                summaryRow(title: "Cheapest station", value: cheapest.gbpFormatted, highlight: true)
                if let avg = viewModel.averageFillCost {
                    Divider()
                    summaryRow(title: "Local average", value: avg.gbpFormatted)
                }
                if let dear = viewModel.mostExpensiveFillCost {
                    Divider()
                    summaryRow(title: "Most expensive", value: dear.gbpFormatted)
                }
            } else {
                Text("No prices available yet.\nPull to refresh the station list.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func summaryRow(title: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 20, weight: highlight ? .bold : .semibold))
                .foregroundColor(highlight ? .green : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Savings banner

    @ViewBuilder
    private var savingsBanner: some View {
        if let savings = viewModel.savingsVsAverage, savings > 0 {
            HStack(spacing: 10) {
                Image(systemName: "sterlingsign.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
                Text("Fill up at the cheapest station and save \(savings.gbpFormatted) versus the local average.")
                    .font(.system(size: 14, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding()
            .background(Color.green.opacity(0.12))
            .cornerRadius(12)
        }
    }
}
