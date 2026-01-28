//
//  ServiceTracker.swift
//  demorailtest
//
//  Created by James on 27/01/2026.
//

import ActivityKit
import Foundation

struct ServiceTrackerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var origin: String
        var destination: String
        var nextStop: String
        var totalStops: Int
        var remainingStops: Int
    }
    
    var printName: String
    var estimatedDuration: TimeInterval
}

@Observable
class ServiceTrackerModel {
    var origin = "Euston"
    var destination = "Manchester Piccadilly"
    var nextStop = "Watford Junction"
    var totalStops = 5
    var remainingStops = 3
    let cardDuration: TimeInterval = 60
    
    var serviceActivity: Activity<ServiceTrackerAttributes>? = nil
    var elapsedTime: TimeInterval = 0
    

    func startLiveActivity(){
        let attributes = ServiceTrackerAttributes(printName: origin, estimatedDuration: cardDuration)
        
        let initialState = ServiceTrackerAttributes.ContentState(
            origin: "Euston", destination: "Manchester Piccadilly", nextStop: "Watford Junction", totalStops: 5, remainingStops: 3
        )
        
        do {
            serviceActivity = try Activity.request(attributes: attributes, content: ActivityContent(state: initialState, staleDate: nil))
        } catch {
            print("Error starting live activity: \(error)")
        }
    }
    
    func updateLiveActivity(){
        let nextStation: String = ""
        let stopsRemaining = 2
        
        let updatedState = ServiceTrackerAttributes.ContentState(
            origin: origin,
            destination: destination,
            nextStop: nextStation,
            totalStops: totalStops,
            remainingStops: stopsRemaining
        )
        
        Task {
            await serviceActivity?.update(using: updatedState)
        }
    }
    
    func endLiveActivity(success: Bool = false){
        
        let finalState = ServiceTrackerAttributes.ContentState(
            origin: origin, destination: destination, nextStop: "", totalStops: 5, remainingStops: 0
        )
        
        Task {
            await serviceActivity?.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .default)
        }
    }
}

import SwiftUI

struct ServiceTrackerView: View {
    
    @State private var origin = ""
    @State private var destination = ""
    @State private var next_stop = ""
    @State private var stopsRemaining = 0
    @State private var totalStops = 0
    
    var body: some View {
        
    }
}
