//
//  ContentView.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//

import SwiftUI
import CoreLocation
import uk_railway_stations
import Ifrit
import SwiftData

struct ContentView: View {
    @State private var selection: TabKey = .here
    @State var scrollText = true
    @State var searchTxt = ""
    
    var body: some View {
        TabView(selection: $selection) {
            Tab("Here", systemImage: "location.fill", value: TabKey.here) {
                HereView()
            }
            
            Tab("Journeys", systemImage: "tram.fill", value: TabKey.journeys) {
                PinnedServicesView()
            }
            
            Tab("Live Trains", systemImage: "clock.badge.fill", value: TabKey.live) {
                StationSearch()
            }
            
//            Tab("Debug", systemImage: "hammer.fill", value: TabKey.debug) {
//                QuickDebugView()
//            }
            
        }
        
        #if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
        
        #if os(macOS)
        .tabViewStyle(.sidebarAdaptable)
        #endif
        // TODO: Come back to tabViewBottomAccessory at a later date.
//        .tabViewBottomAccessory {
//            BottomAccessoryView()
//        }
    }
}

#Preview {
    ContentView()
}

private enum TabKey: Hashable {
    case here, live, journeys, debug
}

struct BottomAccessoryView: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement

    var body: some View {
        switch placement{
        case .inline:
            BottomViewInline()
        case .expanded:
            BottomViewExpanded()
        case .none:
            BottomViewInline()
        }
    }
}

struct BottomViewExpanded: View {
    @State private var txtOffset = 10.0

    var body: some View {
        HStack {
            Spacer(minLength: 13.0)
            Image(.avanti).resizable().frame(width: 33, height: 33).cornerRadius(6.0)
            
            VStack(alignment: .leading) {
                Text("18:30 to Liverpool Lime Street")
                    .font(.footnote)
                    .fixedSize()
                
                HStack {
                    Group {
                        Text("ETA 20:07 ")
                            .font(.footnote)
                            .foregroundColor(.primary) +
                        Text("(On time)")
                            .font(.footnote)
                            .foregroundColor(.green) +
                        Text(" • Next Stop: Liverpool South Parkway")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: txtOffset, y: 0)
                    .animation(.linear(duration: 10).repeatForever(autoreverses: true))
                    .onAppear {
                        txtOffset = -170.0
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                .clipped()
            }
            
            HStack{
                Text("25 stops")
                    .font(.footnote)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.up")
                    .resizable()
                    .frame(width: 11, height: 7)
            }
            .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 10.0)
        }.containerRelativeFrame(
            [.horizontal, .vertical],
            alignment: .center
        )
    }
}

struct BottomViewInline: View {
    @State private var txtOffset = 15.0

    var body: some View {
        HStack {
            Spacer()
            Image(.avanti).resizable().frame(width: 33, height: 33).cornerRadius(6.0)
            
            VStack(alignment: .leading) {
                Text("25 stops")
                    .font(.footnote)
                    .fixedSize()
                
                HStack {
                    Group {
                        Text("ETA 20:07 ")
                            .font(.footnote)
                            .foregroundColor(.primary) +
                        Text("(On time)")
                            .font(.footnote)
                            .foregroundColor(.green) +
                        Text(" • Next Stop: Liverpool South Parkway")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: txtOffset, y: 0)
                    .animation(.linear(duration: 10).repeatForever(autoreverses: true))
                    .onAppear {
                        txtOffset = -200.0
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                .clipped()
                
            }
            
            HStack{
                Image(systemName: "chevron.up")
                    .resizable()
                    .frame(width: 11, height: 7)
            }
            
            Spacer()
        }.containerRelativeFrame(
            [.horizontal, .vertical],
            alignment: .center
        )
    }
}
