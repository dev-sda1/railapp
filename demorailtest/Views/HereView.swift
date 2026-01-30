//
//  HereView.swift
//  demorailtest
//
//  Created by James on 27/01/2026.
//

import SwiftUI
import Foundation
import uk_railway_stations
import SwiftData
import CoreLocation
import MapKit

extension CLLocationCoordinate2D {
    static var station = CLLocationCoordinate2D(latitude: 51.527039, longitude: -0.132384)
}

struct HereView: View {
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var cardNamespace
    @State private var scrollPosition: Double = 0
    @State private var loadingData: Bool = true
    @State private var depList: [DepartureItem] = []
    @State var expanded = false
    @State var activeId = UUID()
    @State private var fullyExpanded = false
    @State private var safeFrame: CGRect = .zero
    @StateObject private var vm = DeparturesViewModel(depList: [], loadingData: false, lastUpdated: "")
    @StateObject private var service_vm = ServiceViewModel(service: fake_service, errValue: false, loadingData: false)
    @State private var layoutID = UUID()
    
    @State private var locationAuthorised = false
    @State private var findingStation = true
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var nearestStation: NearestStationInfo = NearestStationInfo(stationName: "", stationCRS: "", latitude: 0.0, longitude: 0.0, distanceTo: 0.0)
    @State private var defaultStation: NearestStationInfo = NearestStationInfo(stationName: "", stationCRS: "", latitude: 0.0, longitude: 0.0, distanceTo: 0.0)
    
    @State private var position: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: .station,
            distance: 1300,
            heading: 0,
            pitch: 45
        )
    )

    
    let urlString = "https://d-railboard.pyxlwuff.dev/station/MAN"
    
    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGPoint = .zero

        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
    }
        
    struct StationJSONFileEntry : Codable {
        let stationName: String
        let lat: Double
        let long: Double
        let crsCode: String
        let constituentCountry: String
    }
    
    private func getNearestStation(){
        findingStation = true
        let locManager = CLLocationManager()
        locManager.requestWhenInUseAuthorization()
        
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled(){
                locationAuthorised = true
    //            locManager.delegate = self
                locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locManager.startUpdatingLocation()
                
                guard let location: CLLocationCoordinate2D = locManager.location?.coordinate else { return }
                print(location.latitude)
                print(location.longitude)
                latitude = location.latitude
                longitude = location.longitude
                findNearestStationFromLocation()
            }
        }
    }
    
    private func findNearestStationFromLocation(){
        let url = Bundle.stationsJSONBundleURL
        guard let data = try? Data(contentsOf: url) else { return }
        print("Data has been tried successfully")
        
        let decoder = JSONDecoder()
        
        guard let loadedFile = try? decoder.decode([StationJSONFileEntry].self, from: data) else { return }
        
        let radius: Double = 5.0 // All stations within 5 Miles
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
//        let userLocation = CLLocation(latitude: 51.530245, longitude: -0.123645)
        nearestStation = NearestStationInfo(stationName: "", stationCRS: "", latitude: 0.0, longitude: 0.0, distanceTo: 1000000.0)
        
        var possibleNearStations: [NearestStationInfo] = []
        
        loadedFile.enumerated().forEach { index, station in
            let stationLocation = CLLocation(latitude: station.lat, longitude: station.long)
            let distanceInMetres = userLocation.distance(from: stationLocation)
            let distanceInMiles = distanceInMetres * 0.00062137

            if distanceInMiles < radius {
                print("User is near: \(station.crsCode)")
//                nearestStation = NearestStationInfo(stationName: station.stationName, stationCRS: station.crsCode, distanceTo: distanceInMiles)
                possibleNearStations.append(NearestStationInfo(stationName: station.stationName, stationCRS: station.crsCode, latitude: station.lat, longitude: station.long, distanceTo: distanceInMiles))
            }
        }
        
        possibleNearStations.forEach { nearStation in
            if nearStation.distanceTo <= nearestStation.distanceTo {
                nearestStation = nearStation
            }
        }
        
        print("Nearest station found: \(nearestStation.stationCRS)")
        
        position = .camera(
            MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: nearestStation.latitude - 0.0008, longitude: nearestStation.longitude),
                distance: 1000,
                heading: 0,
                pitch: 45
            )
        )
        
        if nearestStation.stationCRS == "" {
            print("Couldn't find a nearby station")
        }else{
            vm.fetchData(crs: nearestStation.stationCRS)
        }
        
        findingStation = false
    }
    
    private func collapse() {
        withAnimation(.spring(duration: 0.35)) {
            expanded = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            layoutID = UUID()
        }
    }
    
    @State private var selectedPointsOfInterest: PointOfInterestCategories = .including([.publicTransport])
        
    var body: some View {
        NavigationStack {
            ZStack{
                VStack(alignment: .leading){
                    Map(position: $position){
                        Marker("", systemImage: "mappin.circle.fill", coordinate: CLLocationCoordinate2D(latitude: nearestStation.latitude, longitude: nearestStation.longitude))
                    }
                    .mapStyle(.standard(elevation: .realistic, pointsOfInterest: selectedPointsOfInterest, showsTraffic: false))
                    .accessibilityHidden(true)
                    .frame(maxWidth: .infinity, maxHeight: 380, alignment: .top)
                    Spacer()
                }
                
                
                GeometryReader { reader in
                    ScrollView {
                        Spacer(minLength: 210)
                        VStack(){
                            VStack{
                                Text("\(nearestStation.stationName)")
                                    .font(.title)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 20)
                                HStack{
                                    Group{
                                        Image(systemName: "location.fill")
                                            .foregroundStyle(Color.blue)
                                        Text("\(String(format: "%.2f", nearestStation.distanceTo))mi - Last updated \(vm.lastUpdated)")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.primary)
                                            .padding([.leading], -3.0)
                                    }
                                }
                            }
                            .padding()
                            
                            if locationAuthorised {
                                if findingStation == false && nearestStation.stationCRS != "" {
                                    ScrollView(.horizontal){
                                        LazyHStack {
                                            VStack(alignment: .leading){
                                                Text("Live Times")
                                                    .font(.title2).bold().padding(.top, 15).frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal)
                                                VStack{
                                                    DepartureCardView(style: .full, crs: nearestStation.stationCRS, expanded: true)
                                                        .environmentObject(vm)
                                                        .environmentObject(service_vm)
                                                        .padding(.bottom, 45)
                                                        .frame(minWidth: reader.size.width - 30, minHeight: reader.size.height, alignment: .top)

                                                }
                                                .glassEffect(in: .rect(cornerRadius: 29.0))
                                                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.35), radius: 10, x: 0, y: 0)
                                                Spacer()
                                            }
                                            
                                            VStack{
                                                Text("Service Status")
                                                    .font(.title2).bold().padding(.top, 15).frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal)
                                                VStack{
                                                    VStack(alignment: .leading){
                                                        Spacer()
                                                    }
                                                    .padding(15)
                                                    .frame(minWidth: reader.size.width - 30, alignment: .center)

                                                }
                                                .glassEffect(in: .rect(cornerRadius: 29.0))
                                                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.35), radius: 10, x: 0, y: 0)
                                                Spacer()
                                            }
                                            
                                            VStack{
                                                Text("Sample Page 3")
                                                    .font(.title2).bold().padding(.top, 15).frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.horizontal)
                                                VStack{
                                                    VStack(alignment: .leading){
                                                        Spacer()
                                                    }
                                                    .padding(15)
                                                    .frame(minWidth: reader.size.width - 18, alignment: .center)

                                                }
                                                .glassEffect(in: .rect(cornerRadius: 29.0))
                                                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.35), radius: 10, x: 0, y: 0)
                                                Spacer()
                                            }

                                        }
                                        .scrollTargetLayout()
                                    }
                                    .scrollTargetBehavior(.viewAligned)
                                    .safeAreaPadding(.horizontal, 10)
                                }
                            }
                            
