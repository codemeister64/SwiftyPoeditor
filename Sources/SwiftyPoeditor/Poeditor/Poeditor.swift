//
//  Poeditor.swift
//  SwiftyPoeditor
//
//  Created by Oleksandr Vitruk on 9/29/19.
//

import Foundation
import SwiftyRequest
import NIO

enum PoeditorError: Error, LocalizedError {
    case unableEncodeBody(String)
    case wrongResponse
    case unableToGetJSONString
    case unableToCreateURLOnSavePath(String)
    
    var errorDescription: String? {
        switch self {
        case .unableEncodeBody(let params):
            return "Poeditor: unable to recode body from with params: \(params)"
        case .wrongResponse:
            return "Poeditor: Wrong response"
        case .unableToGetJSONString:
            return "Poeditor: Unable to decode provided Data to JSON String"
        case .unableToCreateURLOnSavePath(let path):
            return "Poeditor: Unable to create URL on save path with path \(path)"
        }
    }
}

class Poeditor {
    #warning("TODO: remove IBM SwiftyRequest and use something better. Maybe native async-http-client with custom wrapper. SwiftyRequest can't deal with futures outside. So currently we need to create own eventloop")
    
    // MARK: - Private properties
    
    private let settings: PoeditorSettings
    private let eventLoop: MultiThreadedEventLoopGroup
    private lazy var decoder: JSONDecoder = {
        // json decoder with custom date decode strategy
        let decoder = JSONDecoder()
        // json value e.g: "2013-06-10T11:08:54+0000"
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            guard let date = formatter.date(from: dateString) else {
                return Date()
            }
            
            return date
        })
        
        return decoder
    }()
    
    private lazy var encoder: JSONEncoder = JSONEncoder()
    
    // MARK: - Lifecycle
    
    /// init POEditor API client
    /// - Parameter settings: settings structure with API params (PoeditorSettings)
    /// - Parameter eventLoop: eventloop on which future result should be returned.
    /// - Used to create future/promises and retain long-term operation
    init(settings: PoeditorSettings,
         eventLoop: MultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)) {
        
        self.settings = settings
        self.eventLoop = eventLoop // use default event-loop
    }
    
    deinit {
        // shutdown eventloop
        shutDown()
    }
    
    // MARK: - Public methods
    
    /// returns future result with list of all available terms
    func getAllTerms() -> EventLoopFuture<Terms> {
        // create promise to return future result
        let promise = eventLoop.next().makePromise(of: Terms.self)
        
        // generate url and body
        let urlPath = Constants.API.baseURL + "/" + Constants.API.version + "/" + Constants.API.termsListEndpoint
        let bodyString = "api_token=\(settings.token)&id=\(settings.id)&language=\(settings.language)"
        let body = bodyString.data(using: .utf8)
        
        guard let encodedBody = body else {
            promise.fail(PoeditorError.unableEncodeBody(bodyString))
            return promise.futureResult
        }
        
        // create request
        let request = RestRequest(method: .post,
                                  url: urlPath)
        request.contentType = "application/x-www-form-urlencoded"
        request.messageBody = encodedBody
        request.responseData { [weak self] response in
            switch response {
            case .success(let result):
                let data = result.body
                do {
                    // try to decode data to expected objects
                    guard let decoded = try self?.decode(to: PoeditorResult<Terms>.self, data: data),
                        let term = decoded.result else {
                            return promise.fail(PoeditorError.wrongResponse)
                    }
                    
                    promise.succeed(term)
                } catch {
                    promise.fail(error)
                }
            case .failure(let error):
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
    
    /// returns future result with deletion info
    /// - Parameter terms: array of values that should be deleted
    func deleteTerms(terms: [TermValue]) -> EventLoopFuture<DeleteResult> {
        // create promise to return future result
        let promise = eventLoop.next().makePromise(of: DeleteResult.self)
        
        // generate url and body
        let urlPath = Constants.API.baseURL + "/" + Constants.API.version + "/" + Constants.API.termsDeleteEndpoint
        var bodyString = "api_token=\(settings.token)&id=\(settings.id)"
        
        do {
            let encodedString = try encode(value: terms)
            bodyString += "&data=\(encodedString)"
        } catch {
            promise.fail(error)
            return promise.futureResult
        }
        
        let body = bodyString.data(using: .utf8)
        
        guard let encodedBody = body else {
            promise.fail(PoeditorError.unableEncodeBody(bodyString))
            return promise.futureResult
        }
        
        // create request
        let request = RestRequest(method: .post,
                                  url: urlPath)
        request.contentType = "application/x-www-form-urlencoded"
        request.messageBody = encodedBody
        request.responseData { [weak self] response in
            switch response {
            case .success(let result):
                let data = result.body
                do {
                    // try to decode data to expected objects
                    guard let decoded = try self?.decode(to: PoeditorResult<DeletedTerms>.self, data: data),
                        let term = decoded.result?.terms else {
                            return promise.fail(PoeditorError.wrongResponse)
                    }
                    
                    promise.succeed(term)
                } catch {
                    promise.fail(error)
                }
            case .failure(let error):
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
    
    /// returns future result with insertation info
    /// - Parameter terms: array of values that should be inserted
    func addTerms(terms: [TermValue]) -> EventLoopFuture<AddResult> {
        // create promise to return future result
        let promise = eventLoop.next().makePromise(of: AddResult.self)
        
        // generate url and body
        let urlPath = Constants.API.baseURL + "/" + Constants.API.version + "/" + Constants.API.termsAddEndpoint
        var bodyString = "api_token=\(settings.token)&id=\(settings.id)"
        
        do {
            let encodedString = try encode(value: terms)
            bodyString += "&data=\(encodedString)"
        } catch {
            promise.fail(error)
            return promise.futureResult
        }
        
        let body = bodyString.data(using: .utf8)
        
        guard let encodedBody = body else {
            promise.fail(PoeditorError.unableEncodeBody(bodyString))
            return promise.futureResult
        }
        
        // create request
        let request = RestRequest(method: .post,
                                  url: urlPath)
        request.contentType = "application/x-www-form-urlencoded"
        request.messageBody = encodedBody
        request.responseData { [weak self] response in
            switch response {
            case .success(let result):
                let data = result.body
                do {
                    // try to decode data to expected objects
                    guard let decoded = try self?.decode(to: PoeditorResult<AddedTerms>.self, data: data),
                        let term = decoded.result?.terms else {
                            return promise.fail(PoeditorError.wrongResponse)
                    }
                    
                    promise.succeed(term)
                } catch {
                    promise.fail(error)
                }
            case .failure(let error):
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
    
    /// returns future result with download url path for requested localization
    /// - Parameter exportType: format type in which localization should be exported
    func requestExportLocalization(exportType: PoeditorExportType) -> EventLoopFuture<ExportRequestResult> {
        // create promise to return future result
        let promise = eventLoop.next().makePromise(of: ExportRequestResult.self)
        
        // generate url and body
        let urlPath = Constants.API.baseURL + "/" + Constants.API.version + "/" + Constants.API.exportLocalizationEndpoint
        let language = settings.language
        let bodyString = "api_token=\(settings.token)&id=\(settings.id)&language=\(language)&type=\(exportType.rawValue)&order=terms"
        let body = bodyString.data(using: .utf8)
        
        guard let encodedBody = body else {
            promise.fail(PoeditorError.unableEncodeBody(bodyString))
            return promise.futureResult
        }
        
        // create request
        let request = RestRequest(method: .post,
                                  url: urlPath)
        request.contentType = "application/x-www-form-urlencoded"
        request.messageBody = encodedBody
        request.responseData { [weak self] response in
            switch response {
            case .success(let result):
                let data = result.body
                do {
                    // try to decode data to expected objects
                    guard let decoded = try self?.decode(to: PoeditorResult<ExportRequestResult>.self, data: data),
                        let result = decoded.result else {
                            return promise.fail(PoeditorError.wrongResponse)
                    }
                    
                    promise.succeed(result)
                } catch {
                    promise.fail(error)
                }
            case .failure(let error):
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
    
    /// returns future result with URL on downloaded filed
    /// - Parameter downloadPath: file download link path
    /// - Parameter saveFilePath: destination file path
    @available(*, deprecated, message: "Not work for me. Downloaded file always empty | https://github.com/IBM-Swift/SwiftyRequest/issues/75")
    func downloadLocalization(downloadPath: String,
                              saveFilePath: String) -> EventLoopFuture<URL> {
        // create promise to return future result
        let promise = eventLoop.next().makePromise(of: URL.self)
        let saveFileURL = URL(fileURLWithPath: saveFilePath.absolutePath)

        // create request
        let request = RestRequest(method: .get, url: downloadPath)
        request.download(to: saveFileURL) { result in
            switch result {
            case .success:
                promise.succeed(saveFileURL)
            case .failure(let error):
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
    
    /// returns future result with Data of downloaded filed
    /// - Parameter downloadPath: file download link path
    func downloadLocalization(downloadPath: String) -> EventLoopFuture<Data> {
        // create promise to return future result
        let promise = eventLoop.next().makePromise(of: Data.self)
        
        // create request
        let request = RestRequest(method: .get, url: downloadPath)
        request.responseData(completionHandler: { response in
            switch response {
            case .success(let result):
                let data = result.body
                promise.succeed(data)
            case .failure(let error):
                promise.fail(error)
            }
        })
        
        return promise.futureResult
    }
    
    // MARK: - Private methods
    
    /// json decoder wrapper
    /// - Parameter type: structure to decode
    /// - Parameter data: body data
    private func decode<PayloadType: Codable>(to type: PayloadType.Type, data: Data) throws -> PayloadType {
        let object = try decoder.decode(PayloadType.self, from: data)
        return object
    }
    
    /// json encoder wrapper
    /// - Parameter value: structure to encode
    private func encode<Payload: Codable>(value: Payload) throws -> String {
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw PoeditorError.unableToGetJSONString
        }
        
        return string
    }
    
    /// shutdown eventloop and all active resources
    private func shutDown() {
        do {
            try self.eventLoop.syncShutdownGracefully()
        } catch {
            print(error)
        }
    }
}
