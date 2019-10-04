//
//  PeopleTableViewController.swift
//  Random Users
//
//  Created by Joshua Sharp on 10/4/19.
//  Copyright © 2019 Erica Sadun. All rights reserved.
//

import UIKit

class PeopleTableViewController: UITableViewController {

    var personController = PersonController()
    private let cache = Cache<String, Data>()
    private let photoFetchQueue = OperationQueue()
    private var operations = [String : Operation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        personController.fetchPeople { error in
            if let error = error {
                NSLog ("PTVC: Error fetching people: \(error)")
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return personController.people.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell", for: indexPath) as? PeopleTableViewCell else {return UITableViewCell()}

        // Configure the cell...
        print ("Setting up cell for row \(indexPath.row) with \(personController.people[indexPath.row])")
        cell.person = personController.people[indexPath.row]
        loadImage(forCell: cell, forItemAt: indexPath)
        return cell
    }
    
    private func loadImage(forCell cell: UITableViewCell, forItemAt indexPath: IndexPath) {
        
        let photoReference = personController.people[indexPath.row].picture
        
        // Check if there is cached data
        if let cachedData = cache.value(key: photoReference.thumbnail),
            let image = UIImage(data: cachedData) {
            cell.imageView?.image = image
            return
        }
        
        // Start our fetch operations
        let fetchOp = FetchPhotoOperation(photoReference: photoReference)
        
        let cacheOp = BlockOperation {
            if let data = fetchOp.imageData {
                self.cache.cache(key: photoReference.thumbnail, value: data)
            }
        }
        
        let completionOp = BlockOperation {
            defer { self.operations.removeValue(forKey: photoReference.thumbnail) }
            if let currentIndexPath = self.tableView.indexPath(for: cell),
                currentIndexPath != indexPath {
                print("Got image for reused cell")
                return
            }
            if let data = fetchOp.imageData {
                cell.imageView?.image = UIImage(data: data)
            }
        }
        
        cacheOp.addDependency(fetchOp)
        completionOp.addDependency(fetchOp)
        
        photoFetchQueue.addOperation(fetchOp)
        photoFetchQueue.addOperation(cacheOp)
        OperationQueue.main.addOperation(completionOp)
        
        operations[photoReference.thumbnail] = fetchOp
        
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}