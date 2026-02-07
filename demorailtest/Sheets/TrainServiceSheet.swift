//
//  TrainServiceSheet.swift
//  demorailtest
//
//  Created by James on 17/01/2026.
//

import SwiftUI
import SwiftData

struct CurrentServiceAPIError: Codable {
    var error: String
}

struct JourneyArraySchema: Codable, Identifiable {
    let id = UUID()
    var locationName: String
    var crs: String
    var isPass: Bool
    var isCancelled: Bool
    var platform: String? = "Unknown"
    var std: String? = ""
    var etd: String? = ""
    var atd: String? = ""
    var sta: String? = ""
    var eta: String? = ""
    var ata: String? = ""
    var lateness: Int? = 0
}

struct CurrentServiceAPIResult: Codable {
    var headcode: String? = ""
    var `operator`: String
    var operatorCode: String
    var origin: String
    var destination: String
    var cancelled: Bool
    var cancelReason: String? = ""
    var journey: [JourneyArraySchema]
}

//final actor ServiceRefreshService {
//    private var serviceTask: Task<(), Error>?
//    
//    func start(){
//        guard serviceTask == nil else {
//            return
//        }
//        
//        serviceTask = Task {
//            repeat {
//                try await Task.sleep(for: .seconds(30))
//                
//            } while !Task.isCancelled
//        }
//    }
//    
//    func stop(){
//        serviceTask?.cancel()
//        serviceTask = nil
//    }
//}


