//
//  Poeditor.swift
//  SwiftyPoeditor
//
//  Created by Oleksandr Vitruk on 9/29/19.
//

import Foundation
import NIO
import AsyncHTTPClient

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
    
    // MARK: - Private properties
    
    private let settings: PoeditorSettings
    private let client: HTTPClient
    
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
        self.client = HTTPClient(eventLoopGroupProvider: .shared(eventLoop))
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

        do {
            // create request
            var request = try HTTPClient.Request(url: urlPath, method: .POST)
            request.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
            request.body = .string(bodyString)
            
            client.execute(request: request).whenComplete({ [weak self] response in
                switch response {
                case .success(let result):
                    guard result.status == .ok,
                        let body = result.body,
                        let decoder = self?.decoder else {
                        return promise.fail(PoeditorError.wrongResponse)
                    }
                    
                    do {
                        let decodedResult = try body.getJSONDecodable(PoeditorResult<Terms>.self,
                                                                      decoder: decoder, at: body.readerIndex, length: body.readableBytes)
                        // try to decode data to expected objects
                        guard let model = decodedResult?.result else {
                            return promise.fail(PoeditorError.wrongResponse)
                        }
                        
                        promise.succeed(model)
                    } catch {
                        promise.fail(error)
                    }
                case .failure(let error):
                    promise.fail(error)
                }
            })
        } catch {
            promise.fail(error)
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
    
        do {
            // create request
            var request = try HTTPClient.Request(url: urlPath, method: .POST)
            request.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
            request.body = .string(bodyString)
            
            client.execute(request: request).whenComplete({ [weak self] response in
                switch response {
                case .success(let result):
                    guard result.status == .ok,
                        let body = result.body,
                        let decoder = self?.decoder else {
                        return promise.fail(PoeditorError.wrongResponse)
                    }
                    
                    do {
                        let decodedResult = try body.getJSONDecodable(PoeditorResult<DeletedTerms>.self,
                                                                      decoder: decoder, at: body.readerIndex, length: body.readableBytes)
                        // try to decode data to expected objects
                        guard let model = decodedResult?.result?.terms else {
                            return promise.fail(PoeditorError.wrongResponse)
                        }
                        
                        promise.succeed(model)
                    } catch {
                        promise.fail(error)
                    }
                case .failure(let error):
                    promise.fail(error)
                }
            })
        } catch {
            promise.fail(error)
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
        
        do {
            // create request
            var request = try HTTPClient.Request(url: urlPath, method: .POST)
            request.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
            request.body = .string(bodyString)
            
            client.execute(request: request).whenComplete({ [weak self] response in
                switch response {
                case .success(let result):
                    guard result.status == .ok,
                        let body = result.body,
                        let decoder = self?.decoder else {
                        return promise.fail(PoeditorError.wrongResponse)
                    }
                    
                    do {
                        let decodedResult = try body.getJSONDecodable(PoeditorResult<AddedTerms>.self,
                                                                      decoder: decoder, at: body.readerIndex, length: body.readableBytes)
                        // try to decode data to expected objects
                        guard let model = decodedResult?.result?.terms else {
                            return promise.fail(PoeditorError.wrongResponse)
                        }
                        
                        promise.succeed(model)
                    } catch {
                        promise.fail(error)
                    }
                case .failure(let error):
                    promise.fail(error)
                }
            })
        } catch {
            promise.fail(error)
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
        
        do {
            // create request
            var request = try HTTPClient.Request(url: urlPath, method: .POST)
            request.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
            request.body = .string(bodyString)
            
            client.execute(request: request).whenComplete({ [weak self] response in
                switch response {
                case .success(let result):
                    guard result.status == .ok,
                        let body = result.body,
                        let decoder = self?.decoder else {
                        return promise.fail(PoeditorError.wrongResponse)
                    }
                    
                    do {
                        let decodedResult = try body.getJSONDecodable(PoeditorResult<ExportRequestResult>.self,
                                                                      decoder: decoder, at: body.readerIndex, length: body.readableBytes)
                        // try to decode data to expected objects
                        guard let model = decodedResult?.result else {
                            return promise.fail(PoeditorError.wrongResponse)
                        }
                        
                        promise.succeed(model)
                    } catch {
                        promise.fail(error)
                    }
                case .failure(let error):
                    promise.fail(error)
                }
            })
        } catch {
            promise.fail(error)
        }
        
        return promise.futureResult
    }
    
    /// returns future result with Data of downloaded filed
    /// - Parameter downloadPath: file download link path
    func downloadLocalization(downloadPath: String) -> EventLoopFuture<Data> {
        // create promise to return future result
        let promise = eventLoop.next().makePromise(of: Data.self)
        
        // create request
        do {
            // create request
            let request = try HTTPClient.Request(url: downloadPath, method: .GET)
            
            client.execute(request: request).whenComplete({ response in
                switch response {
                case .success(let result):
                    guard result.status == .ok,
                        let body = result.body,
                        let data = body.getData(at: body.readerIndex, length: body.readableBytes) else {
                        promise.fail(PoeditorError.wrongResponse)
                        return
                    }
                    
                    promise.succeed(data)
                case .failure(let error):
                    promise.fail(error)
                }
            })
        } catch {
            promise.fail(error)
        }
        
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
            try self.client.syncShutdown()
            try self.eventLoop.syncShutdownGracefully()
        } catch {
            print(error)
        }
    }
}
