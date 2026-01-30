//
//  PinnedServices.swift
//  demorailtest
//
//  Created by James on 29/01/2026.
//

import SwiftUI
import Foundation
import SwiftData

struct PinnedServicesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    
    @Query private var pinnedServiceQuery: [PinnedService]
    
    @State private var allPinnedServices: [PinnedService] = []
    @State private var currentlyPinned: PinnedServiceSchema = PinnedServiceSchema(origin: "", destination: "", operator: "", operatorCode: "", cancelled: false, trackingFrom: "", trackingTo: "", rid: "", uid: "", sdd: "", eta: "", ata: "")
    
    @State private var showServiceSheet = false
    @State private var serviceSheetData: DepartureItem = fake_departure_item
    @State private var serviceSheetTRUSTData: DepartureTRUSTData = DepartureTRUSTData(rid: "", uid: "", sdd: "")
    
    var body: some View {
        NavigationView{
            if (allPinnedServices.isEmpty == false) {
                ScrollView{
    //                Text("You haven't pinned any services yet").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Current Journey").font(.title2).bold().frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    
                    Text("Previous Journeys").font(.title2).bold().frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(allPinnedServices, id: \.self) { serviceItem in
                        Button {
                            let temp = DepartureItem(origin: serviceItem.pinned_service.origin, destination: serviceItem.pinned_service.destination, operator: serviceItem.pinned_service.operator, operatorCode: serviceItem.pinned_service.operatorCode, cancelled: serviceItem.pinned_service.cancelled, headcode: "", trainLength: 0, expectedDeparture: serviceItem.pinned_service.eta, isDelayed: false, delayLength: 0, rid: serviceItem.pinned_service.rid, uid: serviceItem.pinned_service.uid, sdd: serviceItem.pinned_service.sdd)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                serviceSheetData = temp
                                showServiceSheet.toggle()
                            }
                        } label: {
                            PinnedServiceCard(style: .arrived, serviceData: serviceItem.pinned_service)
                        }

                    }
                }
                .padding()
                .navigationTitle("Journeys")
            }else{
                VStack{
    //                Text("You haven't pinned any services yet").frame(maxWidth: .infinity, alignment: .leading)
                    Text("You currently don't have any journeys pinned.").font(.body).frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .navigationTitle("Journeys")
            }
        }
        .onAppear() {
            allPinnedServices = Array(pinnedServiceQuery)
        }
        .sheet(isPresented: $showServiceSheet) {
            NavigationStack{
                TrainServiceSheet(currentDeparture: serviceSheetData, laterDepartures: [])
                .toolbar {
                    Button(role: .close) {
                        showServiceSheet = false
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    PinnedServicesView()
}