//                                Rectangle()
//                                    .frame(maxWidth: .infinity, minHeight: 100).offset(x: 0, y: -7).foregroundStyle(Color.clear)
                        }
                        .frame(minHeight: reader.size.height)

//                            .background(
//                            )
                        .background(
                            LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                .glassEffect(.regular.tint(colorScheme == .dark ? .clear : .white), in: .rect(cornerRadius: 0))
                                .mask(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .black, .black, .black, .black, .black, .black, .black, .clear]), startPoint: .bottom, endPoint: .top))
                        )
//                            .ignoresSafeArea()
//                            .background(, in: RoundedRectangle(cornerRadius: 15.0))
//                            .glassEffect(in: .rect(cornerRadius: 16.0))
                        
                        
                    }
                    .edgesIgnoringSafeArea(.bottom)
                    .scrollEdgeEffectHidden()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    Button {

                    } label: {
                        Label("TEST", systemImage: "arrow.trianglehead.turn.up.right.diamond.fill").foregroundStyle(Color.blue)
                    }

                }
                    
                ToolbarItem(placement: .navigationBarTrailing) {
                  Menu {
                      NavigationLink {
                          SettingsPage()
                      } label: {
                          Text("Settings")
                      }

                      NavigationLink {
//                          SettingsPage()
                      } label: {
                          Text("About")
                      }
                  } label: {
                      Image(systemName: "ellipsis")
                          .fontWeight(.bold)
                  }
              }
            }
            .background(colorScheme == .dark ? Color.black : Color(red: 242/255, green: 242/255, blue: 247/255))
            .onAppear(){
                getNearestStation()
            }
            .overlay(alignment: .top) {
                if locationAuthorised {
                    if findingStation == false && nearestStation.stationCRS == "" {
                        ZStack{
                            VStack{
                                Text("No national rail stations near your current location.")
                                    .foregroundStyle(Color.white)
                                    .font(.title)
                            }.padding()
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .background(Color.primary)
                    }
                }else{
                    ZStack{
                        VStack{
                            Text("You'll need to grant access to your location to use the Here tab")
                                .foregroundStyle(Color.white)
                                .font(.title)
                        }.padding()
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(Color.primary)

                }
            }
        }
    }
}

#Preview {
    HereView()
}
