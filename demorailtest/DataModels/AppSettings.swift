//
//  AppData.swift
//  demorailtest
//
//  Created by James on 14/01/2026.
//

import Foundation

class AppSettingsManager {
    private let defaults = UserDefaults.standard
    
    var useDarwin: Bool {
        get { return defaults.value(forKey: "useDarwin") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "useDarwin") }
    }
}
