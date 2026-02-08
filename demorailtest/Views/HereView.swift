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
    @Environment(\.modelContext) private var context
    @Query private var recentlySearchedStations: [RecentlySearched]

    @Namespace private var stationNamespace
    
    var selectedStation: NearestStationInfo?
    @State private var scrollPosition: CGPoint = .zero
    @State private var collapsedScrollPosition: CGPoint = .zero

    @State private var loadingData: Bool = true
    @State private var depList: [DepartureItem] = []
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

    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGPoint = .zero

        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
    }
    
    private func loadProvidedStation(stnData: NearestStationInfo) async {
        self.findingStation = true
        self.nearestStation = stnData
        await self.vm.fetchData(crs: stnData.stationCRS)
        self.findingStation = false
    }
             
    private func getNearestStation() async {
        self.findingStation = true
        self.nearestStation = await findNearestStationFromLocation(radius: 5.0)
        
        print(nearestStation)
        
        self.position = .camera(
            MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: nearestStation.latitude, longitude: nearestStation.longitude),
                distance: 800,
                heading: 0,
                pitch: 45
            )
        )
                
        if nearestStation.stationCRS == "" {
            print("Couldn't find a nearby station")
        }else{
            await self.vm.fetchData(crs: nearestStation.stationCRS)
        }
        
        self.findingStation = false
    }
    
    private func addToRecentlySearched(station: RecentlySearchedSchema){
        let item = RecentlySearched(station_info: station)
        var already_searched_recently = false
        
        recentlySearchedStations.prefix(6).enumerated().forEach{ index, list in
            if(item.station.crsCode == list.station.crsCode){
                context.delete(list)
                context.insert(item)
                already_searched_recently = true
                print("Moved item to top of list.")
            }
        }
        
        if(already_searched_recently == false){
            context.insert(item)
            print("Inserted item for first time.")
        }
        
        if(recentlySearchedStations.count > 6){
            guard let bottom_item_index = recentlySearchedStations.last else { return }
            context.delete(bottom_item_index)
        }
    }

        
    @State private var selectedPointsOfInterest: PointOfInterestCategories = .including([.publicTransport])
    @State private var allowMapControl: Bool = false
    @State private var allowMapControlWillChange: Bool = false
        
    var body: some View {
        NavigationStack {
            GeometryReader { reader in
              
                ScrollView {
                    ZStack(alignment: .top) {
                        //  Map
                        GeometryReader { mapReader in
                            let offsetY = mapReader.frame(in: .global).minY
                            let height = (allowMapControl == true ? 680 : 550) + (offsetY > 0 ? offsetY : 0)
                                                                            
                            Spacer()
                                .frame(width: mapReader.size.width, height: height)
                                .background {
                                    Map(position: $position, interactionModes: allowMapControl == true ? [.all] : []){
                                        Marker("", systemImage: "mappin.circle.fill", coordinate: CLLocationCoordinate2D(latitude: nearestStation.latitude, longitude: nearestStation.longitude))
                                    }
                                    .mapStyle(.standard(elevation: .realistic, pointsOfInterest: selectedPointsOfInterest, showsTraffic: false))
                                    .accessibilityHidden(true)
                                    .padding(.bottom, allowMapControl == true ? 40 : 0)
                                    .clipped()
                                    .offset(y: offsetY > 0 ? -offsetY : 0)
                                    .zIndex(1)
                                }
                        }
                        .frame(height: allowMapControl == true ? 680 : 550)
                        
                        if allowMapControl == true {
                            VStack {
                                Spacer()
                                VStack {
                                    Text("\(nearestStation.stationName)")
                                        .font(.title)
                                        .bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 20)
                                    
                                    HStack {
                                        Group {
                                            if nearestStation.distanceTo != -1.0 {
                                                Image(systemName: "location.fill")
                                                    .foregroundStyle(Color.blue)
                                                
                                                Text("\(String(format: "%.2f", nearestStation.distanceTo))mi - Last updated \(vm.lastUpdated)")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .font(.subheadline)
                                                    .foregroundStyle(Color.primary)
                                                    .padding([.leading], -3.0)
                                                Text("\(scrollPosition.y)")
                                            }else{
                                                Text("Last updated \(vm.lastUpdated)")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .font(.subheadline)
                                                    .foregroundStyle(Color.primary)
                                                    .padding([.leading], -3.0)
                                                Text("\(scrollPosition.y)")
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .padding(.bottom, 200)
                                .edgesIgnoringSafeArea(.all)
//                                .background(Color.white)
                                .background(
                                    LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                        .glassEffect(.regular.tint(colorScheme == .dark ? .clear : .white), in: .rect(cornerRadius: 0))
                                        .mask(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .black, .black, .black, .black, .black, .black, .black, .clear]), startPoint: .bottom, endPoint: .top))
                                )
                                .offset(x: 0, y: 250)
                            }
                            .matchedGeometryEffect(id: "stnName1", in: stationNamespace)
                            .zIndex(2)
                            .background(GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                            })
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                self.scrollPosition = value
                            }
                        }else{
                            VStack {
                                Spacer(minLength: 400)
                                VStack {
                                    Text("\(nearestStation.stationName)")
                                        .font(.title)
                                        .bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 20)
                                    
                                    HStack {
                                        Group {
                                            if nearestStation.distanceTo != -1.0 {
                                                Image(systemName: "location.fill")
                                                    .foregroundStyle(Color.blue)
                                                
                                                Text("\(String(format: "%.2f", nearestStation.distanceTo))mi - Last updated \(vm.lastUpdated)")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .font(.subheadline)
                                                    .foregroundStyle(Color.primary)
                                                    .padding([.leading], -3.0)
                                                Text("\(scrollPosition.y)")
                                            }else{
                                                Text("Last updated \(vm.lastUpdated)")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .font(.subheadline)
                                                    .foregroundStyle(Color.primary)
                                                    .padding([.leading], -3.0)
                                                Text("\(scrollPosition.y)")
                                            }
                                        }
                                    }
                                }
                                .padding()
                                
                                if (findingStation == false && nearestStation.stationCRS != "") || selectedStation?.stationCRS != "" {
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
                            .matchedGeometryEffect(id: "stnName0", in: stationNamespace)
                            .background(
                                LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                    .glassEffect(.regular.tint(colorScheme == .dark ? .clear : .white), in: .rect(cornerRadius: 0))
                                    .mask(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .bottom, endPoint: .top))
                            )
                            .zIndex(2)
                            .background(GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                            })
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                self.scrollPosition = value
                            }

                        }
                        
                        // Train Services
                        
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .scrollEdgeEffectHidden()
                .coordinateSpace(name: "scroll")
                .onScrollPhaseChange { oldPhase, newPhase in
                    if newPhase == .decelerating{
                        if allowMapControl == true {
                            if scrollPosition.y < -150 {
                                print("Will return to departure card view")
                                self.allowMapControlWillChange = true
                            }
                        }else{
                            if scrollPosition.y > -95 {
                                print("Will return to departure card view")
                                allowMapControlWillChange = true
                            }
                        }
                        
                        if allowMapControlWillChange == true {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                self.allowMapControl.toggle()
                                self.allowMapControlWillChange.toggle()
                            }
                        }

                    }
                                        
//                    if oldPhase == .decelerating && newPhase == .idle {
//                        if allowMapControl == true {
//                            if scrollPosition.y < -180 {
//                                print("Will return to departure card view")
//                            }
//                        }
//                    }
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
            .task {
                if selectedStation?.stationCRS == "" {
                    await getNearestStation()
                }else{
                    guard let selected = selectedStation.self else { return await getNearestStation() }
                    
                    self.position = .camera(
                        MapCamera(
                            centerCoordinate: CLLocationCoordinate2D(latitude: selected.latitude, longitude: selected.longitude),
                            distance: 800,
                            heading: 0,
                            pitch: 45
                        )
                    )
                    
                    addToRecentlySearched(station: RecentlySearchedSchema(stationName: selected.stationName, crsCode: selected.stationCRS, latitude: selected.latitude, longitude: selected.longitude))
                    await loadProvidedStation(stnData: selected)
                }
            }
        }
    }
}

#Preview {
    HereView(selectedStation: NearestStationInfo(stationName: "Manchester Piccadilly", stationCRS: "MAN", latitude: 53.47736139295, longitude: -2.23090989998, distanceTo: -1.0))
}
