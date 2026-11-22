import SwiftUI

struct StationListView: View {
    @ObservedObject var viewModel: FuelViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var subscriptionManager: SubscriptionManager

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fuel type picker
                Picker("Fuel Type", selection: $viewModel.selectedFuelType) {
                    ForEach(FuelType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // Stats bar
                if let cheapest = viewModel.cheapestPrice {
                    HStack {
                        Label("Lowest reported: **\(cheapest)**", systemImage: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))

                        Spacer()

                        Text("Stock unknown")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        // Full-market aggregates include premium-locked prices. Do not
                        // expose them (including through VoiceOver) to free accounts.
                        if subscriptionManager.canRevealPremium, let avg = viewModel.averagePrice {
                            Text("Reported avg: \(avg)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                }

                // Explicitly distinguish known forecourt locations from
                // unavailable prices; never imply unverified values are live.
                if !viewModel.stations.isEmpty &&
                    viewModel.stations.allSatisfy({ $0.prices.isEmpty }) {
                    Label(
                        "Verified pump prices are unavailable. Showing forecourt locations only.",
                        systemImage: "info.circle"
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // A failed update must be visible even when earlier station locations
                // remain on screen; otherwise users could mistake them for fresh data.
                if let error = viewModel.errorMessage, !viewModel.stations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Station update failed", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Showing previously loaded station locations. \(error)")
                            .font(.footnote)
                        Button("Retry station update") {
                            Task { await refresh() }
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Tries to load the latest nearby station locations.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .accessibilityElement(children: .contain)
                }

                // When retrying after a failure (or moving to a new area), the
                // retained stations remain stale until a successful response.
                if viewModel.isLoading && !viewModel.stations.isEmpty {
                    Label(
                        "Updating nearby stations — showing previous locations until the search finishes.",
                        systemImage: "arrow.clockwise"
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Station list
                if viewModel.isLoading && viewModel.stations.isEmpty {
                    Spacer()
                    ProgressView("Finding cheapest fuel near you...")
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.stations.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "fuelpump.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Try Again") {
                            Task { await refresh() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else if locationManager.authorizationStatus == .notDetermined {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        Text("We need your location to find\ncheap fuel near you")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                        Button("Enable Location") {
                            locationManager.requestPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    Spacer()
                } else {
                    let sorted = viewModel.sortedStations(from: locationManager.userLocation)
                    let priced = sorted.filter { $0.price(for: viewModel.selectedFuelType) != nil }
                    let unpriced = sorted.filter { $0.price(for: viewModel.selectedFuelType) == nil }

                    if sorted.isEmpty && !viewModel.isLoading {
                        Spacer()
                        Text("No nearby fuel stations found. Try increasing your search radius.")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        List {
                            if !priced.isEmpty {
                                Section("Reported prices") {
                                    ForEach(Array(priced.enumerated()), id: \.element.id) { index, station in
                                        let rank = index + 1

                                        if !viewModel.canViewReportedPrice(
                                            for: station,
                                            pricedRank: rank,
                                            isSubscribed: subscriptionManager.canRevealPremium
                                        ) {
                                            // Never put hidden prices in the view or VoiceOver tree.
                                            Button {
                                                showPaywall = true
                                            } label: {
                                                Label("Reported price #\(rank) locked — unlock to view", systemImage: "lock.fill")
                                            }
                                            .accessibilityLabel("Reported price rank \(rank) locked. Opens subscription options.")
                                            .tint(.primary)
                                        } else {
                                            NavigationLink {
                                                StationDetailDestination(
                                                    stationID: station.id,
                                                    viewModel: viewModel,
                                                    locationManager: locationManager,
                                                    subscriptionManager: subscriptionManager,
                                                    onDismiss: nil
                                                )
                                            } label: {
                                                StationRowView(
                                                    station: station,
                                                    fuelType: viewModel.selectedFuelType,
                                                    userLocation: locationManager.userLocation,
                                                    rank: rank
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            if !unpriced.isEmpty {
                                Section("Nearby stations — price unavailable") {
                                    ForEach(unpriced) { station in
                                        NavigationLink {
                                            StationDetailDestination(
                                                    stationID: station.id,
                                                    viewModel: viewModel,
                                                    locationManager: locationManager,
                                                    subscriptionManager: subscriptionManager,
                                                    onDismiss: nil
                                                )
                                        } label: {
                                            StationRowView(
                                                station: station,
                                                fuelType: viewModel.selectedFuelType,
                                                userLocation: locationManager.userLocation,
                                                rank: nil
                                            )
                                        }
                                    }
                                }
                            }

                            if !subscriptionManager.canRevealPremium && priced.count > 3 {
                                Section {
                                    Button {
                                        showPaywall = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "lock.fill")
                                            Text("Unlock all reported prices for just \(SubscriptionManager.price)")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .background(Color.green)
                                        .cornerRadius(10)
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await refresh()
                        }
                    }
                }

                // Last updated
                if let lastRefreshed = viewModel.lastRefreshed {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Search completed \(lastRefreshed.formatted(.relative(presentation: .named))) — price observation times unknown")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Fuel Tracker UK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            Task { await refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscriptionManager: subscriptionManager)
            }
            .onAppear {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestPermission()
                }
            }
        }
    }

    private func refresh() async {
        guard let location = locationManager.userLocation else { return }
        await viewModel.fetchStations(near: location)
    }
}
