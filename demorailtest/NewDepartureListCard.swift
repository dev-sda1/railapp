//
//  NewDepartureListCard.swift
//  demorailtest
//
//  Created by James on 11/01/2026.
//

import SwiftUI
import Foundation
internal import Combine
import CoreLocation
import uk_railway_stations

let fake_departure_item = DepartureItem(
    origin: "Bedford",
    destination: "East Croydon",
    operator: "Thameslink",
    operatorCode: "TL",
    cancelled: false,
    headcode: "9T31",
    platformNo: "2",
    trainLength: 6,
    expectedDeparture: "2026-01-17T12:56:00",
    estimatedDeparture: "2026-01-17T12:56:00",
    isDelayed: false,
    delayLength: 0,
    rid: "202601178757929",
    uid: "W57929",
    sdd: "2026-01-17"
)

struct DepartureData : Codable {
    let locationName: String
    let generatedAt: String
    let filterType: String
    let departures: [DepartureItem]
}

struct DepartureItem: Codable, Identifiable {
    let id = UUID()
    var origin: String
    var destination: String
    var `operator`: String
    var operatorCode: String
    var cancelled: Bool
    var headcode: String
    var additionalServices: [DepartureItem]? = []
    var platformNo: String? = "Unknown"
    var trainLength: Int
    var expectedDeparture: String
    var estimatedDeparture: String? = "UNKN"
    var isDelayed: Bool
    var delayLength: Int
    var rid: String
    var uid: String
    var sdd: String
}

class DeparturesViewModel: ObservableObject {
    @Published var depList: [DepartureItem]
    @Published var loadingData: Bool
    @Published var lastUpdated: String
    
    init(depList: [DepartureItem], loadingData: Bool, lastUpdated: String) {
        self.depList = []
        self.loadingData = false
        self.lastUpdated = "never"
    
        fetchData(crs: "")
    }
    
    @MainActor
    func fetchData(crs: String){
        let urlString = "https://d-railboard.pyxlwuff.dev/station/\(crs)"
//        let urlString = "http://localhost:3000/station/\(crs)"

        guard !loadingData else { return }
        print("woof")
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        
        Task {
            self.loadingData = true
            let (data,_) = try await URLSession.shared.data(for: request)
            let json = try JSONDecoder().decode(DepartureData.self, from: data)
            
            do {
//                let (data,_) = try await URLSession.shared.data(for: request)
//                let json = try JSONDecoder().decode(DepartureData.self, from: data)
                self.depList = json.departures
                self.lastUpdated = Date.now.formatted(date: .omitted, time: .shortened)
            } catch{
                print(error)
            }
                        
            print("Latest fetch complete")
            self.loadingData = false
        }

    }
}

enum DepartureCardStyle {
    case list
    case full
}

struct DepartureCardView : View {
    let style: DepartureCardStyle
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State var crs: String
    @State var expanded: Bool
    @EnvironmentObject var vm: DeparturesViewModel
    @EnvironmentObject var service_vm: ServiceViewModel
    
    @State private var locationAuthorised = false
    @State private var findingStation = true
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var nearestStation: NearestStationInfo = NearestStationInfo(stationName: "", stationCRS: "", distanceTo: 0.0)
    @State private var loadingAnimation = false
    
    // Service Sheet Stuff
    @State private var showServiceSheet = false
    @State private var serviceSheetData: DepartureItem = fake_departure_item
    @State private var serviceSheetTRUSTData: DepartureTRUSTData = DepartureTRUSTData(rid: "", uid: "", sdd: "")
    
    struct StationJSONFileEntry : Codable {
        let stationName: String
        let lat: Double
        let long: Double
        let crsCode: String
        let constituentCountry: String
    }
    
    func formatTime(timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd'T'HH:mm:ss"
        
        var date = formatter.date(from: timeString)?.formatted(date: .omitted, time: .shortened) ?? "00:00"
        if date.count == 4 {
            date = "0\(date)"
        }
        //        print("\(formatter.date(from: timeString)?.formatted(date: .omitted, time: .shortened))")
        
        return date
    }
    
