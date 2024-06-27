//
//  ViewController.swift
//  RssReader
//
//  Created by Irfan DUMAN on 19.05.2024.
//

import UIKit
import CoreData
import FeedKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var rssLinks: [String] = []
    var entites: [NewsEntity] = []
    
    override func viewDidLoad() {
        /*let ReqVar = NSFetchRequest<NSFetchRequestResult>(entityName: "RssLinks")
                let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: ReqVar)
                do { try getCoreDataViewContext().execute(DelAllReqVar) }
                catch { print(error) }*/
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(linkExtracted(_:)), name: NSNotification.Name(rawValue: "linkExtracted"), object: nil)
        navigationItem.title = "RSS Reader"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAlertWithTextField))
        tableView.delegate = self
        tableView.dataSource = self
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RssLinks")
        request.returnsObjectsAsFaults = false
        do {
            let results = try getCoreDataViewContext().fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let rssLink = result.value(forKey: "link") as? String {
                        rssLinks.insert(rssLink, at: 0)
                    }
                }
            }
        } catch {
            NSLog("data error \(error)")
        }
        if rssLinks.count != 0 {
            extractDataFromRssLink(link: rssLinks[rssLinks.count - 1])
        }
    }
    
    @objc func linkExtracted(_ notification: NSNotification) {
        if let link = notification.userInfo?["link"] as? String {
            let index = self.rssLinks.firstIndex(of: link)
            if(index != 0) {
                extractDataFromRssLink(link: self.rssLinks[index! - 1])
                return
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
         }
    }
    
    func extractDataFromRssLink(link: String) {
        let url = URL(string: link)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                NSLog(error.localizedDescription)
            } else if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let parser = FeedParser(data: data!)
                    parser.parseAsync { (result) in
                        switch result {
                        case .success(let feed):
                            switch feed {
                            case let .atom(feed):
                                let entries = feed.entries ?? []
                                for item in entries.reversed() {
                                    let entity = NewsEntity()
                                    entity.content = item.content?.value
                                    entity.title = item.title
                                    entity.published = item.published
                                    self.entites.insert(entity, at: 0)
                                }
                            case let .rss(feed):
                                let entries = feed.items ?? []
                                for item in entries.reversed() {
                                    let entity = NewsEntity()
                                    entity.content = item.description
                                    entity.title = item.title
                                    entity.published = item.pubDate
                                    self.entites.insert(entity, at: 0)
                                }
                            case let .json(feed):
                                print(feed)
                            }
                        case .failure(let error):
                            print(error)
                        }
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "linkExtracted"), object: nil, userInfo: ["link": link])
                    }
                }
            }
        }.resume()
    }
    
    @objc func showAlertWithTextField() {
        let alertController = UIAlertController(title: "RSS Linkini Giriniz", message: "", preferredStyle: .alert)
        alertController.addTextField { textfield in
            textfield.placeholder = "Linki giriniz"
        }
        let cancel = UIAlertAction(title: "Iptal", style: .cancel)
        let saveAction = UIAlertAction(title: "Kaydet", style: .default, handler: { [self] alert -> Void in
            let linkTextField = alertController.textFields![0] as UITextField
            let photoData = NSEntityDescription.insertNewObject(forEntityName: "RssLinks", into: self.getCoreDataViewContext())
            photoData.setValue(linkTextField.text, forKey: "link")
            rssLinks.insert(linkTextField.text!, at: 0)
            extractDataFromRssLink(link: linkTextField.text!)
            do{
                try self.getCoreDataViewContext().save()
            } catch {
                NSLog("fotoğraf uygulama veritabanına kaydedilirken hata alındı: \(error)")
            }
            
        })
        alertController.addAction(saveAction)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewsDetail" {
            if let toNewsDetail = segue.destination as? NewsDetailViewController {
                if let entity = sender as? NewsEntity {
                    toNewsDetail.newsEntity = entity
                }
            }
        }
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entity = entites[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCustomCell", for: indexPath) as! NewsCustomCell
        cell.titleLabel.text = entity.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toNewsDetail", sender: entites[indexPath.row])
    }
    
}

extension UIViewController {
    func getCoreDataViewContext() -> NSManagedObjectContext {
        let appDelegete = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegete.persistentContainer.viewContext
        return context
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

extension NSAttributedString {
    func attributedStringWithResizedImages(with maxWidth: CGFloat) -> NSAttributedString {
        let text = NSMutableAttributedString(attributedString: self)
        text.setFont(UIFont.systemFont(ofSize: 20))
        let fullRange = NSRange(location: 0, length: text.length)
        text.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 20), range: fullRange)
        text.enumerateAttribute(NSAttributedString.Key.attachment, in: NSMakeRange(0, text.length), options: .init(rawValue: 0), using: { (value, range, stop) in
            if let attachement = value as? NSTextAttachment {
                let image = attachement.image(forBounds: attachement.bounds, textContainer: NSTextContainer(), characterIndex: range.location)!
                if image.size.width > maxWidth {
                    let imageAttributedString = NSMutableAttributedString()
                    let newImage = image.resizeImage(scale: maxWidth/image.size.width)
                    let newAttribut = NSTextAttachment()
                    newAttribut.image = newImage
                    imageAttributedString.append(NSAttributedString(string: "\n\n"))
                    imageAttributedString.append(NSAttributedString(attachment: newAttribut))
                    imageAttributedString.append(NSAttributedString(string: "\n\n"))
                    text.replaceCharacters(in: range, with: imageAttributedString)
                }
            }
        })
        return text
    }
}

extension NSMutableAttributedString {
    func setFont(_ font: UIFont) {
        let fullRange = NSRange(location: 0, length: self.length)
        self.enumerateAttributes(in: fullRange, options: []) { (attributes, range, stop) in
            var newAttributes = attributes
            newAttributes[.font] = font
            self.setAttributes(newAttributes, range: range)
        }
    }
}

extension UIImage {
    func resizeImage(scale: CGFloat) -> UIImage {
        let newSize = CGSize(width: self.size.width*scale, height: self.size.height*scale)
        let rect = CGRect(origin: CGPoint.zero, size: newSize)
        
        UIGraphicsBeginImageContext(newSize)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
