//
//  AYLocationManager.swift
//  LocationTrace
//
//  Created by Ahmed Mohamed Yousef on 03/12/2024.
//

import Foundation
import CoreLocation

/// A namespace for the location manager package.
public enum AYLocationServices {
    /// Delegate protocol for location updates and authorization status.
    public protocol Delegate: AnyObject {
        func didUpdateLocation(locations: [CLLocation])
        func didChangeAuthorizationStatus(status: CLAuthorizationStatus)
    }
}

/// A manager class to handle location tracking.
public final class AYLocationManager: NSObject, @unchecked Sendable {
    // Singleton instance
    public static let shared = AYLocationManager()
    
    private let locationManager = CLLocationManager()
    private var recordedLocations: [CLLocation] = []
    
    /// Delegate for receiving location updates.
    public weak var delegate: AYLocationServices.Delegate?
    
    /// Indicates whether location access is granted.
    public var accessGranted: Bool {
        switch locationManager.authorizationStatus {
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        @unknown default:
            return false
        }
    }
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    /// Requests location service permission.
    public func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Starts location tracking.
    public func startTracking() {
        DispatchQueue.global().async {
            guard CLLocationManager.locationServicesEnabled() else {
                print("Location services are not enabled.")
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.recordedLocations.removeAll()
                self.locationManager.startUpdatingLocation()
                self.locationManager.startMonitoringSignificantLocationChanges()
            }
        }
    }
    
    /// Pauses location tracking.
    public func pauseTracking() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Resumes location tracking.
    public func resumeTracking() {
        locationManager.startUpdatingLocation()
    }
    
    /// Stops location tracking.
    public func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    /// Requests a single location update.
    public func requestLocation() {
        locationManager.requestLocation()
    }
}

extension AYLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate?.didChangeAuthorizationStatus(status: status)
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location access granted.")
        case .denied, .restricted:
            print("Location access denied.")
        default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        recordedLocations.append(contentsOf: locations)
        delegate?.didUpdateLocation(locations: locations)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to update location: \(error.localizedDescription)")
    }
}
