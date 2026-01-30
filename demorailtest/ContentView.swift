//
//  ContentView.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//

import SwiftUI
import CoreLocation
import uk_railway_stations
import Ifrit
import SwiftData

struct ContentView: View {
    @State private var selection: TabKey = .here
    @State var scrollText = true
    @State var searchTxt = ""
    
    var body: some View {
        TabView(selection: $selection) {
            Tab("Here", systemImage: "location.fill", value: TabKey.here) {
                HereView()
            }
            
            Tab("Journeys", systemImage: "tram.fill", value: TabKey.journeys) {
                PinnedServicesView()
            }
            
            Tab("Live Trains", systemImage: "clock.badge.fill", value: TabKey.live) {
                SwiftUIView3()
            }
            
        }
        
        .tabBarMinimizeBehavior(.onScrollDown)
        // TODO: Come back to tabViewBottomAccessory at a later date.
//        .tabViewBottomAccessory {
//            BottomAccessoryView()
//        }
    }
}

#Preview {
    ContentView()
}

private enum TabKey: Hashable {
    case here, live, journeys
}

struct BottomAccessoryView: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement

    var body: some View {
        switch placement{
        case .inline:
            BottomViewInline()
        case .expanded:
            BottomViewExpanded()
        case .none:
            BottomViewInline()
        }
    }
}

struct BottomViewExpanded: View {
    @State private var txtOffset = 10.0

    var body: some View {
        HStack {
            Spacer(minLength: 13.0)
            Image(.avanti).resizable().frame(width: 33, height: 33).cornerRadius(6.0)
            
            VStack(alignment: .leading) {
                Text("18:30 to Liverpool Lime Street")
                    .font(.footnote)
                    .fixedSize()
                
                HStack {
                    Group {
                        Text("ETA 20:07 ")
                            .font(.footnote)
                            .foregroundColor(.primary) +
                        Text("(On time)")
                            .font(.footnote)
                            .foregroundColor(.green) +
                        Text(" • Next Stop: Liverpool South Parkway")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: txtOffset, y: 0)
                    .animation(.linear(duration: 10).repeatForever(autoreverses: true))
                    .onAppear {
                        txtOffset = -170.0
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                .clipped()
            }
            
            HStack{
                Text("25 stops")
                    .font(.footnote)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.up")
                    .resizable()
                    .frame(width: 11, height: 7)
            }
            .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 10.0)
        }.containerRelativeFrame(
            [.horizontal, .vertical],
            alignment: .center
        )
    }
}

struct BottomViewInline: View {
    @State private var txtOffset = 15.0

