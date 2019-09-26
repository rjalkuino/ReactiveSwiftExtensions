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


class MovieApiService {
    public static let shared = MovieApiService()
    private init() {}
    private let urlSession = URLSession.shared
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!
    private let apiKey = "68f89d22c89a7252a422f0295a4d6ca3"
    
    private let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return jsonDecoder
    }()
    
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
    
    public enum APIServiceError: Error {
        case apiError
        case invalidEndpoint
        case invalidResponse
        case noData
        case decodeError
    }
    private func fetchResources<T: Decodable>(url: URL) -> SignalProducer<(Result<T, APIServiceError>),Never> {
        return SignalProducer { [weak self] sink,disposable in
            guard let strongSelf = self else { return }
            
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                sink.send(value: .failure(.invalidEndpoint))
                return
            }
            
            let queryItems = [URLQueryItem(name: "api_key", value: strongSelf.apiKey)]
            urlComponents.queryItems = queryItems
            guard let url = urlComponents.url else {
                sink.send(value: .failure(.invalidEndpoint))
                return
            }
            
            strongSelf.urlSession.dataTask(with: url) { (data,response,error) in
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200..<299 ~= statusCode else {
                    sink.send(value: .failure(.invalidEndpoint))
                    return
                }
                guard let data = data else { return }
                
                do {
                    let values = try strongSelf.jsonDecoder.decode(T.self, from: data)
                    sink.send(value: .success(values))
                } catch {
                    sink.send(value: .failure(.decodeError))
                }
                }.resume()
        }
    }
    
    private func fetchResources<T: Decodable>(url: URL, completion: @escaping (Result<T, APIServiceError>) -> Void) {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        let queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            completion(.failure(.invalidEndpoint))
            return
        }
        urlSession.dataTask(with: url) { (data,response,error) in
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, 200..<299 ~= statusCode else {
                completion(.failure(.invalidResponse))
                return
            }
            guard let data = data else { return }
            
            do {
                let values = try self.jsonDecoder.decode(T.self, from: data)
                completion(.success(values))
            } catch {
                completion(.failure(.decodeError))
            }
            }.resume()
    }
    
    public func fetchMovies(from endpoint: Endpoint,
                            result: @escaping (Result<MoviesResponse, APIServiceError>) -> Void) {
        let movieURL = baseURL
            .appendingPathComponent("movie")
            .appendingPathComponent(endpoint.description)
        fetchResources(url: movieURL, completion: result)
    }
    
    public func fetchMovieDetail(movieId: String,
                                 result: @escaping (Result<MoviesResponse, APIServiceError>) -> Void) {
        let movieURL = baseURL
            .appendingPathComponent("movie")
            .appendingPathComponent(movieId)
        fetchResources(url: movieURL, completion: result)
    }
    
    public func getImage(from url: URL) -> SignalProducer<Data,Error>{
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
