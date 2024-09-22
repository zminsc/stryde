//
//  MotionViewModel.swift
//  Stryde
//
//  Created by George Xue on 9/20/24.
//

import Foundation
import CoreMotion

class Accel{
    let motion = CMMotionManager()
    var timer: Timer?
    @Published var accelerometerData: [[Double]] = []
    @Published var apiData: String = "No data yet"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Don't post the first one
    var first = true
    
    @Published var tempo = 0;
    var lastTempo = 0;
    
    func startAccelerometers() {
        print("here in startAccelerometers")
        
        // Make sure the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 1.0 / 100.0  // 100 Hz
            self.motion.startAccelerometerUpdates()
            
            
            // Configure a timer to fetch the data.
            self.timer = Timer(fire: Date(), interval: (1.0/100.0),
                               repeats: true, block: { (timer) in
                // Get the accelerometer data.
                if let data = self.motion.accelerometerData {
                    DispatchQueue.main.async {
                        self.accelerometerData.append([data.acceleration.x,
                                                       data.acceleration.y,
                                                       data.acceleration.z])
                    }
                }
            })
            
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer!, forMode: .default)

        }
    }
    
    func startTracking() {
        stopTracking()
        startAccelerometers()
        self.timer = Timer.scheduledTimer(timeInterval: 6.0,
                                          target: self,
                                          selector: #selector(postData),
                                          userInfo: nil,
                                          repeats: true)
        
        print("Timer Started")
        
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        self.motion.stopAccelerometerUpdates()
        print("Tracking stopped")
    }
    
    
    // API call function
    func fetchDataFromAPI() {
        isLoading = true
        errorMessage = nil
        
        APICalls.instance.fetchData { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let data):
                    self.apiData = String(data: data, encoding: .utf8) ?? "Invalid data"
                    print(self.apiData)
                case .failure(let error):
                    self.errorMessage = error.rawValue
                }
            }
        }
    }
    
    func setTempo(inputTempo: Int) {
        if (inputTempo == lastTempo || lastTempo == 0) {
            self.tempo = inputTempo
        }
        lastTempo = inputTempo
        print(inputTempo)
    }
    
    @objc func postData() {
        if self.first {
            print("POST but first")
            self.first = false
        } else {
            print("POST data")
            APICalls.instance.postData(accelerometerData: self.accelerometerData, setTempo: setTempo)
            
            let middleInd = self.accelerometerData.count / 2
            self.accelerometerData = self.accelerometerData.suffix(middleInd)
        }
    }
}
