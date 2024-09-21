//
//  APICalls.swift
//  Stryde
//
//  Created by George Xue on 9/20/24.
//

import Foundation

enum APIError: String, Error {
    case networkError
    case invalidURL
    case decodingError
}

class APICalls {
    static let instance = APICalls()
    
    func fetchData(completion: @escaping (Result<Data, APIError>) -> Void) {
            // Ensure the URL is valid
            guard let url = URL(string: "http://10.103.151.132:5000") else {
                completion(.failure(.invalidURL))
                return
            }
            
            // Create a data task
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                // Check for networking error
                if let _ = error {
                    completion(.failure(.networkError))
                    return
                }
                
                // Ensure we have data
                guard let data = data else {
                    completion(.failure(.networkError))
                    return
                }
                
                // Success case: return the data
                completion(.success(data))
            }
            
            // Start the task
            task.resume()
        }
    
    func postData(accelerometerData: [[Double]], setTempo: @escaping (Int) -> Void) {
        let Url = String(format: "http://10.103.151.132:5000/process_data")
        guard let serviceUrl = URL(string: Url) else { return }
        let parameters: [[Double]] = accelerometerData
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return
        }
        request.httpBody = httpBody
        request.timeoutInterval = 50
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let response_arr = json as? [Int] else {return}
                    setTempo(response_arr[0])
                } catch {
                    print(error)
                }
            }
        }.resume()
    }



}
