//
//  ContentView.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//

import SwiftUI
import CoreLocation
import uk_railway_stations

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
        .tabViewBottomAccessory {
            BottomAccessoryView()
        }
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

struct NearestStationInfo {
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
    @State private var layoutID = UUID()
    
    @State private var locationAuthorised = false
    @State private var findingStation = true
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var nearestStation: NearestStationInfo = NearestStationInfo(stationName: "", stationCRS: "", distanceTo: 0.0)
    
//    let urlString = "https://d-railboard.pyxlwuff.dev/station/MAN"
    let urlString = "http://localhost:3000/station/MAN"
    
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
//        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        let userLocation = CLLocation(latitude: 51.530637, longitude: -0.123961)
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
                                        .zIndex(100)
                                        
                                } label: {
                                    DepartureCardView(style: .list, crs: nearestStation.stationCRS, expanded: false)
                                        .environmentObject(vm)
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

struct SwiftUIView3: View {
    @State private var searchText = ""
    
    private let items = [
        "Item1",
        "Item2",
        "Item3",
        "Item4",
        "Item5",
        "Item6",
        "Item7",
        "Item8",
        "Item9",
        "Item10",
        "Item11",
        "Item12",
    ]
    
    private var filteredItems: [String] {
        if searchText.isEmpty { return items }
        return items.filter {$0.localizedCaseInsensitiveContains(searchText)}
    }
    
    var body: some View {
        NavigationStack {
            List(filteredItems, id: \.self) { item in
                Text(item)
            }
            .background(Color(red: 242/255, green: 242/255, blue: 247/255))
            .navigationTitle("Search")
        }
        .searchable(text: $searchText)
    }
}
