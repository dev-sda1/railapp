//
//  ContentView.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//

import SwiftUI
import CoreLocation
import uk_railway_stations
import SwiftData

#Preview {
    StationView(crsCode: "MAN", stationName: "Manchester Piccadilly")
}

struct StationView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var context
    @Query private var recentlySearchedStations: [RecentlySearched]

    @Namespace private var stnCardNamespace
    @State private var loadingData: Bool = true
    @State private var depList: [DepartureItem] = []
    @State var expanded = false
    @State var activeId = UUID()
    @State private var fullyExpanded = false
    @State private var safeFrame: CGRect = .zero
    @StateObject private var vm = DeparturesViewModel(depList: [], loadingData: false, lastUpdated: "")
    @StateObject private var service_vm = ServiceViewModel(service: fake_service, errValue: false, loadingData: false)
    @State private var layoutID = UUID()
    var crsCode: String
    var stationName: String
            
    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGPoint = .zero

        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
    }
        
    private func collapse() {
        withAnimation(.spring(duration: 0.35)) {
            expanded = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            layoutID = UUID()
        }
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
        
    var body: some View {
            NavigationStack {
                ZStack{
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            HStack{
                                Group{
                                    Text("Last updated \(vm.lastUpdated)")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.subheadline).bold()
                                        .foregroundStyle(Color.blue)
                                        .padding([.leading], -3.0)
                                }
                                
                                Button("Refresh", systemImage: "arrow.clockwise", action: {
                                    vm.fetchData(crs: crsCode)
                                })
                                .font(.subheadline).bold()
                                .padding(.trailing, 2)
                            }
                        }
                        .coordinateSpace(name: "scroll")
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
                        NavigationLink {
                            DepartureCardView(style: .full, crs: crsCode, expanded: true)
                                .navigationTransition(.zoom(sourceID: "card", in: stnCardNamespace))
                                .environmentObject(vm)
                                .environmentObject(service_vm)
                                .zIndex(100)
                                
                        } label: {
                            DepartureCardView(style: .list, crs: crsCode, expanded: false)
                                .environmentObject(vm)
                                .environmentObject(service_vm)
                        }
                        .matchedTransitionSource(id: "card", in: stnCardNamespace)
                        .buttonStyle(ScaledButtonStyle())
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
                .navigationTitle("\(stationName)")
                .font(.headline)

                .onAppear(){
                    addToRecentlySearched(station: RecentlySearchedSchema(stationName: stationName, crsCode: crsCode))
                    vm.fetchData(crs: crsCode)
                }
            }
    }
}
