//
//  QuoterAPI.swift
//  Quote
//
//  Created by Доктор Кларик on 02/08/2018.
//  Copyright © 2018 Доктор Кларик. All rights reserved.
//

import Foundation
import UIKit

class Quote: NSObject {
    
    init(_ _id: Int, _ _author: String, _ _adder: String, _ _text: String) {
        self.id = _id
        self.author = _author
        self.adder = _adder
        self.text = _text
    }
    
    var id: Int = 0
    var author: String = ""
    var adder: String = ""
    var text: String = ""
    
    static let EMPTY_QUOTE = Quote(-1, "[Invalid]", "[Invalid]", "[Invalid]")
}

class QuoterAPI {
    
    var totalCount: Int = -1
    var currentQuote: Quote = Quote.EMPTY_QUOTE
    var isInitialized = false
    
    func hasQuote() -> Bool {
        return currentQuote == Quote.EMPTY_QUOTE
    }
    
    func isReady() -> Bool {
        return totalCount > 0 && isInitialized
    }
    
    func canPrevious() -> Bool {
        return currentQuote.id > 1
    }
    
    func canNext() -> Bool {
        return currentQuote.id < totalCount
    }
    
    func formatParams(_ params: [String: String]) -> String {
        var args: [String] = []
        for (key, value) in params {
            args.append("\(key)=\(value)")
        }
        return args.joined(separator: "&")
    }
    
    func initializeContext(_ onLoad: @escaping () -> Void, _ onError: @escaping () -> Void) {
        req(params: ["task":"GET", "mode": "total"], onLoad: { json in
            print("Response from initialization \(json)")
            if let rError = json["error"] as? Bool {
                if !rError {
                    if let data = json["data"] as? [String: Int] {
                        self.totalCount = data["count"]!
                        self.isInitialized = true
                        return onLoad()
                    }
                }
            }
            onError()
        }) { _ in
            onError()
        }
    }
    
    func loadRandomQuote(onLoad: @escaping (Quote) -> Void, onError: @escaping ([String: Any]?, String?) -> Void) {
        print("Loading random quote")
        req(params: ["task": "GET", "mode": "rand"], onLoad: { json in
            print("Response from requesting random quote: \n\(json)")
            if let data: [String: Any] = json["data"] as? [String: Any] {
                onLoad(self.createQuote(data))
            }else {
                onError(json, nil)
            }
        }, onError: {error in
            onError(nil, error?.localizedDescription ?? "Error")
        })
    }
    
    func loadQuoteByID(_ id: Int, onLoad: @escaping (Quote) -> Void, onError: @escaping ([String: Any]?, String?) -> Void) {
        print("Loading \(id) quote")
        req(params: ["task": "GET", "mode": "pos", "pos": String(id)], onLoad: { json in
            print("Response from requesting quote by id(\(id): \n\(json)")
            if let data: [String: Any] = json["data"] as? [String: Any] {
                onLoad(self.createQuote(data))
            }else {
                onError(json, nil)
            }
        }, onError: { error in
            onError(nil, error?.localizedDescription ?? "Error")
        })
    }
    
    func createQuote(_ data: [String: Any]) -> Quote {
        let quote = Quote.EMPTY_QUOTE
        if let text = data["quote"] as? String {
            quote.text = text
        }
        if let author = data["author"] as? String {
            quote.author = author
        }
        if let adder = data["adder"] as? String {
            quote.adder = adder
        }
        if let id = data["id"] as? Int {
            quote.id = id
        }
        return quote
    }
    
    private func req(params parameters: [String: String], onLoad: @escaping ([String: Any]) -> Void, onError: @escaping (Optional<Error>) -> Void) {
        let url = URL(string: "http://52.48.142.75:8888/backend/quoter")!
        let session = URLSession.shared
        let args = formatParams(parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = args.data(using: .utf8)
        print("Requesting \(url)?\(args)")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    onLoad(json)
                }else{
                    onError(Optional<Error>.none)
                }
            } catch let error {
                onError(error)
            }
        })
        task.resume()
    }
}