    var body: some View {
        switch style {
        case .list:
            VStack(alignment: .leading) {
                HStack(alignment: .center){
                    Text("Departures")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Color.primary)
                }.padding([.bottom], 10.0)
                
                if vm.loadingData == true {
                    VStack(alignment: .leading){
                        Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                            .opacity(loadingAnimation ? 0.6 : 1)
                            .animation(
                                loadingAnimation ?
                                    .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                    .default,
                                value: loadingAnimation
                            )
                            .onAppear {
                                loadingAnimation = true
                            }
                        
                        Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                            .opacity(loadingAnimation ? 0.6 : 1)
                            .animation(
                                loadingAnimation ?
                                    .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                    .default,
                                value: loadingAnimation
                            )
                            .onAppear {
                                loadingAnimation = true
                            }

                        Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                            .opacity(loadingAnimation ? 0.6 : 1)
                            .animation(
                                loadingAnimation ?
                                    .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                    .default,
                                value: loadingAnimation
                            )
                            .onAppear {
                                loadingAnimation = true
                            }

                        Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                            .opacity(loadingAnimation ? 0.6 : 1)
                            .animation(
                                loadingAnimation ?
                                    .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                    .default,
                                value: loadingAnimation
                            )
                            .onAppear {
                                loadingAnimation = true
                            }
                    }
                    .background(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color.white)
                    .cornerRadius(12.0)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.08), radius: 10, x: 0, y: 0)
                }else{
                    if vm.depList.isEmpty == false {
                        ForEach(vm.depList.prefix(4).enumerated(), id: \.offset){ index, departure in
                            let trust_data = DepartureTRUSTData(rid: departure.rid, uid: departure.uid, sdd: departure.sdd)
                            
                            if index == vm.depList.endIndex - 1 {
                                TrainDepartureCard(trust_data: trust_data, tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture, estimatedDepartureTime: departure.estimatedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, delayLength: departure.delayLength, cancelled: departure.cancelled)
                                    .padding([.top], 5.0)
                                    .padding([.bottom], 3.0)
                            }else{
                                TrainDepartureCard(trust_data: trust_data, tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture, estimatedDepartureTime: departure.estimatedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, delayLength: departure.delayLength, cancelled: departure.cancelled)
                            }
                        }
                    }else{
                        Text("No departures expected for the next two hours.")
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(Color.primary)
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
            .hoverEffect()
            .clipShape(.rect(cornerRadius: 16))
            .padding(.horizontal, 16)
            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.2), radius: 10, x: 0, y: 0)
            
