//
//  PinnedServices.swift
//  demorailtest
//
//  Created by James on 28/01/2026.
//

import Foundation
import SwiftData

struct PinnedServiceSchema: Codable, Hashable {
    var origin: String
    var destination: String
    var `operator`: String
    var operatorCode: String
    var cancelled: Bool
    var cancelReason: String? = ""
    var trackingFrom: String
    var trackingTo: String
    var rid: String
    var uid: String
    var sdd: String
    var eta: String
    var ata: String
}

@Model
class PinnedService: Identifiable {
    var pinned_service: PinnedServiceSchema
    
    init(service: PinnedServiceSchema){
        self.pinned_service = service
    }
}
