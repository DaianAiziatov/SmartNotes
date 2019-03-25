//
//  NotesViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 14/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit
import CoreData

class NotesViewController: UIViewController, AlertDisplayable, LoadingDisplayable {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var notesCounterItem: UIBarButtonItem!
    private var notes = [Note]()
    private var filteredNotes = [Note]()
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()
        if let _ = FirebaseManager.shared.getUser() {
            let syncButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
            navigationItem.rightBarButtonItem = syncButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.showsBookmarkButton = true
        searchController.searchBar.tintColor = #colorLiteral(red: 0.9022161365, green: 0.7540545464, blue: 0.162062794, alpha: 1)
        searchController.searchBar.setImage(UIImage(named: "order_icon"), for: .bookmark, state: .normal)
        definesPresentationContext = true
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true


    }

    @IBAction func profileTapped(_ sender: UIBarButtonItem) {
        if let _ = FirebaseManager.shared.getUser() {
            self.performSegue(withIdentifier: "showProfile", sender: self)
        } else {
            self.performSegue(withIdentifier: "showLogin", sender: self)
        }
    }
    // Load the notes from Core Data
    func loadNotes() {
        if let notes = DataManager.loadNotes() {
            self.notes = notes
            notesCounterItem.title = notes.count == 1 ? "1 Note" : "\(notes.count) Notes"
            self.tableView.separatorStyle = notes.isEmpty ? .none : .singleLine
            self.tableView.reloadData()
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

    @objc
    private func refresh() {
        self.startLoading()
        SyncManager.sync { error in
            if let error = error {
                print("[\(#function)] Error: \(error.localizedDescription)")
                self.stopLoading {
                    self.displayAlert(with: "Error", message: "Some error occured while refreshing. Try again later.")
                }
            } else {
                self.stopLoading {
                    self.loadNotes()
                }
            }
        }

    }

    private func orderASCbyTitle(action: UIAlertAction) -> Void {
        notes.sort(by: { $0.details! < $1.details! })
        tableView.reloadData()
    }

    private func orderDESCbyTitle(action: UIAlertAction) -> Void {
        notes.sort(by: { $0.details! > $1.details! })
        tableView.reloadData()
    }

    private func orderASCbyDate(action: UIAlertAction) -> Void {
        notes.sort(by: {$0.date! < $1.date!})
        tableView.reloadData()
    }

    private func orderDESCbyDate(action: UIAlertAction) -> Void {
        notes.sort(by: {$0.date! > $1.date!})
        tableView.reloadData()
    }

}

// MARK: - UITableView Delegate
extension NotesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("SELECTED NOTE WITH ID: \(notes[indexPath.row].id!)")
    }
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
            let confirm = UIAlertAction(title: "Confirm", style: .default, handler: ({ [unowned self] action in
                let note = self.notes[indexPath.row]
                if let _ = FirebaseManager.shared.getUser() {
                    FirebaseManager.shared.deleteNote(with: note.id!) { error in
                        if let error = error {
                            print("[\(#function)] Error while deleting note from cloud: \(error.localizedDescription)")
                        } else {
                            FirebaseManager.shared.deleteAttachments(for: note) { error in
                                if let error = error {
                                    print("[\(#function)] Error while deleting attachments for note from cloud: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
                context.delete(note)
                DataManager.deleteFolderForNote(with: note.id!)
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
            let description: NSString? = item.details as NSString?
            let filteredResults = (description!.range(of: searchString!, options: .caseInsensitive).location != NSNotFound)
            return filteredResults
        })
        self.tableView.reloadData()
    }

    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        let ascByTitle = UIAlertAction(title: "Order ASC by title", style: .default, handler: orderASCbyTitle(action:))
        let descByTitle = UIAlertAction(title: "Order DESC by title", style: .default, handler: orderDESCbyTitle(action:))
        let ascByDate = UIAlertAction(title: "Order ASC by date", style: .default, handler: orderASCbyDate(action:))
        let descByDate = UIAlertAction(title: "Order DESC by date", style: .default, handler: orderDESCbyDate(action:))
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        displayAlert(with: nil, message: nil, actions: [ascByTitle, descByTitle, ascByDate, descByDate, cancel], style: .actionSheet)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.text = ""
        self.tableView.reloadData()
    }

}
