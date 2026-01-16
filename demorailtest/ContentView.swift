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
    @State private var selection: TabKey = .live
    @State var scrollText = true
    @State var searchTxt = ""
    
    var body: some View {
        TabView(selection: $selection) {
            Tab("Live Trains", systemImage: "clock.badge.fill", value: TabKey.live) {
                SwiftUIView1()
            }
            
            Tab("Journeys", systemImage: "tram.fill", value: TabKey.journeys) {
                SwiftUIView2()
            }
            
            Tab(value: TabKey.search, role: .search) {
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
    case live, journeys, search
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
    var distanceTo: Double
}

struct SwiftUIView1: View {
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
    @State private var nearestStation: NearestStationInfo = NearestStationInfo(stationName: "", stationCRS: "", distanceTo: 0.0)
    
    let urlString = "https://d-railboard.pyxlwuff.dev/station/MAN"
//    let urlString = "http://localhost:3000/station/MAN"
    
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
//        let userLocation = CLLocation(latitude: 53.218229, longitude: -2.636667)
        nearestStation = NearestStationInfo(stationName: "", stationCRS: "", distanceTo: 1000000.0)
        
        var possibleNearStations: [NearestStationInfo] = []
        
        loadedFile.enumerated().forEach { index, station in
            let stationLocation = CLLocation(latitude: station.lat, longitude: station.long)
            let distanceInMetres = userLocation.distance(from: stationLocation)
            let distanceInMiles = distanceInMetres * 0.00062137

            if distanceInMiles < radius {
                print("User is near: \(station.crsCode)")
//                nearestStation = NearestStationInfo(stationName: station.stationName, stationCRS: station.crsCode, distanceTo: distanceInMiles)
                possibleNearStations.append(NearestStationInfo(stationName: station.stationName, stationCRS: station.crsCode, distanceTo: distanceInMiles))
            }
        }
        
        possibleNearStations.forEach { nearStation in
            if nearStation.distanceTo <= nearestStation.distanceTo {
                nearestStation = nearStation
            }
        }
        
        print("Nearest station found: \(nearestStation.stationCRS)")
        
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
        
    var body: some View {
            NavigationStack {
                ZStack{
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            Text("\(nearestStation.stationName ?? "Finding Station")")
                                .font(.title).bold()
                                .foregroundStyle(Color.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack{
                                Group{
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(Color.blue)
                                    Text("\(String(format: "%.2f", nearestStation.distanceTo))mi - Last updated \(vm.lastUpdated)")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.subheadline).bold()
                                        .foregroundStyle(Color.blue)
                                        .padding([.leading], -3.0)
                                }
                                
                                Button("Refresh", systemImage: "arrow.clockwise", action: {
                                    getNearestStation()
                                })
                                .font(.subheadline).bold()
                                .padding(.trailing, 2)
                            }
                        }
                        .coordinateSpace(name: "scroll")
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
                        if locationAuthorised {
                            if findingStation == false && nearestStation.stationCRS != "" {
                                NavigationLink {
                                    DepartureCardView(style: .full, crs: nearestStation.stationCRS, expanded: true)
                                        .navigationTransition(.zoom(sourceID: "card", in: cardNamespace))
                                        .environmentObject(vm)
                                        .environmentObject(service_vm)
                                        .zIndex(100)
                                        
                                } label: {
                                    DepartureCardView(style: .list, crs: nearestStation.stationCRS, expanded: false)
                                        .environmentObject(vm)
                                        .environmentObject(service_vm)
                                }
                                .matchedTransitionSource(id: "card", in: cardNamespace)
                                .buttonStyle(ScaledButtonStyle())
                            }else{
                                Text("Unfortunately, there are no stations near your current location.")
                            }
                        }else{
                            Text("You'll need to grant access to your location to use this.")
                        }
                    }.overlay{
//                        if expanded && locationAuthorised {
//                            DepartureList(onClose: collapse, expanded: expanded, crs: nearestStation.stationCRS, )
//                                .environmentObject(vm)
//                                .matchedGeometryEffect(id: "departures", in: cardNamespace)
//                                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                .zIndex(100)
//                                .scaleEffect(expanded ? 1 : 0.90)
//                        }
                    }
                }
                .background(colorScheme == .dark ? Color.black : Color(red: 242/255, green: 242/255, blue: 247/255))
                .navigationTitle("Live Trains")
                .font(.headline)
                .navigationBarItems(trailing: expanded == true ? nil : Menu {
                    Button("Settings", action: {})
                    Button("About", action: {})
                } label: {
                    Image(systemName: "list.bullet")
                        .fontWeight(.bold)
                }.clipShape(Circle()))
                

                .onAppear(){
                    getNearestStation()
                }
            }
    }
}

struct SwiftUIView2: View {
    var body: some View {
        Text("View 2")
    }
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
    @State private var nearestStation: NearestStationInfo = NearestStationInfo(stationName: "", stationCRS: "", distanceTo: 0.0)
    
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
                    possibleNearStations.append(NearestStationInfo(stationName: station.stationName, stationCRS: station.crsCode, distanceTo: distanceInMiles))
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
