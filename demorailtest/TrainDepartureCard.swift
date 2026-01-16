//
//  TrainDepartureCard.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//


import SwiftUI
import Foundation

struct DepartureTRUSTData {
    var rid: String
    var uid: String
    var sdd: String
}

struct TrainDepartureCard: View {
//    @Binding var expanded: Bool
//    @Binding var activeId: UUID
//
    @Environment(\.colorScheme) var colorScheme
    
//    var id: UUID
    var trust_data: DepartureTRUSTData
    var tocCode: String
    var destination: String
    var departureTime: String
    var estimatedDepartureTime: String
    var platform: String
    var coachNum: Int
    var laterDepartures: [String]
    var delayed: Bool
    var delayLength: Int
    var cancelled: Bool
    
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
    
    func formatAdditionalDepartures(deplist: [String]) -> String {
        var res = ""
        
        if deplist.count == 0 {
            return ""
        }
            
        laterDepartures.prefix(3).enumerated().forEach { index, departure in
            if index == laterDepartures.prefix(3).endIndex - 1 {
                res += "\(formatTime(timeString: departure))"
            }else{
                res += "\(formatTime(timeString: departure)), "
            }
        }
        
        return res
    }
    
    var body: some View {
        VStack(alignment: .leading){
            HStack{
                Spacer(minLength: 15.0)
                Image(GetLogoOfTOC(code: tocCode))
                    .resizable()
                    .frame(width: 30, height: 30)
                    .cornerRadius(6.0)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.12), radius: 5, x: 0, y: 0)
                Text("\(destination)").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                
                if cancelled == true {
                    Text("\(formatTime(timeString: departureTime))").font(.title3).bold().frame(maxWidth: 65, alignment: .trailing).foregroundStyle(Color.red).strikethrough()
                }else{
                    if delayed == true {
                        if estimatedDepartureTime != "UNKN" && estimatedDepartureTime != "" {
                            Text("\(formatTime(timeString: estimatedDepartureTime))").font(.title3).bold().frame(maxWidth: 65, alignment: .trailing).foregroundStyle(Color.orange)
                        }else{
                            Text("\(formatTime(timeString: departureTime))").font(.title3).bold().frame(maxWidth: 65, alignment: .trailing).foregroundStyle(Color.orange)
                        }
                    }else{
                        Text("\(formatTime(timeString: departureTime))").font(.title3).bold().frame(maxWidth: 65, alignment: .trailing).foregroundStyle(Color.primary)
                    }
                    
                }
                Spacer(minLength: 15.0)
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top], 15)
            
            HStack{
                Spacer(minLength: 15.0)
                if coachNum != 0 {
                    Group{
                        Image(systemName: "train.side.middle.car")
                            .foregroundStyle(colorScheme == .dark ? Color(red: 210/255, green: 210/255, blue: 210/255) : Color.gray)
                            .frame(width: 13.0, height: 13.0)
                            .padding([.leading], 2.0)
                        Text("\(coachNum) Coaches")
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? Color(red: 210/255, green: 210/255, blue: 210/255) : Color.gray)
                    }.padding([.leading], 2.0)
                }else{
                    Group{
                        Image(systemName: "train.side.middle.car")
                            .foregroundStyle(colorScheme == .dark ? Color(red: 210/255, green: 210/255, blue: 210/255) : Color.gray)
                            .frame(width: 13.0, height: 13.0)
                            .padding([.leading], 2.0)
                        Text("Formation Unknown")
                            .font(.caption)
                            .foregroundStyle(colorScheme == .dark ? Color(red: 210/255, green: 210/255, blue: 210/255) : Color.gray)
                    }.padding([.leading], 2.0)
                }
                
                
                Text("Platform \(platform)")
                    .padding([.leading, .trailing], 10.0)
                    .padding([.top, .bottom], 2.0)
                    .font(.caption).bold()
                    .background(Color(red: 1 / 255, green: 48 / 255, blue: 102 / 255))
                    .foregroundStyle(Color.white)
                    .cornerRadius(8.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Spacer(minLength: 15.0)
            }.frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: 0.0, y: -7.0)
                .padding([.bottom], 5)
            
            HStack{
                Spacer(minLength: 15.0)
                if cancelled == true {
                    Group{
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Color.red)
                            .frame(width: 13.0, height: 13.0)
                        Text("Cancelled")
                            .font(.caption)
                            .foregroundStyle(Color.red)
                    }
                }else{
                    if delayed == true {
                        if delayLength > 0 {
                            Group{
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(Color.orange)
                                    .frame(width: 13.0, height: 13.0)
                                Text("\(delayLength) min late")
                                    .font(.caption)
                                    .foregroundStyle(Color.orange)
                            }
                        }else{
                            Group{
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(Color.orange)
                                    .frame(width: 13.0, height: 13.0)
                                Text("Delayed")
                                    .font(.caption)
                                    .foregroundStyle(Color.orange)
                            }
                        }
                    }else{
                        Group{
                            Image(systemName: "clock.fill")
                                .foregroundStyle(colorScheme == .dark ? Color(.green) : Color(red: 14/255, green: 137/255, blue: 45/255))
                                .frame(width: 13.0, height: 13.0)
                            Text("On Time")
                                .font(.caption)
                                .foregroundStyle(colorScheme == .dark ? Color(.green) : Color(red: 14/255, green: 137/255, blue: 45/255))
                        }
                    }
                    
                }
                
                if laterDepartures.count != 0 {
                    Text("(also at \(formatAdditionalDepartures(deplist: laterDepartures)))")
                        .font(.caption).foregroundStyle(colorScheme == .dark ? Color.white : Color.gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }else{
                    // Hacky way of keeping the time indicator on the left-hand side
                    Text("").font(.caption).foregroundStyle(colorScheme == .dark ? Color.white : Color.gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                }
                Spacer(minLength: 15.0)
            }.padding([.top], -14.0)
                .padding([.bottom], 15.0)
            .padding([.leading], 2.0)
        }
        .background(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color.white)
        .cornerRadius(12.0)
        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.08), radius: 10, x: 0, y: 0)
    }
}

#Preview {
    @Previewable @Environment(\.colorScheme) var colorScheme
    
    VStack{
        VStack(alignment: .leading) {
            HStack(alignment: .center){
                Text("Departures")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color.primary)
            }.padding([.bottom], 10.0)
            
            let trust_data = DepartureTRUSTData(rid: "", uid: "", sdd: "")
            
            TrainDepartureCard(trust_data: trust_data, tocCode: "VT", destination: "Liverpool Lime Street", departureTime: "2026-01-14T22:09:00", estimatedDepartureTime: "2026-01-14T03:32:00", platform: "7", coachNum: 10, laterDepartures: ["2026-01-10T15:25:00", "2026-01-10T15:25:00", "2026-01-10T15:25:00"], delayed: true, delayLength: 25, cancelled: false)
                .padding([.top], 10.0)
                .padding([.bottom], 3.0)
            
//            TrainDepartureCard(id: UUID(), trust_data: trust_data, tocCode: "XR", destination: "Liverpool Lime Street", departureTime: "2026-01-10T15:25:00", platform: "7", coachNum: 0, laterDepartures: [], delayed: false, cancelled: true)
//                .padding([.top], 10.0)
//                .padding([.bottom], 3.0)

        }
        .padding()
        .background(colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : Color.white)
        .hoverEffect()
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .center
    )
    .background(colorScheme == .dark ? Color.black : Color(red: 242/255, green: 242/255, blue: 247/255), ignoresSafeAreaEdges: [])
}
