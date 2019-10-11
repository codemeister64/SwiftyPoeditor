//
//  LocalizationsFileManager.swift
//  SwiftyPoeditor
//
//  Created by Oleksandr Vitruk on 10/4/19.
//

import Foundation

class LocalizationsFileManager {

    // MARK: - Private properties
    
    private var destinationPath: String {
        return settings.destinationPath.absolutePath
    }
    
    // MARK: - Public properties
    
    private(set) var fileManager: FileManager
    let settings: FileManagerSettings
    
    // MARK: - Lifecycle
    
    /// initializing
    /// - Parameter settings: input settings
    init(settings: FileManagerSettings) {
        self.settings = settings
        self.fileManager = FileManager.default
    }
    
    // MARK: - Public methods
    
    /// write data to destination file
    /// - Parameter data: data content
    func writeData(data: Data) throws -> URL {
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        if checkIfFileExist(url: destinationURL) == false {
            createDestinationPath(url: destinationURL)
        }
        
        try data.write(to: destinationURL, options: .atomic)
    
        return destinationURL
    }
    
    // MARK: - Private methods
    
    /// check wether destination file exist
    private func checkIfFileExist(url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    /// create empty file and needed folders on destination path
    @discardableResult private func createDestinationPath(url: URL) -> Bool {
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        return fileManager.createFile(atPath: url.path, contents: nil, attributes: nil)
    }
}
