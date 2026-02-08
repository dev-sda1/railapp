//
//  PinnedServices.swift
//  demorailtest
//
//  Created by James on 29/01/2026.
//

import SwiftUI
import Foundation
import SwiftData

struct QuickDebugView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
        
    @State private var selectedDeparture: DepartureItem?
    @State private var serviceSheetData: DepartureItem = fake_departure_item
    @State private var serviceSheetTRUSTData: DepartureTRUSTData = DepartureTRUSTData(rid: "", uid: "", sdd: "")
    
    private func presentService(uid: String, sdd: String) {
        var urlString = "https://d-railboard.pyxlwuff.dev/service/new/\(uid)/\(sdd)/detailed"
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        
        Task {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            do {
                let json = try JSONDecoder().decode(CurrentServiceAPIResult.self, from: data)

                let toShow: DepartureItem = DepartureItem(origin: json.origin, destination: json.destination, operator: json.operator, operatorCode: json.operatorCode, cancelled: json.cancelled, headcode: json.headcode ?? "", trainLength: 0, expectedDeparture: json.journey[0].std ?? "2026-01-25T13:53:00", isDelayed: false, delayLength: 0, rid: "", uid: uid, sdd: sdd)
                
                self.selectedDeparture = toShow
                
            } catch {
                print(error.localizedDescription)
            }
        }
        
//        self.serviceData = json
    }
    
    // INPUT VALUES
    
    // Quick Service Lookup
    @State private var inputUID: String = ""
    @State private var inputSDD: String = ""
    @State private var locatingService: Bool = false
    
    var body: some View {
        NavigationView{
            VStack{
                // Quick Service Lookup
                VStack{
                    Text("Quick Service Lookup").font(.title3).frame(maxWidth: .infinity, alignment: .leading)
                    HStack{
                        TextField(text: $inputUID, prompt: Text("UID")) {
                            Text("UID")
                        }
                        .autocorrectionDisabled()
                        
                        TextField(text: $inputSDD, prompt: Text("SDD")) {
                            Text("SDD")
                        }
                        .autocorrectionDisabled()
                        .keyboardType(.numberPad)
                        
                        Button {
                            if locatingService == true { return }
                            self.locatingService = true
                            presentService(uid: inputUID, sdd: inputSDD)
                            self.locatingService = false
                        } label: {
                            Text(locatingService == true ? "Finding.." : "Search")
                        }
                        .buttonStyle(.glassProminent)
                    }
                    .textFieldStyle(.roundedBorder)
                }
                Spacer()
            }
            .navigationTitle("Debug")
            .padding()
        }
        .sheet(item: $selectedDeparture) { item in
            NavigationStack{
                TrainServiceSheet(currentDeparture: item, laterDepartures: item.additionalServices ?? [])
                .toolbar {
                    Button(role: .close) {
                        selectedDeparture = nil
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    QuickDebugView()
}
