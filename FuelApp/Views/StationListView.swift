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

                        if let avg = viewModel.averagePrice {
                            Text("Reported avg: \(avg)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
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
                            refresh()
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
                                            isSubscribed: subscriptionManager.isSubscribed
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
                                                StationDetailView(
                                                    station: station,
                                                    userLocation: locationManager.userLocation,
                                                    visibleFuelType: subscriptionManager.isSubscribed ? nil : viewModel.selectedFuelType
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
                                            StationDetailView(
                                                station: station,
                                                userLocation: locationManager.userLocation,
                                                visibleFuelType: subscriptionManager.isSubscribed ? nil : viewModel.selectedFuelType
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

                            if !subscriptionManager.isSubscribed && priced.count > 3 {
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
                            refresh()
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
                            refresh()
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
            .onChange(of: locationManager.userLocation) { _, newLocation in
                if let location = newLocation, viewModel.stations.isEmpty {
                    Task {
                        await viewModel.fetchStations(near: location)
                    }
                }
            }
        }
    }

    private func refresh() {
        guard let location = locationManager.userLocation else { return }
        Task {
            await viewModel.fetchStations(near: location)
        }
    }
}
