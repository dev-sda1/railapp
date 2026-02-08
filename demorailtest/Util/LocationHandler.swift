//
//  LocationHandler.swift
//  demorailtest
//
//  Created by James on 04/02/2026.
//

import Foundation
import CoreLocation
import uk_railway_stations

struct LocationData {
    var latitude: Double
    var longitude: Double
    var isSuccess: Bool
}


struct StationJSONFileEntry : Codable {
    let stationName: String
    let lat: Double
    let long: Double
    let crsCode: String
    let constituentCountry: String
}

struct NearestStationInfo: Hashable {
    var stationName: String
    var stationCRS: String
    var latitude: Double
    var longitude: Double
    var distanceTo: Double
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    
    enum LocationManagerError: String, Error {
        case replaceContinuation = "Continuation replaced."
        case locationNotFound = "No location found."
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func checkAuthorisation(){
        switch locationManager.authorizationStatus {
        case.notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            return
        }
    }
    
    var currentLocation: CLLocation {
        get async throws {
            if self.continuation != nil {
                self.continuation?.resume(throwing: LocationManagerError.replaceContinuation)
                self.continuation = nil
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                locationManager.requestLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            continuation?.resume(returning: lastLocation)
            continuation = nil
        }else{
            continuation?.resume(throwing: LocationManagerError.locationNotFound)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

}

private func getCurrentLocation() async -> LocationData {
    let locationManager = LocationManager()
    let location: CLLocation?
    
    var res = LocationData(latitude: 0.0, longitude: 0.0, isSuccess: false)
    
    locationManager.checkAuthorisation()
    
    guard let location = try? await locationManager.currentLocation else { return res }
    
    res.latitude = location.coordinate.latitude
    res.longitude = location.coordinate.longitude
    res.isSuccess = true

    print("Returned location data: \(res)")
    return res
}

func findNearestStationFromLocation(radius: Double) async -> NearestStationInfo{
    var nearestStation: NearestStationInfo = NearestStationInfo(stationName: "", stationCRS: "", latitude: 0.0, longitude: 0.0, distanceTo: 10000000.0)
    let location = await getCurrentLocation()
    
    if location.isSuccess == false { return nearestStation }
    
    let url = Bundle.stationsJSONBundleURL
    guard let data = try? Data(contentsOf: url) else { return nearestStation }
    
    let decoder = JSONDecoder()
    
    guard let loadedFile = try? decoder.decode([StationJSONFileEntry].self, from: data) else { return nearestStation }
    let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
    
    var possibleNearStations: [NearestStationInfo] = []
    
    loadedFile.enumerated().forEach { index, station in
        let stationLocation = CLLocation(latitude: station.lat, longitude: station.long)
        let distanceInMetres = userLocation.distance(from: stationLocation)
        let distanceInMiles = distanceInMetres * 0.00062137
        
        if distanceInMiles < radius {
            print("User is near \(station.stationName)")
            possibleNearStations.append(NearestStationInfo(stationName: station.stationName, stationCRS: station.crsCode, latitude: station.lat, longitude: station.long, distanceTo: distanceInMiles))
        }
    }
    
    print("Possible stations: \(possibleNearStations.count)")
    
    possibleNearStations.forEach { possibleStation in
        if possibleStation.distanceTo <= nearestStation.distanceTo {
            nearestStation = possibleStation
        }
    }
    
    print("Nearest to: \(nearestStation.stationCRS)")
    
    return nearestStation
}

func getNearestStationsFromLocation(radius: Double) async -> [NearestStationInfo] {
    var possibleNearStations: [NearestStationInfo] = []
    
    let location = await getCurrentLocation()
    
    if location.isSuccess == false { return possibleNearStations }
    
    let url = Bundle.stationsJSONBundleURL
    guard let data = try? Data(contentsOf: url) else { return possibleNearStations }
    
    let decoder = JSONDecoder()
    
    guard let loadedFile = try? decoder.decode([StationJSONFileEntry].self, from: data) else { return possibleNearStations }
    let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

    loadedFile.enumerated().forEach { index, station in
        let stationLocation = CLLocation(latitude: station.lat, longitude: station.long)
        let distanceInMetres = userLocation.distance(from: stationLocation)
        let distanceInMiles = distanceInMetres * 0.00062137
        
        if distanceInMiles < radius {
            var duplicate = false
            
            possibleNearStations.forEach{ possibleDuplicate in
                if(possibleDuplicate.stationCRS == station.crsCode){
                    duplicate = true
                }
            }
            
            if duplicate == false {
                possibleNearStations.append(NearestStationInfo(stationName: station.stationName, stationCRS: station.crsCode, latitude: station.lat, longitude: station.long, distanceTo: distanceInMiles))
            }
        }
    }
    
    possibleNearStations.sort(by: {$0.distanceTo < $1.distanceTo})
    
    return possibleNearStations
}
