//
//  PlaylistSelectionViewController.swift
//  Stryde
//
//  Created by Shruti Agarwal on 9/21/24.
//


class PlaylistSelectionViewController: UITableViewController {
    var playlists: [String: String] = [:]
    var accessToken: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch user playlists
        fetchUserPlaylists(accessToken: accessToken) { [weak self] playlists, error in
            if let playlists = playlists {
                self?.playlists = playlists
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            } else {
                print("Error fetching playlists: \(String(describing: error))")
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let playlistName = Array(playlists.keys)[indexPath.row]
        cell.textLabel?.text = playlistName
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playlistName = Array(playlists.keys)[indexPath.row]
        if let playlistId = playlists[playlistName] {
            // Call the method to fetch tracks from the selected playlist
            fetchTracksFromPlaylist(playlistId: playlistId)
        }
    }

    func fetchTracksFromPlaylist(playlistId: String) {
        let urlString = "https://api.spotify.com/v1/playlists/\(playlistId)/tracks"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching tracks: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    var trackURIs: [String] = []
                    for item in items {
                        if let track = item["track"] as? [String: Any],
                           let uri = track["uri"] as? String {
                            trackURIs.append(uri)
                        }
                    }
                    // Pass track URIs for further processing
                    DispatchQueue.main.async {
                        self.processTrackURIs(trackURIs)
                    }
                }
            } catch {
                print("Error parsing track data: \(error)")
            }
        }
        task.resume()
    }

    func processTrackURIs(_ uris: [String]) {
        // Example: Fetch audio features for these URIs
        fetchAndSortTracksByTempo(uris: uris)
    }
    
    func fetchAndSortTracksByTempo(uris: [String]) {
        let dispatchGroup = DispatchGroup()
        
        var tempDict: [Double: String] = [:]
        
        for uri in uris {
            dispatchGroup.enter()
            let trackId = uri.replacingOccurrences(of: "spotify:track:", with: "")
            fetchAudioFeatures(for: trackId) { audioFeatures, error in
                if let error = error {
                    print("Error fetching audio features for URI \(uri): \(error.localizedDescription)")
                } else if let audioFeatures = audioFeatures, let tempo = audioFeatures["tempo"] as? Double {
                    tempDict[tempo] = uri
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Sort the dictionary by tempo and store it in the class property
            self.tempoTrackDictionary = tempDict.sorted(by: { $0.key < $1.key }).reduce(into: [:]) { $0[$1.key] = $1.value }
            print("Sorted tempo track dictionary: \(self.tempoTrackDictionary)")
        }
    }

}
