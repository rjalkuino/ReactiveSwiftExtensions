//
//  APIServices.swift
//  TestProject
//
//  Created by robert john alkuino on 25/09/2019.
//  Copyright © 2019 robert john alkuino. All rights reserved.
//

import UIKit
import ReactiveSwift

public struct MoviesResponse: Codable {
    
    public let page: Int
    public let totalResults: Int
    public let totalPages: Int
    public let results: [Movie]
}

public enum APIServiceError: Error {
    case apiError
    case invalidEndpoint
    case invalidResponse
    case noData
    case decodeError
}

class APIService<T:Decodable> {
    private init() {}
    private static var urlSession:URLSession {
        return URLSession.shared
    }
    private static var baseURL:URL {
        return URL(string: "https://api.themoviedb.org/3")!
    }
    private static var apiKey:String {
        return "68f89d22c89a7252a422f0295a4d6ca3"
    }
    
    private static var jsonDecoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return jsonDecoder
    }
    
    enum Endpoint: String, CustomStringConvertible, CaseIterable {
        case topRated
        case movieDetail
        
        var description: String {
            switch self {
            case .topRated:
                return "top_rated"
            case .movieDetail:
                return ""
            }
        }
    }
    
    private static func fetchResources(url: URL) -> SignalProducer<(Result<T, APIServiceError>),Never> {
        return SignalProducer { sink,disposable in
            
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                sink.send(value: .failure(.invalidEndpoint))
                return
            }
            
            let queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
            urlComponents.queryItems = queryItems
            guard let url = urlComponents.url else {
                sink.send(value: .failure(.invalidEndpoint))
                return
            }
            
            urlSession.dataTask(with: url) { (data,response,error) in
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200..<299 ~= statusCode else {
                    sink.send(value: .failure(.invalidEndpoint))
                    return
                }
                guard let data = data else { return }
                
                do {
                    let values = try jsonDecoder.decode(T.self, from: data)
                    sink.send(value: .success(values))
                } catch {
                    sink.send(value: .failure(.decodeError))
                }
                }.resume()
        }
    }
    
    public static func fetchMovies(from endpoint: Endpoint) -> SignalProducer<(Result<T, APIServiceError>),Never> {
        let movieURL = baseURL
            .appendingPathComponent("movie")
            .appendingPathComponent(endpoint.description)
        
        return fetchResources(url: movieURL)
    }
    
    public static func fetchMovieDetail(movieId: String) -> SignalProducer<(Result<T, APIServiceError>),Never> {
        let movieURL = baseURL
            .appendingPathComponent("movie")
            .appendingPathComponent(movieId)
        
        return fetchResources(url: movieURL)
    }
    
    public static func getImage(from url: URL) -> SignalProducer<Data,Error>{
        return SignalProducer{ sink, disposable in
            URLSession.shared.dataTask(with: url, completionHandler: { (data,response,error) in
                if let error = error {
                    sink.send(error: error)
                }
                if let data = data {
                    sink.send(value: data)
                }
            }).resume()
        }
        
    }
}
