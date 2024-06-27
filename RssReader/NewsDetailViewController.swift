//
//  NewsDetailViewController.swift
//  RssReader
//
//  Created by Irfan DUMAN on 19.05.2024.
//

import UIKit

class NewsDetailViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var newsEntity: NewsEntity!

    override func viewDidLoad() {
        super.viewDidLoad()
        let attr = newsEntity.content.htmlToAttributedString?.attributedStringWithResizedImages(with: textView.bounds.width - 10)
        textView.attributedText = attr
    }
}
