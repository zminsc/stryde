from flask import Flask, request, jsonify
import numpy as np
import scipy
import matplotlib.pyplot as plt

app = Flask(__name__)

@app.route("/")
def hello():
    print("hello")
    return "Hello World!"

def get_steps_per_min(imu_data, freq):
    """
    Get the steps per min given imu data
    Assuming imu_data has shape (N, 3)
    """

    # Iterate through all three axes to find the clearest signal
    max_peak = -100
    peak_freq = 0
    for i in range(3):
        freq_domain = np.abs(np.fft.rfft(imu_data[:, i], len(imu_data[:, i])))[1:]
        x_freq = np.fft.rfftfreq(len(imu_data[:, i]), 1/freq)[1:]

        start_ind = np.argmax(x_freq > 0.9)
        end_ind = np.argmin(x_freq < 1.8)
        interest_freqs = x_freq[start_ind-1: end_ind+1]
        interest_abs = freq_domain[start_ind-1:end_ind+1]

        peak_mag = np.max(interest_abs)
        if peak_mag > max_peak:
            max_peak = peak_mag
            peak_freq = interest_freqs[np.argmax(interest_abs)]
    
    # Calculate steps per minute given peak_freq
    steps_per_min = peak_freq * 2 * 60
    return steps_per_min

@app.route("/process_data", methods=["POST"])
def process_data():
    data = request.get_json()
    imu_data = np.array(data)
    
    steps_per_min = get_steps_per_min(imu_data, freq=100)

    steps_per_min = round(steps_per_min, -1)
    print(steps_per_min)
    return jsonify([steps_per_min]), 200


app.run(host="0.0.0.0", debug=True)