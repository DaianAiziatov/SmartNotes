//
//  NoteTableViewCell.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 14/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit
import CoreData

class NoteTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.contentView.backgroundColor = selected ? #colorLiteral(red: 0.9022161365, green: 0.7540545464, blue: 0.162062794, alpha: 1) : #colorLiteral(red: 0.4352941176, green: 0.4431372549, blue: 0.4745098039, alpha: 0)
    }

    func configure(with note: Note) {
        let text = note.details as! NSAttributedString
        let lines = text.string.split(separator: "\n")
        let title = lines.count > 0 ? NSAttributedString(string: String(lines[0])) : text
        let details = lines.count > 1 ? String(lines.dropFirst().joined()) : nil
        titleLabel.attributedText = title
        let date = DateFormatter()
        date.dateFormat = "MM/dd/yy"
        let dateSaved = date.string(from: note.date!)
        subtitleLabel.text = "\(dateSaved) - \(details ?? "No additional text" )"
    }

}