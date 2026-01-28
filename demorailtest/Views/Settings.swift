//
//  Settings.swift
//  demorailtest
//
//  Created by James on 25/01/2026.
//
import SwiftUI
import Foundation
import SwiftData

struct SettingsPage: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isDarwin = AppSettingsManager().useDarwin
            
    var body: some View {
        NavigationStack {
            ZStack{
                ScrollView {
                    VStack(){
                        Toggle(isOn: $isDarwin) {
                            Text("Use Darwin Push Port")
                            Text("Darwin Client is in testing, data may be inaccurate or missing").font(.subheadline)
                        }
                        .onChange(of: isDarwin) { oldValue, newValue in
                            if newValue == true && oldValue == false {
                                AppSettingsManager().useDarwin = true
                            }else{
                                AppSettingsManager().useDarwin = true
                            }
                        }
                        
                        VStack(alignment: .leading){
                            Text("Attribution").font(.title2).bold().frame(maxWidth: .infinity, alignment: .leading)
                            HStack{
                                Text("Contains public sector information licensed under the [Open Government Licence v3.0.](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)").font(.subheadline).padding(.top, 1)
                            }
                            Divider()
                            Text("Uses Darwin Real Time Information and LDBWS under an open licence by [Rail Delivery Group](https://raildata.org.uk)").font(.subheadline)
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .background(colorScheme == .dark ? Color.black : Color(red: 242/255, green: 242/255, blue: 247/255))
            .navigationTitle("Settings")
            .font(.headline)
        }
    }
}


#Preview {
    SettingsPage()
}
