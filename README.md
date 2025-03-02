# stryde

Honorable mention for Most Creative Hack at [PennApps XXIV](https://2024f.pennapps.com/).

Research has demonstrated that music when synchronized with a person's running cadence can provide enhanced psychological and psychophysical benefits during running. As a group of runners, we thought it would be very useful to have an app that would pick up music that matched the current pace of our strides, in order to motivate us to push through our runs. We took this hackathon as an opportunity to explore this interesting idea.

Our system leverages the smart devices that people wear/possess while running to measure their running cadence. Once we process and clean these metrics, we wire them to a mobile application. This app links the user's Spotify account with our system and allows the user to pick between their various playlists (ideally with songs that vary in tempo!) that they want to listen to on their run. Then, once the user starts running, the application plays songs that matches the user's running tempo in real time.

## Demo

[![Stryde Demo Video](https://img.youtube.com/vi/3voHB-i6Xtw/0.jpg)](https://www.youtube.com/watch?v=3voHB-i6Xtw)

## How We Built Stryde

We decided to leverage the IMU sensor on the iPhone to measure the user's cadence. We leverage the fact that many people run with either their phone or their Apple Watch to track their workouts, and both of these devices have IMU sensors that we can access. Although the current system is built for the iPhone, adding watch support should be relatively straightforward. We use a python backend server to process the raw signal data received from the IMU and compute the user's running cadence using Fourier transforms. On the mobile app, we use the [Spotify API](https://developer.spotify.com/documentation/web-api) to access the user's playlists, find the tempo of the songs, and play songs that match the user's running pace in real time. Our app frontend is developed using [UIKit](https://developer.apple.com/documentation/uikit/). We also leveraged the [Cerebras AI API](http://cerebras.ai) to allow users the option to play music via an unstructured chat request (i.e. "I want to feel positive on this run!"), rather than select playlists on their own.

## Running the App (Development)

First start by initializing the backend server by running `cd backend`, and then `python app.py`. Note down the ip address that the server is running on and put that value in the correct locations in `Stryde/APICalls.swift`.

Afterwards, open up `Stryde.xcodeproj` in XCode. Connect your iOS device running iOS 17. You can then build the project and open the app. Make sure to allow connections to local network devices when prompted!
