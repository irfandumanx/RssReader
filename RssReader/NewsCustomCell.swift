//
//  NewsCustomCell.swift
//  RssReader
//
//  Created by Irfan DUMAN on 19.05.2024.
//

import UIKit

class NewsCustomCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