struct TrainServiceSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var context
    
    @Query private var pinnedServiceQuery: [PinnedService]
    @State private var serviceData: CurrentServiceAPIResult = CurrentServiceAPIResult(headcode: "", operator: "", operatorCode: "", origin: "", destination: "", cancelled: false, cancelReason: "", journey: [])
    @State private var fetchingServiceData = false
    @State private var firstRoundFetched = false
    @State private var refreshingData = false
    @State private var isPinned = false
    
    @State var currentDeparture: DepartureItem
    @State var laterDepartures: [DepartureItem]
    @State private var allPinnedServices: [PinnedService] = []

    @State private var isDarwin = AppSettingsManager().useDarwin
    @State private var task: Task<(), Error>?

    func fetchData(uid: String, sdd: String){
        guard task == nil else { return }
        
        self.allPinnedServices = Array(pinnedServiceQuery)
        self.allPinnedServices.forEach { pinnedServiceItem in
            print(pinnedServiceItem.pinned_service.rid)
            if pinnedServiceItem.pinned_service.rid == currentDeparture.rid {
                self.isPinned = true
            }
        }

            
        var urlString = "https://d-railboard.pyxlwuff.dev/service/new/\(uid)/\(sdd)/standard"
        
        if isDarwin == true {
            urlString = "https://d-railboard.pyxlwuff.dev/service/new/\(uid)/\(sdd)/standard"
        }else{
            urlString = "https://d-railboard.pyxlwuff.dev/service/\(uid)/\(sdd)/standard"
        }
                
        guard !fetchingServiceData || !refreshingData else { return }
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        
        
        task = Task {
            repeat {
                if firstRoundFetched == false {
                    self.fetchingServiceData = true
                }else{
                    self.refreshingData = true
                }
                
                let (data, _) = try await URLSession.shared.data(for: request)
                
                do {
                    let json = try JSONDecoder().decode(CurrentServiceAPIResult.self, from: data)
                    
                    self.serviceData = json
                    //                if !err_json.error.isEmpty {
                    //                    self.errValue = true
                    //                    print("Error from server: \(err_json.error)")
                    //                }else{
                    //                    self.service = json
                    //                }
                    
                    if firstRoundFetched == false {
                        self.firstRoundFetched = true
                    }
                }catch {
                    print(error)
                }
                
                self.fetchingServiceData = false
                self.refreshingData = false
                
                try await Task.sleep(for: .seconds (60))
            } while !Task.isCancelled
        }
    }
    
    var body: some View {
        VStack(alignment: .leading){
            VStack {
                HStack(alignment: .top){
                    Image(GetLogoOfTOC(code: currentDeparture.operatorCode))
                        .resizable()
                        .frame(width: 41, height: 41)
                        .cornerRadius(9.0)
                    
                    if isDarwin == true {
                        VStack{
                            Text("\(currentDeparture.uid) \(currentDeparture.destination)").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                            Text("\(formatTime(timeString: currentDeparture.expectedDeparture))").font(.title3).bold().foregroundStyle(Color.gray).frame(maxWidth: .infinity, alignment: .leading)
                        }

                    }else{
                        VStack{
                            Text("\(currentDeparture.destination)").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                            Text("\(formatTime(timeString: currentDeparture.expectedDeparture))").font(.title3).bold().foregroundStyle(Color.gray).frame(maxWidth: .infinity, alignment: .leading)
                        }

                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                
                HStack(spacing: 15) {
                    if currentDeparture.cancelled {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Color.red)
                            .frame(width: 13.0, height: 13.0)
                        Text("Cancelled")
                            .font(.caption)
                            .foregroundStyle(Color.red)
                            .padding(.leading, -5)
                            .padding(.trailing, 5)
                    }else{
                        if currentDeparture.delayLength > 0 {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color.orange)
                                .frame(width: 13.0, height: 13.0)
                            Text("\(currentDeparture.delayLength)min late")
                                .font(.caption)
                                .foregroundStyle(Color.orange)
                                .padding(.leading, -5)
                                .padding(.trailing, 5)
                        }else{
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color.green)
                                .frame(width: 13.0, height: 13.0)
                            Text("On Time")
                                .font(.caption)
                                .foregroundStyle(Color.green)
                                .padding(.leading, -5)
                                .padding(.trailing, 5)
                            
                        }
                    }
                    
                    if currentDeparture.trainLength != 0 {
                        Group{
                            Image(systemName: "train.side.middle.car")
                                .foregroundStyle(colorScheme == .dark ? Color(red: 210/255, green: 210/255, blue: 210/255) : Color.gray)
                                .frame(width: 13.0, height: 13.0)
                            Text("\(currentDeparture.trainLength) Coaches")
                                .font(.caption)
                                .foregroundStyle(colorScheme == .dark ? Color(red: 210/255, green: 210/255, blue: 210/255) : Color.gray)
                                .padding(.leading, -5)
                        }
                    }else{
                        Group{
                            Image(systemName: "train.side.middle.car")
                                .foregroundStyle(colorScheme == .dark ? Color(red: 210/255, green: 210/255, blue: 210/255) : Color.gray)
                                .frame(width: 13.0, height: 13.0)
                               
                            Text("Formation Unknown")
                                .font(.caption)
                                .foregroundStyle(colorScheme == .dark ? Color(red: 210/255, green: 210/255, blue: 210/255) : Color.gray)
                                .padding(.leading, -5)
                        }
                    }

                    
                    Text("Platform \(currentDeparture.platformNo ?? "Unknown")")
                        .padding([.leading, .trailing], 10.0)
                        .padding([.top, .bottom], 2.0)
                        .font(.caption).bold()
                        .background(Color(red: 1 / 255, green: 48 / 255, blue: 102 / 255))
                        .foregroundStyle(Color.white)
                        .cornerRadius(8.5)

                }


            }
                        
            ScrollView{
                if laterDepartures.count != 0 && laterDepartures.count > 1 {
                    VStack{
                        Text("Additional Departures").font(.subheadline).foregroundStyle(Color.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        Picker("Later Departures", selection: $currentDeparture.rid) {
                            ForEach(Array(laterDepartures).prefix(3)) { laterService in
                                if laterService.cancelled {
                                    Text("\(formatTime(timeString: laterService.expectedDeparture))").foregroundStyle(Color.red).strikethrough().tag(laterService.rid)
                                }else{
                                    if laterService.isDelayed {
                                        if laterService.delayLength > 0 {
                                            Text("\(formatTime(timeString: laterService.estimatedDeparture ?? "00:00"))").foregroundStyle(Color.orange).tag(laterService.rid)
                                        }else{
                                            Text("\(formatTime(timeString: laterService.expectedDeparture))").foregroundStyle(Color.orange).tag(laterService.rid)
                                        }
                                    }else{
                                        Text("\(formatTime(timeString: laterService.expectedDeparture))").foregroundStyle(Color.primary).tag(laterService.rid)
                                    }
                                }
                                
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.top)
                    .padding(.horizontal, 50)
                }
                
                if serviceData.cancelled == true {
                    VStack{
                        HStack{
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundStyle(Color.red)
                            
                            Text("CANCELLED").font(.headline).bold().foregroundColor(Color.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .horizontal])
                        
                        Text("\(serviceData.cancelReason ?? "This train has been cancelled because of an unknown reason")")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body)
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
                            .padding([.bottom, .horizontal])
                    }
                    .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color(red: 242/255, green: 242/255, blue: 247/255))
                    .cornerRadius(6)
                    .padding()
                }
                
                
                VStack{
                    VStack{
                        VStack(alignment: .center){
                            ForEach(serviceData.journey) { stop in
                                if serviceData.journey.first?.crs == stop.crs {
                                    HStack{
                                        VStack(alignment: .center){
                                            Circle().overlay(Circle().stroke(Color.white, lineWidth: 3)).frame(width: 15, height: 15).offset(x: 0, y: 3).foregroundStyle(Color(red: 1/255, green: 48/255, blue: 102/255)).zIndex(2.0).opacity(stop.atd ?? "" != "" || stop.isCancelled == true ? 0.5 : 1.0)
                                            Rectangle().frame(width: 4, height: 75).offset(x: 0, y: -5).foregroundStyle(Color(red: 1/255, green: 48/255, blue: 102/255)).opacity(stop.atd ?? "" != "" || stop.isCancelled == true ? 0.5 : 1.0)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            HStack(){
                                                Text("\(stop.locationName)").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                                                
                                                if stop.isCancelled {
                                                    Text("\(formatTime(timeString: stop.std ?? "00:00"))")
                                                        .font(.headline)
                                                        .foregroundStyle(Color.red)
                                                        .strikethrough()
                                                }else{
                                                    if stop.lateness ?? 0 > 0 {
                                                        if stop.etd ?? "" != "" {
                                                            HStack {
                                                                Text("\(formatTime(timeString: stop.std ?? "00:00"))")
                                                                    .font(.headline)
                                                                    .foregroundStyle(Color.red)
                                                                    .strikethrough()
                                                                Text("\(formatTime(timeString: stop.etd ?? "00:00"))")
                                                                    .font(.headline)
                                                                    .foregroundStyle(Color.primary)
                                                            }
    
                                                        }else{
                                                            Text("\(formatTime(timeString: stop.std ?? "00:00"))")
                                                                .font(.headline)
                                                                .foregroundStyle(Color.orange)
                                                        }
                                                    }else{
                                                        Text("\(formatTime(timeString: stop.std ?? "00:00"))")
                                                            .font(.headline)
                                                            .foregroundStyle(Color.primary)
                                                    }
                                                }
                                            }
                                            
                                            HStack{
                                                Text("Platform \(stop.platform ?? "Unknown")")
                                                    .padding([.leading, .trailing], 10.0)
                                                    .padding([.top, .bottom], 2.0)
                                                    .font(.caption).bold()
                                                    .background(Color(red: 1 / 255, green: 48 / 255, blue: 102 / 255))
                                                    .foregroundStyle(Color.white)
                                                    .cornerRadius(8.5)
                                                
                                                Spacer()
                                                
                                                if stop.isCancelled == true {
                                                    Text("Cancelled").font(.subheadline).foregroundStyle(Color.red)
                                                }else{
                                                    if stop.lateness ?? 0 > 0 {
                                                        if stop.atd ?? "" != "" {
                                                            Text("Departed \(stop.lateness ?? 0) min late").font(.subheadline).foregroundStyle(Color.secondary)
                                                        }else {
                                                            if stop.ata ?? "" != "" {
                                                                Text("Arrived \(stop.lateness ?? 0) min late").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }else{
                                                                Text("\(stop.lateness ?? 0) min late").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }
                                                        }
                                                    }else{
                                                        if stop.atd ?? "" != "" {
                                                            Text("Departed On Time").font(.subheadline).foregroundStyle(Color.secondary)
                                                        }else{
                                                            if stop.ata ?? "" != "" {
                                                                Text("Arrived On Time").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }else{
                                                                Text("On Time").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.top, -5)

                                            Spacer()
                                        }
                                    }
                                }else{
                                    if serviceData.journey.last?.crs == stop.crs {
                                        HStack{
                                            VStack(alignment: .center){
                                                Circle().overlay(Circle().stroke(Color.white, lineWidth: 3)).frame(width: 15, height: 15).offset(x: 0, y: -15).foregroundStyle(Color(red: 1/255, green: 48/255, blue: 102/255)).zIndex(2.0).opacity(stop.atd ?? "" != "" || stop.isCancelled == true ? 0.5 : 1.0)
                                                Rectangle().frame(width: 0, height: 35).offset(x: 0, y: -23).foregroundStyle(Color(red: 1/255, green: 48/255, blue: 102/255)).opacity(stop.atd ?? "" != "" || stop.isCancelled == true ? 0.5 : 1.0)
                                            }
                                            
                                            VStack(alignment: .leading) {
                                                HStack(){
                                                    Text("\(stop.locationName)").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                                                    
                                                    if stop.isCancelled {
                                                        Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                            .font(.headline)
                                                            .foregroundStyle(Color.red)
                                                            .strikethrough()
                                                    }else{
                                                        if stop.lateness ?? 0 > 0 {
                                                            if stop.eta ?? "" != "" {
                                                                HStack {
                                                                    Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                        .font(.headline)
                                                                        .foregroundStyle(Color.red)
                                                                        .strikethrough()
                                                                    Text("\(formatTime(timeString: stop.eta ?? "00:00"))")
                                                                        .font(.headline)
                                                                        .foregroundStyle(Color.primary)
                                                                }
        
                                                            }else{
                                                                Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                    .font(.headline)
                                                                    .foregroundStyle(Color.orange)
                                                            }
                                                        }else{
                                                            Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                .font(.headline)
                                                                .foregroundStyle(Color.primary)
                                                        }
                                                    }
                                                }
                                                
                                                HStack{
                                                    Text("Platform \(stop.platform ?? "Unknown")")
                                                        .padding([.leading, .trailing], 10.0)
                                                        .padding([.top, .bottom], 2.0)
                                                        .font(.caption).bold()
                                                        .background(Color(red: 1 / 255, green: 48 / 255, blue: 102 / 255))
                                                        .foregroundStyle(Color.white)
                                                        .cornerRadius(8.5)
                                                    
                                                    Spacer()
                                                    
                                                    if stop.isCancelled == true {
                                                        Text("Cancelled").font(.subheadline).foregroundStyle(Color.red)
                                                    }else{
                                                        if stop.lateness ?? 0 > 0 {
                                                            if stop.ata ?? "" != "" {
                                                                Text("Arrived \(stop.lateness ?? 0) min late").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }else{
                                                                Text("\(stop.lateness ?? 0) min late").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }
                                                        }else{
                                                            if (stop.ata ?? "" != "") {
                                                                Text("Arrived On Time").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }else{
                                                                Text("On Time").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.top, -5)

                                                Spacer()
                                            }
                                            .padding(.top, -18)
                                        }
                                        .padding(.bottom, -25)
                                    }else{
                                        HStack{
                                            VStack(alignment: .center){
                                                Circle().overlay(Circle().stroke(Color.white, lineWidth: 3)).frame(width: 15, height: 15).offset(x: 0, y: -6).foregroundStyle(Color(red: 1/255, green: 48/255, blue: 102/255)).zIndex(2.0).opacity(stop.atd ?? "" != "" || stop.isCancelled == true ? 0.5 : 1.0)
                                                Rectangle().frame(width: 4, height: 75).offset(x: 0, y: -14).foregroundStyle(Color(red: 1/255, green: 48/255, blue: 102/255)).opacity(stop.atd ?? "" != "" || stop.isCancelled == true ? 0.5 : 1.0)
                                            }
                                            
                                            VStack(alignment: .leading) {
                                                HStack(){
                                                    Text("\(stop.locationName)").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                                                    
                                                    if stop.isCancelled {
                                                        Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                            .font(.headline)
                                                            .foregroundStyle(Color.red)
                                                            .strikethrough()
                                                    }else{
                                                        if stop.lateness ?? 0 > 0 {
                                                            if stop.eta ?? "" != "" {
                                                                HStack {
                                                                    Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                        .font(.headline)
                                                                        .foregroundStyle(Color.red)
                                                                        .strikethrough()
                                                                    Text("\(formatTime(timeString: stop.eta ?? "00:00"))")
                                                                        .font(.headline)
                                                                        .foregroundStyle(Color.primary)
                                                                }
        
                                                            }else{
                                                                Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                    .font(.headline)
                                                                    .foregroundStyle(Color.orange)
                                                            }
                                                        }else{
                                                            Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                .font(.headline)
                                                                .foregroundStyle(Color.primary)
                                                        }
                                                    }
                                                }
                                                
                                                HStack{
                                                    Text("Platform \(stop.platform ?? "Unknown")")
                                                        .padding([.leading, .trailing], 10.0)
                                                        .padding([.top, .bottom], 2.0)
                                                        .font(.caption).bold()
                                                        .background(Color(red: 1 / 255, green: 48 / 255, blue: 102 / 255))
                                                        .foregroundStyle(Color.white)
                                                        .cornerRadius(8.5)
                                                    
                                                    Spacer()
                                                    
                                                    if stop.isCancelled == true {
                                                        Text("Cancelled").font(.subheadline).foregroundStyle(Color.red)
                                                    }else{
                                                        if stop.lateness ?? 0 > 0 {
                                                            if stop.atd ?? "" != "" {
                                                                Text("Departed \(stop.lateness ?? 0) min late").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }else {
                                                                if stop.ata ?? "" != "" {
                                                                    Text("Arrived \(stop.lateness ?? 0) min late").font(.subheadline).foregroundStyle(Color.secondary)
                                                                }else{
                                                                    Text("\(stop.lateness ?? 0) min late").font(.subheadline).foregroundStyle(Color.secondary)
                                                                }
                                                            }
                                                        }else{
                                                            if stop.atd ?? "" != "" {
                                                                Text("Departed On Time").font(.subheadline).foregroundStyle(Color.secondary)
                                                            }else{
                                                                if stop.ata ?? "" != "" {
                                                                    Text("Arrived On Time").font(.subheadline).foregroundStyle(Color.secondary)
                                                                }else{
                                                                    Text("On Time").font(.subheadline).foregroundStyle(Color.secondary)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.top, -5)

                                                Spacer()
                                            }
                                            .padding(.top, -16)
                                        }
                                        .padding(.bottom, -16)
                                    }
                                }
                            }
                        }
                        .padding(.top)
                        .padding(.horizontal)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.vertical)
                    
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Button {
                    print("Pin Journey button pressed")
                    guard let firstItem = serviceData.journey.first else { return }
                    guard let lastItem = serviceData.journey.last else { return }
                    
                    let item = PinnedService(service: PinnedServiceSchema(origin: firstItem.crs, destination: lastItem.crs, operator: serviceData.operator, operatorCode: serviceData.operatorCode, cancelled: serviceData.cancelled, trackingFrom: firstItem.crs, trackingTo: lastItem.crs, rid: currentDeparture.rid, uid: currentDeparture.uid, sdd: currentDeparture.sdd, eta: "", ata: ""))
                    
                    print("Iterating")
                    
                    if isPinned == true {
                        allPinnedServices.enumerated().forEach { index, pinnedServiceItem in
                            if(currentDeparture.rid == pinnedServiceItem.pinned_service.rid) {
                                if isPinned == true {
                                    context.delete(pinnedServiceItem)
                                    isPinned = false
                                    print("Pin Removed")
                                }
                            }
                        }
                    }else{
                        context.insert(item)
                        allPinnedServices.append(item)
                        isPinned = true
                        print("Pin added")
                    }
                    
                } label: {
                    HStack {
                        if isPinned == true {
                            Label("Unpin Journey", systemImage: "pin.fill").font(.body)
                        }else{
                            Label("Pin Journey", systemImage: "pin.fill").font(.body)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                #if os(iOS)
                .buttonStyle(.glassProminent)
                #endif
                .padding()
                .padding(.horizontal)
            }
        }
        .onAppear() {
            fetchData(uid: currentDeparture.uid, sdd: currentDeparture.sdd)
        }
    }
}

#Preview {
    @Previewable @Environment(\.colorScheme) var colorScheme

    TrainServiceSheet(currentDeparture: DepartureItem(origin: "Abbey Wood", destination: "Reading", operator: "Elizabeth Line", operatorCode: "XR", cancelled: false, headcode: "9R56", trainLength: 9, expectedDeparture: "2026-02-07T11:45:00", isDelayed: false, delayLength: 0, rid: "202602078073046", uid: "P73046", sdd: "2026-02-07"), laterDepartures: [fake_departure_item, fake_departure_item, fake_departure_item])
}
