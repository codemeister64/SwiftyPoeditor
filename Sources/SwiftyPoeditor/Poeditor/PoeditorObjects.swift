//
//  PoeditorObjects.swift
//  SwiftyPoeditor
//
//  Created by Oleksandr Vitruk on 10/2/19.
//

import Foundation

enum PoeditorExportType: String, Codable, CaseIterable {
    case appleStrings = "apple_strings"
    case androidStrings = "android_strings"
    case keyValueJSON = "key_value_json"
    case po, pot, mo, xls, xlsx, csv, ini, resw, resx, xliff, properties, json, yml, xmb, xtb
}

/// status of POEditor API requests
enum PoeditorResponseStatusType: String, Codable {
    case success, fail
}

/// POEditor API error codes
enum PoeditorResponseCodeType: String, Codable {
    case ok = "200"
    case missingAPIToken = "401"
    case invalidAPIToken = "4011"
    case noDataSentUsingPOST = "4012"
    case noPermissions = "403"
    case noAPIAccess = "4031"
    case stringLimitReached = "4032"
    case processingUploadedFile = "4033"
    case projectArchived = "4034"
    case invalidAPICall = "404"
    case customErrorMessage = "4040"
    case dataShouldBeJSON = "4042"
    case wrongLangugageCode = "4043"
    case projectNotContainingSpecifiedLanguage = "4044"
    case noLanguageSpecified = "4045"
    case unableToParseFile = "4046"
    case invalidExportType = "4047"
    case tooManyUploadRequests = "4048"
    case missingUpdatingParameter = "4049"
    case languageAlreadyInProject = "4050"
    case invalidDownloadURL = "4051"
    case expiredExportFile = "4052"
    case projectOrLanguageAltered = "4053"
    case tooManyRequests = "429"
}

/// POEditor API request status payload
struct PoeditorResponse: Codable {
    let status: PoeditorResponseStatusType
    let code: PoeditorResponseCodeType
    let message: String
}

/// Terms list paylod
struct Terms: Codable {
    struct Term: Codable {
        struct Translation: Codable {
            let content: String
            let fuzzy: Int
            let updated: Date?
        }
        
        let term, context, plural: String
        let created: Date
        let updated: Date?
        let reference: String
        let tags: [String]
        let comment: String
        let translation: Translation?
    }
    
    let terms: [Term]
    
    var allKeys: [String] {
        return terms.map { $0.term }
    }
}

/// Deletion result
struct DeleteResult: Codable {
    let parsed: Int
    let deleted: Int
}

/// Terms deletion payload wrapper
struct DeletedTerms: Codable {
    let terms: DeleteResult
}


/// Insertation result
struct AddResult: Codable {
    let parsed: Int
    let added: Int
}

/// Terms insertation payload wrapper
struct AddedTerms: Codable {
    let terms: AddResult
}

/// Top-level payload wrapper
struct PoeditorResult<Payload: Codable>: Codable {
    let response: PoeditorResponse
    let result: Payload?
}

/// Payload to delete or insert terms
struct TermValue: Codable {
    let term: String
}

/// Payload to export requested language
struct ExportRequestResult: Codable {
    enum CodingKeys: String, CodingKey {
        case urlPath = "url"
    }
    
    let urlPath: String
}
