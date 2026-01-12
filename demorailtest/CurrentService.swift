//
//  ContentView.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//

import SwiftUI

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
        isDelayed: false,
        rid: "202601108925258",
        uid: "Y25258",
        sdd: "2026-01-10"
    )
    
    var body: some View {
        ServiceView(serviceInfo: sampleDeparture)
    }
}

#Preview {
    CurrentService()
}

struct ServiceView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var scrollPosition: Double = 0
    @State private var loadingData: Bool = true
    @State private var layoutID = UUID()
    @State var serviceInfo: DepartureItem
    @State var isPinned = false
    
    let urlString = "https://localhost:3000/station/MAN"
    
    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGPoint = .zero

        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
    }
    
    func formatTime(timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: timeString)?.formatted(date: .omitted, time: .shortened) ?? "00:00"
    }
            
    var body: some View {
        ZStack{
            NavigationStack {
                ZStack{
                    ScrollView {
                        Text("\(formatTime(timeString: serviceInfo.expectedDeparture ?? "00:00"))").font(.title).bold().frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
                        Text("\(serviceInfo.origin) to \(serviceInfo.destination)").font(.title2).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Color.primary)
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
    }
}