            case .full:
            ScrollView{
                VStack(alignment: .leading, spacing: 0){
                    VStack(alignment: .leading, spacing: 0){
                        // Title
                        HStack(alignment: .center){
                            Text("Departures")
                                .font(.title).bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding([.bottom], 10.0)
                    
                    if vm.loadingData == true {
                        VStack(alignment: .leading){
                            Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                                .opacity(loadingAnimation ? 0.6 : 1)
                                .animation(
                                    loadingAnimation ?
                                        .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                        .default,
                                    value: loadingAnimation
                                )
                                .onAppear {
                                    loadingAnimation = true
                                }
                            
                            Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                                .opacity(loadingAnimation ? 0.6 : 1)
                                .animation(
                                    loadingAnimation ?
                                        .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                        .default,
                                    value: loadingAnimation
                                )
                                .onAppear {
                                    loadingAnimation = true
                                }
                            
                            Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                                .opacity(loadingAnimation ? 0.6 : 1)
                                .animation(
                                    loadingAnimation ?
                                        .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                        .default,
                                    value: loadingAnimation
                                )
                                .onAppear {
                                    loadingAnimation = true
                                }

                            
                            Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                                .opacity(loadingAnimation ? 0.6 : 1)
                                .animation(
                                    loadingAnimation ?
                                        .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                        .default,
                                    value: loadingAnimation
                                )
                                .onAppear {
                                    loadingAnimation = true
                                }

                            
                            Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                                .opacity(loadingAnimation ? 0.6 : 1)
                                .animation(
                                    loadingAnimation ?
                                        .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                        .default,
                                    value: loadingAnimation
                                )
                                .onAppear {
                                    loadingAnimation = true
                                }

                            
                            Rectangle().foregroundStyle(Color.gray).frame(maxWidth: .infinity, minHeight: 90)
                                .opacity(loadingAnimation ? 0.6 : 1)
                                .animation(
                                    loadingAnimation ?
                                        .easeInOut(duration: 1).repeatForever(autoreverses: true) :
                                        .default,
                                    value: loadingAnimation
                                )
                                .onAppear {
                                    loadingAnimation = true
                                }


                        }
                        .background(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color.white)
                        .cornerRadius(12.0)
                        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.08), radius: 10, x: 0, y: 0)
                    }else{
                        if vm.depList.isEmpty == false {
                            ForEach(vm.depList.enumerated(), id: \.offset) { index, departure in
                                let trust_data = DepartureTRUSTData(rid: departure.rid, uid: departure.uid, sdd: departure.sdd)
                                
                                if index == vm.depList.endIndex - 1 {
                                    Button {
                                        var temp_dep = departure
                                        
                                        let temp: DepartureItem = DepartureItem(origin: departure.origin, destination: departure.destination, operator: departure.operator, operatorCode: departure.operatorCode, cancelled: departure.cancelled, headcode: departure.headcode, trainLength: departure.trainLength, expectedDeparture: departure.expectedDeparture, estimatedDeparture: departure.estimatedDeparture ?? "UNKN", isDelayed: departure.isDelayed, delayLength: departure.delayLength, rid: departure.rid, uid: departure.uid, sdd: departure.sdd)
                                        
                                        temp_dep.additionalServices?.insert(temp, at: 0)
                                        
                                        serviceSheetData = temp_dep
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showServiceSheet.toggle()
                                        }
                                        
                                    } label: {
                                        TrainDepartureCard(trust_data: trust_data, tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture, estimatedDepartureTime: departure.estimatedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, delayLength: departure.delayLength, cancelled: departure.cancelled)
                                            .padding([.top], 5.0)
                                            .padding([.bottom], 5.0)
                                    }
//                                    NavigationLink{
//                                        ServiceView(serviceInfo: departure)
//                                            .environmentObject(service_vm)
//                                    } label: {
//                                        TrainDepartureCard(trust_data: trust_data, tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture, estimatedDepartureTime: departure.estimatedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, delayLength: departure.delayLength, cancelled: departure.cancelled)
//                                            .padding([.top], 5.0)
//                                            .padding([.bottom], 5.0)
//                                    }
                                }else{
                                    Button {
                                        var temp_dep = departure
                                        
                                        let temp: DepartureItem = DepartureItem(origin: departure.origin, destination: departure.destination, operator: departure.operator, operatorCode: departure.operatorCode, cancelled: departure.cancelled, headcode: departure.headcode, trainLength: departure.trainLength, expectedDeparture: departure.expectedDeparture, estimatedDeparture: departure.estimatedDeparture ?? "UNKN", isDelayed: departure.isDelayed, delayLength: departure.delayLength, rid: departure.rid, uid: departure.uid, sdd: departure.sdd)
                                        
                                        temp_dep.additionalServices?.insert(temp, at: 0)
                                        
                                        serviceSheetData = temp_dep
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showServiceSheet.toggle()
                                        }

                                    } label: {
                                        TrainDepartureCard(trust_data: trust_data, tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture, estimatedDepartureTime: departure.estimatedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, delayLength: departure.delayLength, cancelled: departure.cancelled)
                                            .padding([.top], 5.0)
                                            .padding([.bottom], 5.0)
                                    }
                                    
                                    
                                    
//                                    NavigationLink {
//                                        ServiceView(serviceInfo: departure)
//                                            .environmentObject(service_vm)
//                                    } label: {
//                                        TrainDepartureCard(trust_data: trust_data, tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture, estimatedDepartureTime: departure.estimatedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, delayLength: departure.delayLength, cancelled: departure.cancelled)
//                                            .padding([.top, .bottom], 5.0)
//                                    }
                                }
                            }
                        }else{
                            Text("No departures expected for the next two hours.")
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(Color.primary)

                        }
                    }
                }
                .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
                .padding()
                .sheet(isPresented: $showServiceSheet) {
                    NavigationStack{
                        TrainServiceSheet(currentDeparture: serviceSheetData, laterDepartures: serviceSheetData.additionalServices ?? [])
                        .toolbar {
                            Button(role: .close) {
                                showServiceSheet = false
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
                
            }
            .overlay {
                ZStack(alignment: .topTrailing){
                    closeButton
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
//            .ignoresSafeArea(.all, edges: [.top])
            .toolbar(.hidden)
            .statusBarHidden(true)
            .onAppear(){
                #if os(iOS)
                    UIImpactFeedbackGenerator.init(style: .heavy).impactOccurred()
                #endif
            }
            .scrollBounceBehavior(.always, axes: .vertical)
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark")
                .fontWeight(.bold)
                .padding(10)
        }
        #if os(iOS)
        .buttonStyle(.glass)
        #endif
        .clipShape(Circle())
    }

}


#Preview("List Style") {
    @Previewable @StateObject var vm = DeparturesViewModel(depList: [], loadingData: false, lastUpdated: "")
    @Previewable @StateObject var service_vm = ServiceViewModel(service: fake_service, errValue: false, loadingData: false)

    ScrollView {
        DepartureCardView(style: .list, crs: "EUS", expanded: false)
            .environmentObject(vm)
            .environmentObject(service_vm)
            .onAppear(){
                vm.fetchData(crs: "EUS")
            }
    }.background(Color(red: 242/255, green: 242/255, blue: 247/255))
}

#Preview("Detail Style"){
    @Previewable @StateObject var vm = DeparturesViewModel(depList: [], loadingData: false, lastUpdated: "")
    @Previewable @StateObject var service_vm = ServiceViewModel(service: fake_service, errValue: false, loadingData: false)

    NavigationStack{
        ScrollView{
            DepartureCardView(style: .full, crs: "MAN", expanded: true)
                .environmentObject(vm)
                .environmentObject(service_vm)
                .onAppear(){
                    vm.fetchData(crs: "MAN")
                }
        }
    }
}
