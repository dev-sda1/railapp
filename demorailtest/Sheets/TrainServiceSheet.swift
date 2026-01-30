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
    @State private var serviceData: CurrentServiceAPIResult = CurrentServiceAPIResult(headcode: "", operator: "", operatorCode: "", origin: "", destination: "", cancelled: true, cancelReason: "", journey: [])
    @State private var fetchingServiceData = false
    @State private var firstRoundFetched = false
    @State private var refreshingData = false
    @State private var isPinned = false
    
    @State var currentDeparture: DepartureItem
    @State var laterDepartures: [DepartureItem]
    @State private var allPinnedServices: [PinnedService] = []

    @State private var isDarwin = AppSettingsManager().useDarwin
    @State private var task: Task<(), Error>?

        
       
    func formatTime(timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        
        var date = formatter.date(from: timeString)?.formatted(date: .omitted, time: .standard) ?? "00:00"
        if date.count == 4 {
            date = "0\(date)"
        }
        
        var formatted = ""
        
        if date.firstIndex(of: "a") == nil && date.firstIndex(of: "p") == nil {
            formatted = "\(date.split(separator: ":")[0]):\(date.split(separator: ":")[1])"
        }else{
            formatted = "\(date.split(separator: ":")[0]):\(date.split(separator: ":")[1])\(date.split(separator: ":")[2].suffix(2))"
        }
                
        return formatted
    }
    
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
            HStack(alignment: .top){
                Image(GetLogoOfTOC(code: currentDeparture.operatorCode))
                    .resizable()
                    .frame(width: 45, height: 45)
                    .cornerRadius(6.0)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.12), radius: 5, x: 0, y: 0)
                
                if isDarwin == true {
                    VStack{
                        Text("\(currentDeparture.uid) \(formatTime(timeString: currentDeparture.expectedDeparture)) to \(currentDeparture.destination)").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                        Text("\(currentDeparture.operator)").font(.footnote).foregroundStyle(Color.gray).frame(maxWidth: .infinity, alignment: .leading)
                    }

                }else{
                    VStack{
                        Text("\(formatTime(timeString: currentDeparture.expectedDeparture)) to \(currentDeparture.destination)").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                        Text("\(currentDeparture.operator)").font(.footnote).foregroundStyle(Color.gray).frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal)
            .padding(.bottom, 16)
//            .glassEffect()
            
            ScrollView{
                if laterDepartures.count != 0 {
                    VStack{
                        Text("Additional Departures").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                        
                        ScrollView(.horizontal){
                            HStack{
                                ForEach(laterDepartures) { laterService in
                                    Button {
                                        currentDeparture = laterService
                                        fetchData(uid: laterService.uid, sdd: laterService.sdd)
                                    } label: {
                                        VStack{
                                            if laterService.cancelled {
                                                Text("\(formatTime(timeString: laterService.expectedDeparture))").font(.title3).bold().strikethrough().foregroundStyle(Color.red)
                                                Text("Cancelled").foregroundStyle(Color.red)
                                            }else{
                                                if laterService.isDelayed {
                                                    if laterService.delayLength > 0 {
                                                        Text("\(formatTime(timeString: laterService.estimatedDeparture ?? "00:00"))").font(.title3).bold().foregroundStyle(Color.orange)
                                                        Text("Delayed \(laterService.delayLength)min").foregroundStyle(Color.orange)
                                                    }else{
                                                        Text("\(formatTime(timeString: laterService.expectedDeparture))").font(.title3).bold().foregroundStyle(Color.orange)
                                                        Text("Delayed").foregroundStyle(Color.orange)
                                                    }
                                                }else{
                                                    Text("\(formatTime(timeString: laterService.expectedDeparture))").font(.title3).bold().foregroundStyle(Color.primary)
                                                    Text("On Time").foregroundStyle(Color.green)
                                                }
                                                
                                            }
                                        }
                                        .padding()
                                        .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color(red: 242/255, green: 242/255, blue: 247/255))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                    }
                    .padding(.top)
                    .padding(.horizontal)
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
                    Text("Calling Points").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                    
                    VStack{
                        VStack(alignment: .center){
                            ForEach(serviceData.journey) { stop in
                                if serviceData.journey.first?.crs == stop.crs {
                                    HStack{
                                        VStack(alignment: .center){
                                            Circle().frame(width: 15, height: 15).offset(x: 0, y: 3).foregroundStyle(stop.atd ?? "" != "" || stop.isCancelled == true ? Color.gray : Color.black)
                                            Rectangle().frame(width: 4, height: 58).offset(x: 0, y: -12).foregroundStyle(stop.atd ?? "" != "" || stop.isCancelled == true ? Color.gray : Color.black)
                                        }
                                        
                                        VStack(alignment: .leading){
                                            Text("\(stop.locationName)").font(.headline).bold().frame(maxWidth: .infinity, alignment: .leading)
                                            HStack{
                                                if stop.isCancelled {
                                                    Image(systemName: "clock.fill")
                                                        .foregroundStyle(Color.red)
                                                        .frame(width: 13.0, height: 13.0)
                                                    Text("Cancelled")
                                                        .font(.caption)
                                                        .foregroundStyle(Color.red)
                                                }else{
                                                    if stop.lateness ?? 0 > 0 {
                                                        Image(systemName: "clock.fill")
                                                            .foregroundStyle(Color.orange)
                                                            .frame(width: 13.0, height: 13.0)
                                                        Text("\(stop.lateness ?? 0)min late")
                                                            .font(.caption)
                                                            .foregroundStyle(Color.orange)
                                                    }else{
                                                        Image(systemName: "clock.fill")
                                                            .foregroundStyle(Color.green)
                                                            .frame(width: 13.0, height: 13.0)
                                                        Text("On Time")
                                                            .font(.caption)
                                                            .foregroundStyle(Color.green)
                                                        
                                                    }
                                                }
                                                
                                            }.padding(.top, -5)
                                            Spacer()
                                        }
                                        
                                        VStack(alignment: .leading){
                                            if stop.isCancelled {
                                                Text("\(formatTime(timeString: stop.std ?? "00:00"))")
                                                    .font(.headline).bold()
                                                    .foregroundStyle(Color.red)
                                                    .strikethrough()
                                                    .frame(maxWidth: 72, alignment: .trailing)
                                            }else{
                                                if stop.lateness ?? 0 > 0 {
                                                    if stop.etd ?? "" != "" || stop.etd ?? "" != "UNKN" {
                                                        Text("\(formatTime(timeString: stop.etd ?? "00:00"))")
                                                            .font(.headline).bold()
                                                            .foregroundStyle(Color.orange)
                                                            .frame(maxWidth: 72, alignment: .trailing)
                                                    }else{
                                                        Text("\(formatTime(timeString: stop.std ?? "00:00"))")
                                                            .font(.headline).bold()
                                                            .foregroundStyle(Color.orange)
                                                            .frame(maxWidth: 72, alignment: .trailing)
                                                    }
                                                }else{
                                                    Text("\(formatTime(timeString: stop.std ?? "00:00"))")
                                                        .font(.headline).bold()
                                                        .foregroundStyle(Color.primary)
                                                        .frame(maxWidth: 72, alignment: .trailing)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                }else{
                                    if serviceData.journey.last?.crs == stop.crs {
                                        HStack{
                                            VStack(alignment: .center){
                                                Circle().frame(width: 15, height: 15).offset(x: 0, y: -15)
                                                Rectangle().frame(width: 0, height: 50).offset(x: 0, y: -23)
                                            }
                                            
                                            VStack(alignment: .leading){
                                                Text("\(stop.locationName)").font(.headline).bold().frame(maxWidth: .infinity, alignment: .leading)
                                                HStack{
                                                    if stop.isCancelled {
                                                        Image(systemName: "clock.fill")
                                                            .foregroundStyle(Color.red)
                                                            .frame(width: 13.0, height: 13.0)
                                                        Text("Cancelled")
                                                            .font(.caption)
                                                            .foregroundStyle(Color.red)
                                                    }else{
                                                        if stop.lateness ?? 0 > 0 {
                                                            Image(systemName: "clock.fill")
                                                                .foregroundStyle(Color.orange)
                                                                .frame(width: 13.0, height: 13.0)
                                                            Text("\(stop.lateness ?? 0)min late")
                                                                .font(.caption)
                                                                .foregroundStyle(Color.orange)
                                                        }else{
                                                            Image(systemName: "clock.fill")
                                                                .foregroundStyle(Color.green)
                                                                .frame(width: 13.0, height: 13.0)
                                                            Text("On Time")
                                                                .font(.caption)
                                                                .foregroundStyle(Color.green)
                                                        }
                                                        
                                                    }
                                                    
                                                }.padding(.top, -5)
                                                Spacer()
                                            }
                                            .padding(.top, -17)
                                            
                                            VStack(alignment: .leading){
                                                if stop.isCancelled {
                                                    Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                        .font(.headline).bold()
                                                        .foregroundStyle(Color.red)
                                                        .strikethrough()
                                                        .frame(maxWidth: 72, alignment: .trailing)
                                                }else{
                                                    if stop.lateness ?? 0 > 0 {
                                                        if stop.eta ?? "" != "" || stop.eta ?? "" != "UNKN" {
                                                            Text("\(formatTime(timeString: stop.eta ?? "00:00"))")
                                                                .font(.headline).bold()
                                                                .foregroundStyle(Color.orange)
                                                                .frame(maxWidth: 72, alignment: .trailing)
                                                        }else{
                                                            Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                .font(.headline).bold()
                                                                .foregroundStyle(Color.orange)
                                                                .frame(maxWidth: 72, alignment: .trailing)
                                                        }
                                                    }else{
                                                        Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                            .font(.headline).bold()
                                                            .foregroundStyle(Color.primary)
                                                            .frame(maxWidth: 72, alignment: .trailing)
                                                    }
                                                }
                                            }
                                            .padding(.top, -17)
                                        }
                                        .padding(.bottom, -25)
                                    }else{
                                        HStack{
                                            VStack(alignment: .center){
                                                Circle().overlay(Circle().stroke(stop.atd ?? "" != "" || stop.isCancelled == true ? Color.gray : Color.black, lineWidth: 4)).frame(width: 15, height: 15).offset(x: 0, y: -14).foregroundStyle(.clear)
                                                Rectangle().frame(width: 4, height: 50).offset(x: 0, y: -23).foregroundStyle(stop.atd ?? "" != "" || stop.isCancelled == true ? Color.gray : Color.black)
                                            }
                                            
                                            VStack(alignment: .leading){
                                                HStack {
//                                                    Button {
//                                                        
//                                                    } label: {
//                                                        Label("", systemImage: "pin.fill").frame(width: 7, height: 7).padding(.leading, 7)
//                                                    }
                                                    
                                                    Text("\(stop.locationName)").font(.headline).bold().frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                
                                                HStack{
                                                    if stop.isCancelled {
                                                        Image(systemName: "clock.fill")
                                                            .foregroundStyle(Color.red)
                                                            .frame(width: 13.0, height: 13.0)
                                                        Text("Cancelled")
                                                            .font(.caption)
                                                            .foregroundStyle(Color.red)
                                                    }
                                                    
                                                    if stop.lateness ?? 0 > 0 {
                                                        Image(systemName: "clock.fill")
                                                            .foregroundStyle(Color.orange)
                                                            .frame(width: 13.0, height: 13.0)
                                                        Text("\(stop.lateness ?? 0)min late")
                                                            .font(.caption)
                                                            .foregroundStyle(Color.orange)
                                                    }else{
                                                        Image(systemName: "clock.fill")
                                                            .foregroundStyle(Color.green)
                                                            .frame(width: 13.0, height: 13.0)
                                                        Text("On Time")
                                                            .font(.caption)
                                                            .foregroundStyle(Color.green)
                                                        
                                                    }
                                                }.padding(.top, -5)
                                                Spacer()
                                            }
                                            .padding(.top, -17)
                                            
                                            if stop.atd ?? "" != "" {
                                                VStack(alignment: .leading){
                                                    if stop.isCancelled {
                                                        Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                            .font(.headline).bold()
                                                            .foregroundStyle(Color.red)
                                                            .strikethrough()
                                                            .frame(maxWidth: 72, alignment: .trailing)
                                                        Spacer()
                                                        
                                                    }else{
                                                        if stop.lateness ?? 0 > 0 {
                                                            if stop.atd ?? "" != "" || stop.atd ?? "" != "UNKN" {
                                                                Text("\(formatTime(timeString: stop.atd ?? "00:00"))")
                                                                    .font(.headline).bold()
                                                                    .foregroundStyle(Color.orange)
                                                                    .frame(maxWidth: 72, alignment: .trailing)
                                                                Spacer()
                                                                
                                                            }else{
                                                                Text("\(formatTime(timeString: stop.atd ?? "00:00"))")
                                                                    .font(.headline).bold()
                                                                    .foregroundStyle(Color.orange)
                                                                    .frame(maxWidth: 72, alignment: .trailing)
                                                                Spacer()
                                                                
                                                            }
                                                        }else{
                                                            Text("\(formatTime(timeString: stop.atd ?? "00:00"))")
                                                                .font(.headline).bold()
                                                                .foregroundStyle(Color.primary)
                                                                .frame(maxWidth: 72, alignment: .trailing)
                                                            Spacer()
                                                        }
                                                    }
                                                }
                                                .padding(.top, -17)
                                            }else{
                                                if stop.ata ?? "" != "" {
                                                    VStack(alignment: .leading){
                                                        if stop.isCancelled {
                                                            Text("\(formatTime(timeString: stop.ata ?? "00:00"))")
                                                                .font(.headline).bold()
                                                                .foregroundStyle(Color.red)
                                                                .strikethrough()
                                                                .frame(maxWidth: 72, alignment: .trailing)
                                                            Spacer()
                                                            
                                                        }else{
                                                            if stop.lateness ?? 0 > 0 {
                                                                if stop.ata ?? "" != "" || stop.ata ?? "" != "UNKN" {
                                                                    Text("\(formatTime(timeString: stop.ata ?? "00:00"))")
                                                                        .font(.headline).bold()
                                                                        .foregroundStyle(Color.orange)
                                                                        .frame(maxWidth: 72, alignment: .trailing)
                                                                    Spacer()
                                                                    
                                                                }else{
                                                                    Text("\(formatTime(timeString: stop.ata ?? "00:00"))")
                                                                        .font(.headline).bold()
                                                                        .foregroundStyle(Color.orange)
                                                                        .frame(maxWidth: 72, alignment: .trailing)
                                                                    Spacer()
                                                                    
                                                                }
                                                            }else{
                                                                Text("\(formatTime(timeString: stop.ata ?? "00:00"))")
                                                                    .font(.headline).bold()
                                                                    .foregroundStyle(Color.primary)
                                                                    .frame(maxWidth: 72, alignment: .trailing)
                                                                Spacer()
                                                            }
                                                        }
                                                    }
                                                    .padding(.top, -17)
                                                    
                                                }else{
                                                    VStack(alignment: .leading){
                                                        if stop.isCancelled {
                                                            Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                .font(.headline).bold()
                                                                .foregroundStyle(Color.red)
                                                                .strikethrough()
                                                                .frame(maxWidth: 72, alignment: .trailing)
                                                            Spacer()
                                                            
                                                        }else{
                                                            if stop.lateness ?? 0 > 0 {
                                                                if stop.eta ?? "" != "" || stop.eta ?? "" != "UNKN" {
                                                                    Text("\(formatTime(timeString: stop.eta ?? "00:00"))")
                                                                        .font(.headline).bold()
                                                                        .foregroundStyle(Color.orange)
                                                                        .frame(maxWidth: 72, alignment: .trailing)
                                                                    Spacer()
                                                                    
                                                                }else{
                                                                    Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                        .font(.headline).bold()
                                                                        .foregroundStyle(Color.orange)
                                                                        .frame(maxWidth: 72, alignment: .trailing)
                                                                    Spacer()
                                                                    
                                                                }
                                                            }else{
                                                                Text("\(formatTime(timeString: stop.sta ?? "00:00"))")
                                                                    .font(.headline).bold()
                                                                    .foregroundStyle(Color.primary)
                                                                    .frame(maxWidth: 72, alignment: .trailing)
                                                                Spacer()
                                                            }
                                                        }
                                                    }
                                                    .padding(.top, -17)
                                                    
                                                }
                                            }
                                            
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
                    .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color(red: 242/255, green: 242/255, blue: 247/255))
                    .cornerRadius(6)
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
                .buttonStyle(.glassProminent)
                .padding()
            }
        }.onAppear() {
            fetchData(uid: currentDeparture.uid, sdd: currentDeparture.sdd)
        }
    }
}

#Preview {
    @Previewable @Environment(\.colorScheme) var colorScheme

    TrainServiceSheet(currentDeparture: DepartureItem(origin: "Abbey Wood", destination: "Reading", operator: "Elizabeth Line", operatorCode: "XR", cancelled: false, headcode: "9R56", trainLength: 9, expectedDeparture: "2026-01-29T20:17:00", isDelayed: false, delayLength: 0, rid: "202601257602417", uid: "G23712", sdd: "2026-01-29"), laterDepartures: [])
}
