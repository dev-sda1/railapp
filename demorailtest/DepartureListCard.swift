//
//  TrainDepartureCard.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//


import SwiftUI
import Foundation
internal import Combine


struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}

struct FakeDepartureList: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 0){
                    Text("Departures")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Color.primary)
                        .padding([.bottom], 10.0)
                    
                    VStack(alignment: .leading){
                        HStack{
                            Rectangle().frame(width: 30, height: 30).cornerRadius(6.0).foregroundStyle(Color.gray)
                            Rectangle().frame(width: 160, height: 30, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)

                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack{
                            Rectangle().frame(width: 90, height: 30, alignment: .trailing).cornerRadius(6.0).foregroundStyle(Color.gray)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                            .offset(x: 0.0, y: -37.5)
                        
                        HStack{
                            Rectangle().frame(width: 150, height: 25, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)
                            
                            Group{
                                Rectangle().frame(width: 0, height: 25, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)
                            }.padding([.leading], 2.0).frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle().frame(width: 120, height: 15, alignment: .trailing).cornerRadius(6.0).foregroundStyle(Color.gray)
                                                                                
                        }.padding([.top], -14.0)
                        .padding([.leading], 2.0)
                    }
                    
                    VStack(alignment: .leading){
                        HStack{
                            Rectangle().frame(width: 30, height: 30).cornerRadius(6.0).foregroundStyle(Color.gray)
                            Rectangle().frame(width: 160, height: 30, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)

                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack{
                            Rectangle().frame(width: 90, height: 30, alignment: .trailing).cornerRadius(6.0).foregroundStyle(Color.gray)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                            .offset(x: 0.0, y: -37.5)
                        
                        HStack{
                            Rectangle().frame(width: 150, height: 25, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)
                            
                            Group{
                                Rectangle().frame(width: 0, height: 25, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)
                            }.padding([.leading], 2.0).frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle().frame(width: 120, height: 15, alignment: .trailing).cornerRadius(6.0).foregroundStyle(Color.gray)
                                                                                
                        }.padding([.top], -14.0)
                        .padding([.leading], 2.0)
                    }
                    
                    VStack(alignment: .leading){
                        HStack{
                            Rectangle().frame(width: 30, height: 30).cornerRadius(6.0).foregroundStyle(Color.gray)
                            Rectangle().frame(width: 160, height: 30, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)

                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack{
                            Rectangle().frame(width: 90, height: 30, alignment: .trailing).cornerRadius(6.0).foregroundStyle(Color.gray)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                            .offset(x: 0.0, y: -37.5)
                        
                        HStack{
                            Rectangle().frame(width: 150, height: 25, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)
                            
                            Group{
                                Rectangle().frame(width: 0, height: 25, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)
                            }.padding([.leading], 2.0).frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle().frame(width: 120, height: 15, alignment: .trailing).cornerRadius(6.0).foregroundStyle(Color.gray)
                                                                                
                        }.padding([.top], -14.0)
                        .padding([.leading], 2.0)
                    }
                    
                    VStack(alignment: .leading){
                        HStack{
                            Rectangle().frame(width: 30, height: 30).cornerRadius(6.0).foregroundStyle(Color.gray)
                            Rectangle().frame(width: 160, height: 30, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)

                        }.frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack{
                            Rectangle().frame(width: 90, height: 30, alignment: .trailing).cornerRadius(6.0).foregroundStyle(Color.gray)
                        }.frame(maxWidth: .infinity, alignment: .trailing)
                            .offset(x: 0.0, y: -37.5)
                        
                        HStack{
                            Rectangle().frame(width: 150, height: 25, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)
                            
                            Group{
                                Rectangle().frame(width: 0, height: 25, alignment: .leading).cornerRadius(6.0).foregroundStyle(Color.gray)
                            }.padding([.leading], 2.0).frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle().frame(width: 120, height: 15, alignment: .trailing).cornerRadius(6.0).foregroundStyle(Color.gray)
                                                                                
                        }.padding([.top], -14.0)
                        .padding([.leading], 2.0)
                    }
                }
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: nil,
            alignment: .center
        )
        .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
        .cornerRadius(12.0)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.15), radius: 10, x: 0, y: 0)

    }
}

struct DepartureList: View {
    @Namespace private var cardNamespace
    let onClose: () -> Void
    @State var expanded: Bool
    @State var activeId = UUID()
    @State var crs: String
    @EnvironmentObject var vm: DeparturesViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        //ZStack{
                VStack {
                    if expanded == true {
                        HStack(alignment: .center){
                            Text("Departures")
                                .font(.title).bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(Color.primary)
                        }.padding([.bottom], 10.0)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading){
                            if expanded == false {
                                HStack(alignment: .center){
                                    Text("Departures")
                                        .font(.title2).bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(Color.primary)
                                }.padding([.bottom], 10.0)
                            }
                            
                            if expanded == false {
                                ForEach(vm.depList.prefix(4).enumerated(), id: \.offset) { index, departure in
                                    let trust_data = DepartureTRUSTData(rid: departure.rid, uid: departure.uid, sdd: departure.sdd)
                                    
                                    if index == vm.depList.endIndex - 1 {
                                        TrainDepartureCard(id: departure.id, trust_data: trust_data, tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, cancelled: departure.cancelled)
                                            .padding([.top], 10.0)
                                            .padding([.bottom], 3.0)
                                    }else{
                                        TrainDepartureCard(id: departure.id, trust_data: trust_data,  tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, cancelled: departure.cancelled)
                                            .padding([.top, .bottom], 10.0)
                                        Divider()
                                    }
                                }
                            }else{
                                ForEach(vm.depList.enumerated(), id: \.offset) { index, departure in
                                    let trust_data = DepartureTRUSTData(rid: departure.rid, uid: departure.uid, sdd: departure.sdd)
                                    
                                    if index == vm.depList.endIndex - 1 {
                                        NavigationLink{
                                            ServiceView(serviceInfo: departure)
                                        } label: {
                                            TrainDepartureCard(id: departure.id, trust_data: trust_data, tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, cancelled: departure.cancelled)
                                                .padding([.top], 10.0)
                                                .padding([.bottom], 3.0)
                                        }
                                    }else{
                                        NavigationLink {
                                            ServiceView(serviceInfo: departure)
                                        } label: {
                                            TrainDepartureCard(id: departure.id, trust_data: trust_data,  tocCode: departure.operatorCode, destination: departure.destination, departureTime: departure.expectedDeparture ?? "UNKN", platform: departure.platformNo ?? "Unknown", coachNum: departure.trainLength, laterDepartures: departure.additionalServices ?? [], delayed: departure.isDelayed, cancelled: departure.cancelled)
                                                .padding([.top, .bottom], 10.0)
                                        }
                                        
                                        Divider()
                                    }
                                }
                            }
                        }/*.safeAreaPadding(.top, expanded ? 55 : 0)*/.edgesIgnoringSafeArea([.leading, .trailing])
                    }.edgesIgnoringSafeArea([.leading, .trailing])
                }
                .matchedGeometryEffect(id: "departures", in: cardNamespace)
                .padding()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: expanded ? .infinity : nil,
                    alignment: expanded ? .top : .center
                )
                .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
//        }.ignoresSafeArea()
//        .frame(
//            maxWidth: .infinity,
//            maxHeight: expanded ? .infinity : nil,
//            alignment: expanded ? .top : .center
//        )
//        .padding()
//        .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
//        .cornerRadius(expanded ? 0.0 : 12.0)
    }
}