    var body: some View {
        HStack {
            Spacer()
            Image(.avanti).resizable().frame(width: 33, height: 33).cornerRadius(6.0)
            
            VStack(alignment: .leading) {
                Text("25 stops")
                    .font(.footnote)
                    .fixedSize()
                
                HStack {
                    Group {
                        Text("ETA 20:07 ")
                            .font(.footnote)
                            .foregroundColor(.primary) +
                        Text("(On time)")
                            .font(.footnote)
                            .foregroundColor(.green) +
                        Text(" • Next Stop: Liverpool South Parkway")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: txtOffset, y: 0)
                    .animation(.linear(duration: 10).repeatForever(autoreverses: true))
                    .onAppear {
                        txtOffset = -200.0
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                .clipped()
                
            }
            
            HStack{
                Image(systemName: "chevron.up")
                    .resizable()
                    .frame(width: 11, height: 7)
            }
            
            Spacer()
        }.containerRelativeFrame(
            [.horizontal, .vertical],
            alignment: .center
        )
    }
}

struct NearestStationInfo: Hashable {
    var stationName: String
    var stationCRS: String
    var latitude: Double
    var longitude: Double
    var distanceTo: Double
}

struct Stations: Searchable {
    let stationName: String
    let crsCode: String
    
    var properties: [FuseProp] { [stationName,crsCode].map{ FuseProp($0) } }
}

struct SwiftUIView3: View {
    struct StationJSONFileEntry : Codable {
        let stationName: String
        let lat: Double
        let long: Double
        let crsCode: String
        let constituentCountry: String
    }
    
    struct StationSearchResult: Codable, Hashable{
        let stationName: String
        let crsCode: String
    }
    
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme

    @Query private var recentSearchedQuery: [RecentlySearched]
    @State private var recentlySearchedStations: [RecentlySearched] = []
    
    @State private var stationData: [Stations] = []
    @State private var searchResults: [StationSearchResult] = []
    @State private var stationsFile: [StationJSONFileEntry] = []
    @State private var nearbyStations: [NearestStationInfo] = []
    @State private var searchText = ""
    @State private var locating = false
    
    @State private var locationAuthorised = false
    @State private var findingStation = true
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var nearestStation: NearestStationInfo = NearestStationInfo(stationName: "", stationCRS: "", latitude: 0.0, longitude: 0.0, distanceTo: 0.0)
    
    private func getNearbyStations(){
        guard !locating else { return }

        locating = true
        nearbyStations = [];
        let radius: Double = 5.0 // All stations within 5 Miles
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
//        let userLocation = CLLocation(latitude: 51.514266, longitude: -0.303593)
        
        var possibleNearStations: [NearestStationInfo] = []
        
        stationsFile.enumerated().forEach { index, station in
            let stationLocation = CLLocation(latitude: station.lat, longitude: station.long)
            let distanceInMetres = userLocation.distance(from: stationLocation)
            let distanceInMiles = distanceInMetres * 0.00062137

            if distanceInMiles < radius {
                var duplicate = false
//                print("User is near: \(station.crsCode)")
//                nearestStation = NearestStationInfo(stationName: station.stationName, stationCRS: station.crsCode, distanceTo: distanceInMiles)
                
                // Very very rough workaround for weird duplicate results in the nearby stations list.
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
        
        nearbyStations = Array(possibleNearStations.prefix(6))
        findingStation = false
        locating = false
    }
    
    private func getNearestStation(){
        findingStation = true
        let locManager = CLLocationManager()
        locManager.requestWhenInUseAuthorization()
        
        DispatchQueue.global().async {
            let url = Bundle.stationsJSONBundleURL
            guard let data = try? Data(contentsOf: url) else { return }
            print("Data has been tried successfully")
            
            let decoder = JSONDecoder()
            
            guard let loadedFile = try? decoder.decode([StationJSONFileEntry].self, from: data) else { return }
            
            loadedFile.enumerated().forEach { index, station in
                let data: Stations = Stations(stationName: station.stationName, crsCode: station.crsCode)
                stationData.append(data)
                stationsFile.append(station)
            }

            
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
                                
                getNearbyStations()
            }
        }
    }

    private var filteredItems: [StationSearchResult] {
        if(searchText == ""){ // Prevent weird lag spikes by it trying to repeatedly search an empty string.
            return []
        }else{
            let fuse = Fuse()
            let resultsSync = fuse.searchSync(searchText, in: stationData) { station in
                    [
                        FuseProp(station.stationName, weight: 0.18),
                        FuseProp(station.crsCode, weight: 0.82)
                    ]
            }
            
            var filteredStations: [StationSearchResult] = []
            
            filteredStations = resultsSync.prefix(6).map{ (index, _, matchedRanges) in
                let stn = stationData[index]
                
                return StationSearchResult(stationName: stn.stationName, crsCode: stn.crsCode)
            }
            
            return Array(filteredStations.prefix(5))

        }
        
        
//        if searchText.isEmpty { return items }
//        return items.filter {$0.localizedCaseInsensitiveContains(searchText)}
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { g in
                ScrollView{
                    if(searchText == "" && findingStation == false){
                        VStack(alignment: .leading){
                            VStack(alignment: .leading){
                                HStack{
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(Color.blue)
                                    Text("Nearby Stations")
                                        .font(.title2).bold()
                                        .frame(alignment: .leading)
                                        .foregroundStyle(Color.blue)
                                }
                                
                                List {
                                    ForEach(nearbyStations.prefix(6), id: \.self) {item in
                                        NavigationLink {
                                            StationView(crsCode: item.stationCRS, stationName: item.stationName)
                                        } label: {
                                            Text("\(item.stationName) (\(item.stationCRS)) - \(String(format: "%.2f", item.distanceTo))mi")
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundStyle(Color.primary)
                                                .swipeActions(edge: .trailing){
                                                    Button(role: .confirm) {
                                                        
                                                    } label: {
                                                        Label("Add to Favourites", systemImage: "star.fill")
                                                    }
                                                }
                                        }

                                    }.listRowBackground(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
                                }
                                .frame(height: CGFloat((nearbyStations.count * 53)), alignment: .top)
                                .padding([.trailing, .leading], -16.0)
                                .scrollContentBackground(.hidden)
                                .listStyle(.plain)

                            }
                            .padding()
                            .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
                            .hoverEffect()
                            .clipShape(.rect(cornerRadius: 16))

                            
                            if(recentlySearchedStations.isEmpty == false){
                                VStack(alignment: .leading){
                                    Text("Recently Searched")
                                        .font(.title2).bold()
                                        .frame(alignment: .leading)
                                        .foregroundStyle(.primary)
                                    
                                    List {
                                        ForEach(recentlySearchedStations.prefix(6), id: \.self) {searchItem in
                                            NavigationLink {
                                                StationView(crsCode: searchItem.station.crsCode, stationName: searchItem.station.stationName)
                                            } label: {
                                                Text("\(searchItem.station.stationName) (\(searchItem.station.crsCode))")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .foregroundStyle(Color.primary)
                                                    .swipeActions(edge: .trailing){
                                                        Button(role: .confirm) {
                                                            
                                                        } label: {
                                                            Label("Add to Favourites", systemImage: "star.fill")
                                                        }
                                                    }
                                            }
                                        }.listRowBackground(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
                                    }
                                    .frame(height: CGFloat((recentlySearchedStations.count * 53)), alignment: .top)
                                    .frame(maxWidth: .infinity)
                                    .padding([.trailing, .leading], -16.0)
                                    .scrollContentBackground(.hidden)
                                    .listStyle(.plain)
                                }
                                .padding()
                                .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
                                .hoverEffect()
                                .clipShape(.rect(cornerRadius: 16))
                                .padding(.top, 15)
                            }

                        }.padding()
                    }else{
                        List(filteredItems, id: \.self) { filtereditem in
                            NavigationLink {
                                StationView(crsCode: filtereditem.crsCode, stationName: filtereditem.stationName)
                            } label: {
                                Text("\(filtereditem.stationName) (\(filtereditem.crsCode))")
                            }
                        }.frame(width: g.size.width, height: g.size.height, alignment: .center)
                    }
                }
            }
            .navigationTitle("Search")
        }
        .searchable(text: $searchText)
        .onAppear(){
            print("Opening Station List")
            recentlySearchedStations = Array(recentSearchedQuery.prefix(6))
            getNearestStation()
        }
    }
}
