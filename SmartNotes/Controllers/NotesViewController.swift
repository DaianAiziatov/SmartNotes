//
//  NotesViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 14/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit
import CoreData

enum Order {
    case ascByDate
    case ascByTitle
    case descByDate
    case descByTitle
}

class NotesViewController: UIViewController, AlertDisplayable {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var notesCounterItem: UIBarButtonItem!
    private var notes = [Note]()
    private var filteredNotes = [Note]()
    private let searchController = UISearchController(searchResultsController: nil)
    private var sortOrder: Order = .descByDate

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = #colorLiteral(red: 0.9022161365, green: 0.7540545464, blue: 0.162062794, alpha: 1)
        definesPresentationContext = true
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        let orderButton = UIBarButtonItem(image: UIImage(named: "order_icon"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(orderList(sender:)))
        navigationItem.rightBarButtonItem = orderButton
    }

    // Load the notes from Core Data
    func loadNotes() {
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        do {
            notes = try context.fetch(fetchRequest)
            notes.sort(by: {$0.date! > $1.date!})
            notesCounterItem.title = notes.count == 1 ? "1 Note" : "\(notes.count) Notes"
            self.tableView.separatorStyle = notes.isEmpty ? .none : .singleLine
            self.tableView.reloadData()
        } catch (let error) {
            print("[NotesViewController] \(#function): Cannot fetch from database. Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNote" || segue.identifier == "createNote"{
            if let destination = segue.destination as? ShowNoteViewController {
                if let selectedRow = tableView.indexPathForSelectedRow?.row {
                    if searchController.isActive == true && searchController.searchBar.text != "" {
                        destination.note = filteredNotes[selectedRow]
                    } else {
                        destination.note = notes[selectedRow]
                    }

                }
            }
        }
    }

    @objc
    private func orderList(sender: UIBarButtonItem) {
        let ascByTitle = UIAlertAction(title: "Order ASC by title", style: .default, handler: orderASCbyTitle(action:))
        let descByTitle = UIAlertAction(title: "Order DESC by title", style: .default, handler: orderDESCbyTitle(action:))
        let ascByDate = UIAlertAction(title: "Order ASC by date", style: .default, handler: orderASCbyDate(action:))
        let descByDate = UIAlertAction(title: "Order DESC by date", style: .default, handler: orderDESCbyDate(action:))
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        displayAlert(with: nil, message: nil, actions: [ascByTitle, descByTitle, ascByDate, descByDate, cancel], style: .actionSheet)
    }

    private func orderASCbyTitle(action: UIAlertAction) -> Void {
        sortOrder = .ascByTitle
        notes.sort(by: {($0.details as! NSAttributedString).string < ($1.details as! NSAttributedString).string})
        tableView.reloadData()
    }

    private func orderDESCbyTitle(action: UIAlertAction) -> Void {
        sortOrder = .descByTitle
        notes.sort(by: {($0.details as! NSAttributedString).string > ($1.details as! NSAttributedString).string})
        tableView.reloadData()
    }

    private func orderASCbyDate(action: UIAlertAction) -> Void {
        sortOrder = .ascByDate
        notes.sort(by: {$0.date! < $1.date!})
        tableView.reloadData()
    }

    private func orderDESCbyDate(action: UIAlertAction) -> Void {
        sortOrder = .descByDate
        notes.sort(by: {$0.date! > $1.date!})
        tableView.reloadData()
    }

}

// MARK: - UITableView Delegate
extension NotesViewController: UITableViewDelegate {

}

// MARK: - UITableView Data Source
extension NotesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive == true && searchController.searchBar.text != "" {
            return filteredNotes.count
        }
        return notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath) as! NoteTableViewCell
        if searchController.isActive == true && searchController.searchBar.text != "" {
            cell.configure(with: filteredNotes[indexPath.row])
        } else {
            cell.configure(with: notes[indexPath.row])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let confirm = UIAlertAction(title: "Confirm", style: .default, handler: ({ action in
                context.delete(self.notes[indexPath.row])
                self.loadNotes()
            }))
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            displayAlert(with: "Are you sure to delete this note?", message: "This action can't be undone", actions: [confirm, cancel])
        }
    }
}

// MARK: - Search Bar delegate
extension NotesViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchString = searchController.searchBar.text
        filteredNotes = notes.filter({ (item) -> Bool in
            // TODO: - remove forcecasting
            let description: NSString? = item.details as! NSString?
            let filteredResults = (description!.range(of: searchString!, options: .caseInsensitive).location != NSNotFound)
            return filteredResults
        })
        self.tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.text = ""
        self.tableView.reloadData()
    }

}
