//
//  Llmcalls.swift
//  Stryde
//
//  Created by Freddy Liu on 9/22/24.
//

import Foundation

class LLMCalls {
    
    let apikey = "Bearer csk-e3cr39y63ftf4feme25revy69tky944wtkrcnk8wcmhhdpw9"
    
    func sendMessage(message: String, getMessage: @escaping (String) -> Void) {
        // Define URL and parameters
        let url = URL(string: "https://api.cerebras.ai/v1/chat/completions")!
        var request = URLRequest(url: url)
        
        // Set the HTTP method
        request.httpMethod = "POST"
        
        // Set the headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apikey, forHTTPHeaderField: "Authorization")
        
        // Create your JSON body
        let parameters: [String: Any] = [
            "model": "llama3.1-8b",
            "stream": false,
            "messages": [["content": message, "role": "user"]],
            "temperature": 0,
            "max_tokens": -1,
            "seed": 0,
            "top_p": 1
        ]
        
        do {
            // Convert the parameters to JSON data
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
        }
        
        // Create the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle the response
            if let error = error {
                print("Error making API call: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error: \(response!)")
                return
            }
            
            if let data = data {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let messageContent = firstChoice["message"] as? [String: Any],
                       let content = messageContent["content"] as? String {
                        
                        // Print and pass the message content
                        print("Message content: \(content)")
                        getMessage(content)
                    } else {
                        print("Failed to parse the response")
                    }
                    
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }
        
        // Start the API call
        task.resume()
    }
    
}
