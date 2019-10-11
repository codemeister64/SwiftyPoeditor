//
//  Constants.swift
//  SwiftyPoeditor
//
//  Created by Oleksandr Vitruk on 9/28/19.
//

import Foundation

// MARK - Predefined constants

struct Constants {
    struct Defaults {
        static let lowercasedMode = "true"
        static let enumName = "I18n"
        static let language = "en"
        static let deleteRemovals = "true"
        static let exportType: PoeditorExportType = .appleStrings
    }
    
    struct API {
        static let baseURL = "https://api.poeditor.com"
        static let version = "v2"
        static let termsListEndpoint = "terms/list"
        static let termsAddEndpoint = "terms/add"
        static let termsDeleteEndpoint = "terms/delete"
        static let exportLocalizationEndpoint = "projects/export"
    }
}

// MARK - Settings objects declarations

struct ParserSettings {
    let path: String
    let lowercasedMode: Bool
    let enumName: String
}

struct PoeditorSettings {
    let token: String
    let id: String
    let language: String
}

struct FileManagerSettings {
    let destinationPath: String
}

struct UploadSettings {
    let parserSettings: ParserSettings
    let poeditorSettings: PoeditorSettings
    let deleteRemovals: Bool
}

struct DownloadSettings {
    let poeditorSettings: PoeditorSettings
    let fileManagerSettings: FileManagerSettings
    let type: PoeditorExportType
}
