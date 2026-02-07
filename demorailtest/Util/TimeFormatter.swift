//
//  TimeFormatter.swift
//  demorailtest
//
//  Created by James on 04/02/2026.
//

import Foundation

func formatTime(timeString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyy-MM-dd'T'HH:mm:ss"
    formatter.locale = Locale(identifier: "en_GB_POSIX")
    
    var date = formatter.date(from: timeString)?.formatted(date: .omitted, time: .standard) ?? "00:00"
    if date.count == 4 {
        date = "0\(date)"
    }
    
    var formatted = ""
    
    if date.firstIndex(of: "a") == nil && date.firstIndex(of: "p") == nil {
        formatted = "\(date.split(separator: ":")[0]):\(date.split(separator: ":")[1])"
    }else{
        formatted = "\(date.split(separator: ":")[0]):\(date.split(separator: ":")[1])\(date.split(separator: ":")[2].suffix(2))"
    }
    
    if formatted.count == 4 {
        formatted = "0\(formatted)"
    }
            
    return formatted
}

