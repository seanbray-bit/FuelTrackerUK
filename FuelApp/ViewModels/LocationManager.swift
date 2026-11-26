import Foundation
import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?

    private let manager = CLLocationManager()

    static func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
        status == .authorizedWhenInUse || status == .authorizedAlways
    }

    var canUseLocation: Bool {
        Self.isAuthorized(authorizationStatus) && Self.isAuthorized(manager.authorizationStatus)
    }

    var lookupLocation: CLLocation? {
        canUseLocation ? userLocation : nil
    }

    private(set) var permissionEpoch = UUID()
    private var minimumFixTimestamp: Date?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 500 // Update every 500m
        synchronizeAuthorization()
    }

    func requestPermission() {
        guard manager.authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard canUseLocation else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func synchronizeAuthorization() {
        let status = manager.authorizationStatus
        let changed = status != authorizationStatus
        if !Self.isAuthorized(status) {
            stopUpdating()
            userLocation = nil
            locationError = nil
            if changed {
                permissionEpoch = UUID()
                minimumFixTimestamp = Date()
            }
        } else if changed {
            locationError = nil
        }
        if changed { authorizationStatus = status }
        if canUseLocation { startUpdating() }
    }

    func retryLocation() {
        guard canUseLocation else { return }
        locationError = nil
        stopUpdating()
        startUpdating()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            guard self.canUseLocation else { return }
            // Core Location may initially deliver a cached fix or a queued older
            // callback. Accept approximate accuracy, but require valid coordinates
            // and an observation no older than 120 seconds (5s future tolerance).
            guard location.horizontalAccuracy.isFinite, location.horizontalAccuracy >= 0,
                  CLLocationCoordinate2DIsValid(location.coordinate),
                  (-5...120).contains(Date().timeIntervalSince(location.timestamp)) else {
                if self.userLocation == nil {
                    self.locationError = "Waiting for a current location. Try again."
                }
                return
            }
            if let minimum = self.minimumFixTimestamp, location.timestamp < minimum { return }
            if let current = self.userLocation, location.timestamp < current.timestamp { return }
            self.userLocation = location
            self.locationError = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            guard self.canUseLocation else {
                self.synchronizeAuthorization()
                return
            }
            self.locationError = "Unable to get your location. Try again."
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.synchronizeAuthorization()
        }
    }
}
