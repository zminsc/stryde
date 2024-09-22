//
//  PlaylistsTableViewController.swift
//  Stryde
//
//  Created by Shruti Agarwal on 9/21/24.
//

import UIKit

class PlaylistsTableViewController: UITableViewController {

    var playlists: [(name: String, id: String, imageURL: String?)] = [] // This will hold the playlist data
    
    // Delegate to communicate with the parent ViewController
    weak var delegate: PlaylistSelectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Register a basic UITableViewCell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - Table view data source methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let playlist = playlists[indexPath.row]
        cell.textLabel?.text = playlist.name
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18) // Set larger and bold text
        cell.textLabel?.numberOfLines = 1
        cell.textLabel?.adjustsFontSizeToFitWidth = true // Ensure text fits within cell width
        
        
        if let imageURL = playlist.imageURL, let url = URL(string: imageURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        cell.imageView?.image = UIImage(data: data)
                        cell.imageView?.layer.cornerRadius = 10 // Apply rounded corners
                        cell.imageView?.clipsToBounds = true    // Ensure corners are clipped
                                            
                        let itemSize = CGSize(width: 100, height: 100) // Set larger image size
                        UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0)
                        let imageRect = CGRect(origin: CGPoint.zero, size: itemSize)
                        cell.imageView?.image?.draw(in: imageRect)
                        cell.imageView?.image = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        
                        
                        
                        cell.setNeedsLayout() // Update the cell's layout to reflect the new image
                    }
                }
            }
        } else {
            cell.imageView?.image = UIImage(systemName: "photo") // Placeholder image
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120 // Increase the row height for better spacing between cells
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add padding between cells by setting margins
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.borderWidth = 0 // Set to 0 to avoid showing borders
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        
        // Add padding around the cell content
        cell.contentView.frame = cell.contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15))
    }

    // MARK: - Table view delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlaylist = playlists[indexPath.row]
        // Notify the delegate (ViewController) about the selection
        delegate?.didSelectPlaylist(selectedPlaylist.id)
        dismiss(animated: true, completion: nil)
    }

}
