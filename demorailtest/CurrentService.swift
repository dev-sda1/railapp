//
//  ContentView.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//

import Foundation
import SwiftUI
internal import Combine

struct CurrentService: View {
    @State var scrollText = true
    @State var searchTxt = ""
    
    var sampleDeparture: DepartureItem = DepartureItem(
        origin: "Manchester Piccadilly",
        destination: "Manchester Airport",
        operator: "Northern",
        operatorCode: "NT",
        cancelled: false,
        headcode: "1Y66",
        trainLength: 6,
        expectedDeparture: "2026-01-10T14:24:34",
        estimatedDeparture: "2026-01-10T14:24:34",
        isDelayed: false,
        delayLength: 0,
        rid: "202601157602352",
        uid: "L02352",
        sdd: "2026-01-15"
    )
    
    var body: some View {
        ServiceView(serviceInfo: sampleDeparture)
    }
}

struct CurrentServiceAPIError: Codable {
    var error: String
}

struct JourneyArraySchema: Codable {
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
    var headcode: String
    var `operator`: String
    var operatorCode: String
    var origin: String
    var destination: String
    var cancelled: Bool
    var cancelReason: String? = ""
    var journey: [JourneyArraySchema]
}

let fake_service: CurrentServiceAPIResult = CurrentServiceAPIResult(headcode: "", operator: "", operatorCode: "", origin: "", destination: "", cancelled: false, journey: [])

#Preview {
    @Previewable @StateObject var vm = ServiceViewModel(service: fake_service, errValue: false, loadingData: false)
    
    CurrentService()
        .environmentObject(vm)
}

class ServiceViewModel: ObservableObject {
    @Published var service: CurrentServiceAPIResult
    @Published var errValue: Bool
    @Published var loadingData: Bool
    
    init(service: CurrentServiceAPIResult, errValue: Bool, loadingData: Bool) {
        self.service = service
        self.errValue = errValue
        self.loadingData = loadingData
        
        getServiceData(uid: "", sdd: "")
    }
    
    @MainActor
    func getServiceData(uid: String, sdd: String){
        let urlString = "https://d-railboard.pyxlwuff.dev/service/\(uid)/\(sdd)/standard"
//        let urlString = "http://localhost:3000/service/\(uid)/\(sdd)/standard"
        
        guard !loadingData else { return }
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        
        Task {
            self.loadingData = true
            let (data, _) = try await URLSession.shared.data(for: request)

            do {
                let json = try JSONDecoder().decode(CurrentServiceAPIResult.self, from: data)

                self.service = json
//                if !err_json.error.isEmpty {
//                    self.errValue = true
//                    print("Error from server: \(err_json.error)")
//                }else{
//                    self.service = json
//                }
            }catch {
                print(error)
            }
            
            self.loadingData = false
        }

    }
}

struct ServiceView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var scrollPosition: Double = 0
    @State private var loadingData: Bool = true
    @State private var layoutID = UUID()
    @EnvironmentObject var vm: ServiceViewModel


    @State var serviceInfo: DepartureItem
    @State var isPinned = false
    @State var loadingServiceData = false
    @State var isErr = false
    
    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGPoint = .zero

        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
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
        ZStack{
            NavigationStack {
                ZStack{
                    ScrollView {
                        Text("\(formatTime(timeString: serviceInfo.expectedDeparture))").font(.title).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                        Text("\(serviceInfo.origin) to \(serviceInfo.destination)").font(.title2).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                                                
                        if vm.service.cancelled == true {
                            VStack{
                                HStack{
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .resizable()
                                        .frame(width: 15, height: 15)
                                        .foregroundStyle(Color.red)
                                    
                                    Text("CANCELLED").font(.headline).bold().foregroundColor(Color.red)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("\(vm.service.cancelReason ?? "This train has been cancelled because of an unknown reason")")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.body)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
                            .cornerRadius(6)
                        }

                    }
                    .padding()
                }
                .background(colorScheme == .dark ? Color.black : Color(red: 242/255, green: 242/255, blue: 247/255))
                .font(.headline)
                .navigationBarItems(trailing: Button {
                    isPinned.toggle()
                } label: {
                    Label("Dropdown", systemImage: isPinned ? "pin.fill" : "pin")
                })
            }
        }
        .edgesIgnoringSafeArea([.leading, .trailing])
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .onAppear {
            vm.getServiceData(uid: serviceInfo.uid, sdd: serviceInfo.sdd)
        }
    }
}
