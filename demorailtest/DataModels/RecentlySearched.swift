//
//  AppData.swift
//  demorailtest
//
//  Created by James on 14/01/2026.
//

import Foundation
import SwiftData

struct RecentlySearchedSchema: Codable, Hashable{
    let stationName: String
    let crsCode: String
}

@Model
class RecentlySearched: Identifiable {
    var station: RecentlySearchedSchema
    
    init(station_info: RecentlySearchedSchema){
        self.station = station_info
    }
}
