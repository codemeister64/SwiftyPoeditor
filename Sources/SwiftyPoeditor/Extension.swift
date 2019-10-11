//
//  Extension.swift
//  SwiftyPoeditor
//
//  Created by Oleksandr Vitruk on 9/28/19.
//

import Foundation

extension String {
    /// casts string to bool with extra cases
    var boolValue: Bool {
        switch self.lowercased() {
        case "true", "yes", "1":
            return true
        default:
            return false
        }
    }
}
