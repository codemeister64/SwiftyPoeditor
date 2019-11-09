//
//  FileParser.swift
//  SwiftyPoeditor
//
//  Created by Oleksandr Vitruk on 9/28/19.
//

import Foundation
import AST
import Source
import Parser

typealias Member = EnumDeclaration.Member
typealias UnionStyleEnumCase = EnumDeclaration.UnionStyleEnumCase
typealias Case = EnumDeclaration.UnionStyleEnumCase.Case

enum FileParserError: Error, LocalizedError {
    case unknownMember(Member)
    case unknownDeclaration(Declaration, Member)
    case unknownCaseIdentifier(Case)
    case unknownEnumIdentifier(EnumDeclaration)
    case noKeysFound
    
    var errorDescription: String? {
        switch self {
        case .unknownMember(let member):
            return "FileParserError: unknown member type: \(member)"
        case .unknownDeclaration(let declaration, let member):
            return "FileParserError: unknown declaration \(declaration), member \(member)"
        case .unknownCaseIdentifier(let caseObject):
            return "FileParserError: unknown case identifier \(caseObject)"
        case .unknownEnumIdentifier(let enumObject):
            return "FileParserError: unknown enum identifier \(enumObject)"
        case .noKeysFound:
            return "FileParserError: localization keys not found"
        }
    }
}

class FileParser {
    
    // MARK: - Private properties
    
    private(set) var localizationKeys: [String] = [] // array to store parsed keys
    
    // MARK: - Public properties
    
    let settings: ParserSettings
    
    // MARK: - Lifecycle
    
    /// init localization enum file parser
    /// - Parameter settings: settings structure with parser params (ParserSettings)
    init(with settings: ParserSettings) {
        self.settings = settings
    }
    
    // MARK: - Public methods
    
    /// parse input file as localization enum
    func parse() throws -> [String] {
        // try to compose path to the file and escape it
        var rawPath = settings.path.removingPercentEncoding ?? settings.path
        rawPath = rawPath.replacingOccurrences(of: "\\", with: "")
        rawPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines).absolutePath
        
        // construct file url
        let fileURL = URL(fileURLWithPath: rawPath)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        // init file
        let file = SourceFile(path: fileURL.absoluteString, content: content)
        // init parser
        let parser = Parser(source: file)
        // run parser
        let topLevelDeclaration = try parser.parse()
        // cleanup possible previous results
        self.localizationKeys.removeAll()
        
        var members: [Member] = []
        // find top level I18n enum and get children/nested -enums
        for statement in topLevelDeclaration.statements {
            guard let enumStatement = statement as? EnumDeclaration else {
                continue
            }
            // switch statement used in order to avoid creation of custom Equatable extension.
            // (not compiling via terminal swift build, baybe some swift 5.1 bug)
            switch enumStatement.name {
            case .name(let name), .backtickedName(let name):
                guard name == settings.enumName else {
                    continue
                }
                members.append(contentsOf: enumStatement.members)
            default:
                continue
            }
        }
        // start keys generating recursively with root path
        try composeContext(members: members, rootPath: "")
        
        guard self.localizationKeys.isEmpty == false else {
            // check if keys found
            throw FileParserError.noKeysFound
        }
        
        return self.localizationKeys
    }
    
    // MARK: - Private methods
    
    /// recursively iteratet over nested enums and compose localization keys
    /// - Parameter members: enum child members
    /// - Parameter rootPath: enum current level path
    private func composeContext(members: [Member], rootPath: String) throws {
        var cases: [Case] = []
        var enums: [EnumDeclaration] = []
        
        // iterate over all members in current context
        for member in members {
            switch member {
            case .declaration(let declaration):
                // get all nested sub-enums in current context
                guard let nestedEnum = declaration as? EnumDeclaration else {
                    throw FileParserError.unknownDeclaration(declaration, member)
                }
                enums.append(nestedEnum)
            case .union(let union):
                // get all cases in current context
                cases.append(contentsOf: union.cases)
            default:
                // something that should not be here
                // not enum case and not enum declaration
                throw FileParserError.unknownMember(member)
            }
        }
        // iterate over founded cases
        for statement in cases {
            switch statement.name {
            case .name(let name), .backtickedName(let name):
                // use case identifier as key last component
                var key = rootPath.isEmpty == true ? name : rootPath + "." + name // add key component to current context path
                key = settings.lowercasedMode == true ? key.lowercased() : key // if lowercased mode enabled - lowercase current key
                localizationKeys.append(key) // save final key
            default:
                // something that we can parse
                throw FileParserError.unknownCaseIdentifier(statement)
            }
        }
        // iterate over founded sub-enums
        for statement in enums {
            var nestedRooPath: String
            
            switch statement.name {
            case .name(let name), .backtickedName(let name):
                // get enum name and append it to current path. It will generate next nested level context path
                nestedRooPath = rootPath.isEmpty == true ? name : rootPath + "." + name
            default:
                // something that we can`t parse
                throw FileParserError.unknownEnumIdentifier(statement)
            }
            // run parsing for next deeper level
            try composeContext(members: statement.members, rootPath: nestedRooPath)
        }
    }
}
