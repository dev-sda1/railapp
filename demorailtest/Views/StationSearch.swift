//
//  StationSearch.swift
//  demorailtest
//
//  Created by James on 04/02/2026.
//

import SwiftUI
import uk_railway_stations
import SwiftData
import Ifrit

struct Stations: Searchable {
    let stationName: String
    let crsCode: String
    let latitude: Double
    let longitude: Double
    
    var properties: [FuseProp] { [stationName,crsCode].map{ FuseProp($0) } }
}

struct StationSearch: View {
    struct StationSearchResult: Codable, Hashable{
        let stationName: String
        let crsCode: String
        let latitude: Double
        let longitude: Double
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
    
    private func getNearbyStations() async {
        guard !locating else { return }
        locating = true
        
        let url = Bundle.stationsJSONBundleURL
        guard let data = try? Data(contentsOf: url) else { return }
        print("Data has been tried successfully")
        
        let decoder = JSONDecoder()
        
        guard let loadedFile = try? decoder.decode([StationJSONFileEntry].self, from: data) else { return }
        
        loadedFile.enumerated().forEach { index, station in
            let data: Stations = Stations(stationName: station.stationName, crsCode: station.crsCode, latitude: station.lat, longitude: station.long)
            stationData.append(data)
            stationsFile.append(station)
        }
        
        nearbyStations = await Array(getNearestStationsFromLocation(radius: 5.0).prefix(6))
        findingStation = false
        locating = false
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
                
                return StationSearchResult(stationName: stn.stationName, crsCode: stn.crsCode, latitude: stn.latitude, longitude: stn.longitude)
            }
            
            return Array(filteredStations.prefix(5))

        }
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
                                            HereView(selectedStation: NearestStationInfo(stationName: item.stationName, stationCRS: item.stationCRS, latitude: item.latitude, longitude: item.longitude, distanceTo: item.distanceTo))
//                                            StationView(crsCode: item.stationCRS, stationName: item.stationName)
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
                            #if os(iOS) || os(visionOS)
                            .hoverEffect()
                            #endif
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
                                                HereView(selectedStation: NearestStationInfo(stationName: searchItem.station.stationName, stationCRS: searchItem.station.crsCode, latitude: searchItem.station.latitude, longitude: searchItem.station.longitude, distanceTo: -1.0))
//                                                StationView(crsCode: searchItem.station.crsCode, stationName: searchItem.station.stationName)
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
                                #if os(iOS) || os(visionOS)
                                .hoverEffect()
                                #endif
                                .clipShape(.rect(cornerRadius: 16))
                                .padding(.top, 15)
                            }

                        }.padding()
                    }else{
                        List(filteredItems, id: \.self) { filtereditem in
                            NavigationLink {
                                HereView(selectedStation: NearestStationInfo(stationName: filtereditem.stationName, stationCRS: filtereditem.crsCode, latitude: filtereditem.latitude, longitude: filtereditem.longitude, distanceTo: -1.0))
//                                StationView(crsCode: filtereditem.crsCode, stationName: filtereditem.stationName)
                            } label: {
                                Text("\(filtereditem.stationName) (\(filtereditem.crsCode))")
                            }
                        }.frame(width: g.size.width, height: g.size.height, alignment: .center)
                    }
                }
            }
            .navigationTitle("Search")
        }
        #if os(macOS)
        .searchable(text: $searchText, placement: .sidebar)
        #else
        .searchable(text: $searchText)
        #endif
        .task {
            print("Opening Station List")
            recentlySearchedStations = Array(recentSearchedQuery.prefix(6))
            await getNearbyStations()
        }
    }
}

#Preview {
    StationSearch()
}
