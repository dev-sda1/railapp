//
//  TOCs.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//

import SwiftUI

public enum TOCs {
    case TranspennineExpress,AvantiWestCoast,Northern,Eurostar,Merseyrail,TransportForWales, C2C,CaledonianSleeper,ChilternRailways,CrossCountry,HullTrains,GrandCentral,GreaterAnglia,GreatWesternRailway,GreatNorthern,HeathrowExpress,ElizabethLine,IslandLine,LondonOverground,ScotRail,SouthWesternRailway,Southeastern,Southern,LNWR,WestMidlandsTrains,Freight,LNER,EMR,GatwickExpress,Lumo,Thameslink
    
//    var colour: Color {
//        switch self {
//        case .TranspennineExpress:
//            return Color(red: 0.0, green: 0.0, blue: 0.0)
//        case .AvantiWestCoast:
//            return Color(red: 0.0, green: 0.0, blue: 0.0)
//        case .Northern:
//            return Color(red: 0.0, green: 0.0, blue: 0.0)
//        }
//    }
    
    var toc_code: String {
        switch self {
        case .TranspennineExpress:
            return "TP"
        case .AvantiWestCoast:
            return "VT"
        case .Northern:
            return "NT"
        case .Eurostar:
            return "ES"
        case .Merseyrail:
            return "ME"
        case .TransportForWales:
            return "AW"
        case .C2C:
            return "CC"
        case .CaledonianSleeper:
            return "CS"
        case .ChilternRailways:
            return "CH"
        case .CrossCountry:
            return "XC"
        case .HullTrains:
            return "HT"
        case .GrandCentral:
            return "GC"
        case .GreaterAnglia:
            return "LE"
        case .GreatWesternRailway:
            return "GW"
        case .GreatNorthern:
            return "GN"
        case .HeathrowExpress:
            return "HX"
        case .ElizabethLine:
            return "XR"
        case .IslandLine:
            return "IL"
        case .LondonOverground:
            return "LO"
        case .ScotRail:
            return "SR"
        case .SouthWesternRailway:
            return "SW"
        case .Southeastern:
            return "SE"
        case .Southern:
            return "SN"
        case .LNWR:
            return "LM"
        case .WestMidlandsTrains:
            return "LM"
        case .Freight:
            return "ZZ"
        case .LNER:
            return "GR"
        case .EMR:
            return "EM"
        case .Lumo:
            return "LD"
        case .Thameslink:
            return "TL"
        case .GatwickExpress:
            return "GX"
        }
    }
}


func GetLogoOfTOC(code: String) -> ImageResource {
    switch code {
    case TOCs.TranspennineExpress.toc_code:
        return ImageResource(name: "TransPennine Express", bundle: .main)
    case TOCs.AvantiWestCoast.toc_code:
        return ImageResource(name: "avanti", bundle: .main)
    case TOCs.Northern.toc_code:
        return ImageResource(name: "Northern Trains", bundle: .main)
    case TOCs.Eurostar.toc_code:
        return ImageResource(name: "Eurostar", bundle: .main)
    case TOCs.Merseyrail.toc_code:
        return ImageResource(name: "Merseyrail", bundle: .main)
    case TOCs.TransportForWales.toc_code:
        return ImageResource(name: "TransportForWales", bundle: .main)
    case TOCs.C2C.toc_code:
        return ImageResource(name: "C2C", bundle: .main)
    case TOCs.CaledonianSleeper.toc_code:
        return ImageResource(name: "Caledonian Sleeper", bundle: .main)
    case TOCs.ChilternRailways.toc_code:
        return ImageResource(name: "Chiltern", bundle: .main)
    case TOCs.CrossCountry.toc_code:
        return ImageResource(name: "CrossCountry", bundle: .main)
    case TOCs.HullTrains.toc_code:
        return ImageResource(name: "HullTrains", bundle: .main)
    case TOCs.GreatNorthern.toc_code:
        return ImageResource(name: "GreatNorthern", bundle: .main)
    case TOCs.GrandCentral.toc_code:
        return ImageResource(name: "GrandCentral", bundle: .main)
    case TOCs.GreaterAnglia.toc_code:
        return ImageResource(name: "GreaterAnglia", bundle: .main)
    case TOCs.GreatWesternRailway.toc_code:
        return ImageResource(name: "GWR", bundle: .main)
    case TOCs.HeathrowExpress.toc_code:
        return ImageResource(name: "Heathrow Express", bundle: .main)
    case TOCs.ElizabethLine.toc_code:
        return ImageResource(name: "Elizabeth Line", bundle: .main)
    case TOCs.IslandLine.toc_code:
        return ImageResource(name: "IslandLine", bundle: .main)
    case TOCs.LondonOverground.toc_code:
        return ImageResource(name: "London Overground", bundle: .main)
    case TOCs.ScotRail.toc_code:
        return ImageResource(name: "Scotrail", bundle: .main)
    case TOCs.SouthWesternRailway.toc_code:
        return ImageResource(name: "South Western Railway", bundle: .main)
    case TOCs.Southeastern.toc_code:
        return ImageResource(name: "South Eastern", bundle: .main)
    case TOCs.Southern.toc_code:
        return ImageResource(name: "Southern", bundle: .main)
    case TOCs.LNWR.toc_code:
        return ImageResource(name: "LNWR", bundle: .main)
    case TOCs.WestMidlandsTrains.toc_code:
        return ImageResource(name: "WMR", bundle: .main)
    case TOCs.Freight.toc_code:
        return ImageResource(name: "Generic", bundle: .main)
    case TOCs.LNER.toc_code:
        return ImageResource(name: "LNER", bundle: .main)
    case TOCs.EMR.toc_code:
        return ImageResource(name: "EMR", bundle: .main)
    case TOCs.Lumo.toc_code:
        return ImageResource(name: "Lumo", bundle: .main)
    case TOCs.Thameslink.toc_code:
        return ImageResource(name: "Thameslink", bundle: .main)
    case TOCs.GatwickExpress.toc_code:
        return ImageResource(name: "avanti", bundle: .main)
    default:
        print("Couldn't find logo for: \(code), using generic.")
        return ImageResource(name: "Generic", bundle: .main)
    }
}
