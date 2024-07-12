//
//  TableViewDelegate.swift
//  ParkingFinder
//
//  Created by Rishabh Changwani on 7/1/24.
//

import Foundation
import UIKit

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    // UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let searchResult = searchResults[indexPath.row]
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }

    // UITableViewDelegate methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let searchResult = searchResults[indexPath.row]
        searchBar.text = searchResult.title
        tableView.isHidden = true
        performSearch(for: searchResult)
    }
}
