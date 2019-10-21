//
//  Extension.swift
//  SwiftyPoeditor
//
//  Created by Oleksandr Vitruk on 9/28/19.
//

import Foundation
import ConsoleKit

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

protocol PrettyOutput: class {
    var shortOutput: Bool { get set }
    var currentLoadingBar: ActivityIndicator<LoadingBar>? { get set }
    
    func createLoadingBar(context: CommandContext, title: String)
    func printToConsole(context: CommandContext,
                        string: String,
                        style: ConsoleStyle,
                        newLine: Bool)
}

extension PrettyOutput {
    
    /// creates loading bar if short output is false
    /// - Parameter context: console context
    /// - Parameter title: loading bar title
    func createLoadingBar(context: CommandContext, title: String) {
        guard shortOutput == false else { return  }
        currentLoadingBar = context.console.loadingBar(title: title)
    }
    
    /// print text to console with style or as plain text if short output is true
    /// - Parameter context: console context
    /// - Parameter string: string that should be printed
    /// - Parameter style: initial style
    /// - Parameter newLine: declares if print should be performed in new line
    func printToConsole(context: CommandContext,
                        string: String,
                        style: ConsoleStyle,
                        newLine: Bool = true) {
        
        let outputStyle: ConsoleStyle = shortOutput ? .plain : style
        
        context.console.output(string.consoleText(outputStyle), newLine: newLine)
    }
}
