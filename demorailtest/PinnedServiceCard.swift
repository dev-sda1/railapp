//
//  TrainDepartureCard.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//


import SwiftUI
import Foundation
import uk_railway_stations

enum PinnedServiceCardStyle {
    case arrived
    case ongoing
}

struct PinnedServiceCard: View {
    let style: PinnedServiceCardStyle

    @Environment(\.colorScheme) var colorScheme
    
    var serviceData: PinnedServiceSchema
    
    struct StationJSONFileEntry : Codable {
        let stationName: String
        let lat: Double
        let long: Double
        let crsCode: String
        let constituentCountry: String
    }
        
    func formatYear(timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd"
        formatter.locale = Locale(identifier: "en_GB_POSIX")

        let date = formatter.date(from: timeString)?.formatted(date: .numeric, time: .omitted) ?? "01/01/1970"
        
        return date
    }
    
    func getStationNameFromCRS(crsString: String) -> String {
        let url = Bundle.stationsJSONBundleURL
        guard let data = try? Data(contentsOf: url) else { return "" }
        
        let decoder = JSONDecoder()
        
        guard let stations = try? decoder.decode([StationJSONFileEntry].self, from: data) else { return "" }
        
        var foundStation = ""
        
        stations.forEach{file_entry in
            if file_entry.crsCode == crsString {
                foundStation = file_entry.stationName
            }
        }
        
        return foundStation
    }
        
    var body: some View {
        switch style {
        case .arrived:
            VStack(alignment: .leading){
                HStack{
                    Spacer(minLength: 15.0)
                    Image(GetLogoOfTOC(code: serviceData.operatorCode))
                        .resizable()
                        .frame(width: 30, height: 30)
                        .cornerRadius(6.0)
                        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.12), radius: 5, x: 0, y: 0)
                    VStack{
                        Text("\(getStationNameFromCRS(crsString: serviceData.trackingFrom)) to").font(.caption).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary).padding(.bottom, -5)
                        Text("\(getStationNameFromCRS(crsString: serviceData.trackingTo))").font(.subheadline).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                    }
                    
                    Spacer(minLength: 15.0)
                    
//                    Text("On Time")
//                        .padding(.trailing, 16).font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top], 15)
                
//                HStack{
//                    Spacer(minLength: 15.0)
//
//                    
//                    Spacer(minLength: 15.0)
//                }.frame(maxWidth: .infinity, alignment: .leading)
//                    .offset(x: 0.0, y: -7.0)
//                    .padding([.bottom], 5)
                
                HStack{
                    Text("\(formatYear(timeString: serviceData.sdd))").font(.caption).frame(maxWidth: .infinity, alignment: .leading)
//                    Text("Arrived on time at 12:45").font(.caption).bold().frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, -10)
                .padding()
            }
            .background(colorScheme == .dark ? .white.opacity(0.03) : .clear).clipShape(.rect(cornerRadius: 19.0))
    //        .glassEffect(in: .rect(cornerRadius: 19.0))
            #if os(iOS)
            .glassEffect(.regular.tint(colorScheme == .dark ? .clear : .white).interactive(), in: .rect(cornerRadius: 19.0))
            #endif
    //        .background(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color.white)
    //        .cornerRadius(12.0)
            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.08), radius: 10, x: 0, y: 0)
        case .ongoing:
            VStack(alignment: .leading){
                HStack{
                    Spacer(minLength: 15.0)
                    Image(GetLogoOfTOC(code: serviceData.operatorCode))
                        .resizable()
                        .frame(width: 30, height: 30)
                        .cornerRadius(6.0)
                        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.12), radius: 5, x: 0, y: 0)
                    Text("\(serviceData.trackingTo)").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                    
                    
                    Spacer(minLength: 15.0)
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top], 15)
                
                HStack{
                    Spacer(minLength: 15.0)

                    
                    Spacer(minLength: 15.0)
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: 0.0, y: -7.0)
                    .padding([.bottom], 5)
                
                HStack{
                    Spacer(minLength: 15.0)
                    
                    Spacer(minLength: 15.0)
                }.padding([.top], -14.0)
                    .padding([.bottom], 15.0)
                .padding([.leading], 2.0)
            }
            .background(colorScheme == .dark ? .white.opacity(0.03) : .clear).clipShape(.rect(cornerRadius: 19.0))
    //        .glassEffect(in: .rect(cornerRadius: 19.0))
            #if os(iOS)
            .glassEffect(.regular.tint(colorScheme == .dark ? .clear : .white).interactive(), in: .rect(cornerRadius: 19.0))
            #endif
    //        .background(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color.white)
    //        .cornerRadius(12.0)
            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.08), radius: 10, x: 0, y: 0)
        }
    }
}

#Preview("Service Arrived") {
    @Previewable @Environment(\.colorScheme) var colorScheme
    
    VStack{
        VStack(alignment: .leading) {
            HStack(alignment: .center){
                Text("Previous Journeys")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.primary)
            }.padding([.bottom], 10.0)
                        
            PinnedServiceCard(style: .arrived, serviceData: PinnedServiceSchema(origin: "EUS", destination: "WVH", operator: "Avanti West Coast", operatorCode: "VT", cancelled: false, trackingFrom: "EUS", trackingTo: "WVH", rid: "", uid: "L02351", sdd: "2026-01-29", eta: "2026-01-29T21:40:00", ata: "2026-01-29T21:40:00"))
                .padding([.top], 10.0)
                .padding([.bottom], 3.0)
        }
        .padding()
        .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
        #if os(iOS) || os(visionOS)
        .hoverEffect()
        #endif
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 16)
        .blendMode(.lighten)

    }
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .center
    )
    .background(colorScheme == .dark ? Color.black : Color(red: 242/255, green: 242/255, blue: 247/255), ignoresSafeAreaEdges: [])
}

#Preview("Live Service") {
    @Previewable @Environment(\.colorScheme) var colorScheme
    
    VStack{
        VStack(alignment: .leading) {
            HStack(alignment: .center){
                Text("Current Journey")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.primary)
            }.padding([.bottom], 10.0)
                        
            PinnedServiceCard(style: .arrived, serviceData: PinnedServiceSchema(origin: "EUS", destination: "WVH", operator: "Avanti West Coast", operatorCode: "VT", cancelled: false, trackingFrom: "EUS", trackingTo: "WVH", rid: "", uid: "L02351", sdd: "2026-01-29", eta: "", ata: ""))
                .padding([.top], 10.0)
                .padding([.bottom], 3.0)
            
        }
        .padding()
        .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
        #if os(iOS) || os(visionOS)
        .hoverEffect()
        #endif
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 16)
        .blendMode(.lighten)

    }
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .center
    )
    .background(colorScheme == .dark ? Color.black : Color(red: 242/255, green: 242/255, blue: 247/255), ignoresSafeAreaEdges: [])
}
