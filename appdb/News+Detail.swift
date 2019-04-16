//
//  News+Detail.swift
//  appdb
//
//  Created by ned on 16/03/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit

class NewsDetail: LoadingTableView {
    
    fileprivate var item: SingleNews! {
        didSet {
            shareButton.isEnabled = true
        }
    }
    var partialItem: SingleNews!
    
    fileprivate var shareButton: UIBarButtonItem!
    
    convenience init(with item: SingleNews) {
        self.init(style: .plain)
        self.partialItem = item
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Todo register cells
        tableView.register(NewsDetailTitleDateCell.self, forCellReuseIdentifier: "titledatecell")
        tableView.register(NewsDetailHTMLCell.self, forCellReuseIdentifier: "htmlcell")

        // Initialize 'Share' button
        shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.share))
        shareButton.isEnabled = false
        
        if Global.isIpad {
            // Add 'Dismiss' button for iPad
            let dismissButton = UIBarButtonItem(title: "Dismiss".localized(), style: .done, target: self, action: #selector(self.dismissAnimated))
            self.navigationItem.rightBarButtonItems = [dismissButton, shareButton]
        } else {
            self.navigationItem.rightBarButtonItems = [shareButton]
        }
        
        // Hide separator for empty cells
        tableView.tableFooterView = UIView()
        
        // UI
        tableView.theme_backgroundColor = Color.veryVeryLightGray
        
        tableView.separatorStyle = .none
        
        showsErrorButton = false
        state = .loading
        
        guard let p = self.partialItem else { return }
        API.getNewsDetail(id: p.id, success: { result in
            self.item = result
            self.state = .done
        }, fail: { error in
            self.showErrorMessage(text: "An error has occurred".localized(), secondaryText: error.localizedDescription, animated: false)
        })
    }
    
    @objc fileprivate func share(sender: UIBarButtonItem) {
        let text = item.title
        let urlString = "\(Global.mainSite)news.php?id=\(item.id)"
        guard let url = URL(string: urlString) else { return }
        let activity = UIActivityViewController(activityItems: [text, url], applicationActivities: [SafariActivity()])
        if #available(iOS 11.0, *) {} else {
            activity.excludedActivityTypes = [.airDrop]
        }
        activity.popoverPresentationController?.barButtonItem = sender
        present(activity, animated: true)
    }
    
    @objc func dismissAnimated() { dismiss(animated: true) }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state == .done ? 2 : 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard state == .done else { return UITableViewCell() }
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "titledatecell", for: indexPath)
                as? NewsDetailTitleDateCell else { return UITableViewCell() }
            cell.title.text = item.title
            cell.date.text = item.added
            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "htmlcell", for: indexPath)
                as? NewsDetailHTMLCell else { return UITableViewCell() }
            cell.htmlText.transform(using: item.text)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard state == .done else { return 0 }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard state == .done else { return 0 }
        switch indexPath.row {
        case 0: return 90
        default: return 300
        }
    }
    
}

extension AttributedLabel {
    func transform(using text: String) {
        var counter = 0
        var isOrdered = false
        
        // Supports <ul>, <ol>, <li>, <p>, <br>
        let transformers: [TagTransformer] = [
            .brTransformer,
            TagTransformer(tagName: "ul", tagType: .start) { _ in
                isOrdered = false
                return ""
            },
            TagTransformer(tagName: "ol", tagType: .start) { _ in
                isOrdered = true
                return ""
            },
            TagTransformer(tagName: "li", tagType: .start) { _ in
                counter += 1
                return isOrdered ? "\(counter). " : "• "
            },
            TagTransformer(tagName: "li", tagType: .end) { _ in
                return "\n"
            },
            TagTransformer(tagName: "p", tagType: .end) { _ in
                return "\n"
            }
            
        ]
        // Supports <b>
        let b = Style("b").font(.boldSystemFont(ofSize: font.pointSize))
        
        // Supports <i>
        let i = Style("i").font(.italicSystemFont(ofSize: font.pointSize))
        
        // Supports <strong>
        let strong = Style("strong").font(.boldSystemFont(ofSize: font.pointSize))
        
        // Supports <u>
        let u = Style("u").underlineStyle(.single)
        
        // Supports <a>
        let link = Style("a").foregroundColor(UIColor(rgba: "#446CB3"), .normal).foregroundColor(UIColor(rgba: "#486A92"), .highlighted)
            .underlineStyle(.single)
        
        // Supports <img>
        let img = Style("img")
        
        // Close <img> tag manually (otherwise it's not detected)
        var newText = text
        if text.contains("<img src") {
            let a = text.components(separatedBy: "<img src")[1].components(separatedBy: ">")[0]
            newText = text.replacingOccurrences(of: a + ">", with: a + "></img>")
        }
        
        // Apply styles
        let str = newText.style(tags: [b, i, strong, u, img, link], transformers: transformers)
        
        // Create NSMutableAttributedString
        let mutableAttrStr = NSMutableAttributedString(attributedString: str.attributedString)
        
        // Insert image if <img> tag is found
        addImageSupport(mutableAttrStr: mutableAttrStr, detections: str.detections)

        // Update text
        attributedText = mutableAttrStr.styleLinks(link)
        
        // Click on url detection
        onClick = { label, detection in
            switch detection.type {
            case .link(let url):
                var partialUrl = url.absoluteString.replacingOccurrences(of: "&amp;", with: "&")
                if !partialUrl.hasPrefix("http") { partialUrl = "http://" + partialUrl }
                guard let fullUrl = URL(string: partialUrl) else { return }
                UIApplication.shared.openURL(fullUrl)
            case .tag(let tag):
                if tag.name == "a", let href = tag.attributes["href"] {
                    if href.hasPrefix("http") {
                        guard let url = URL(string: href.replacingOccurrences(of: "&amp;", with: "&")) else { return }
                        UIApplication.shared.openURL(url)
                    } else {
                        let urlString: String = "\(Global.mainSite)\(href)".replacingOccurrences(of: "&amp;", with: "&")
                        guard let url = URL(string: urlString) else { return }
                        UIApplication.shared.openURL(url)
                    }
                }
            default:
                break
            }
        }
    }
    
    func addImageSupport(mutableAttrStr: NSMutableAttributedString, detections: [Detection]) {
        var locationShift = 0
        for detection in detections {
            switch detection.type {
            case .tag(let tag):

                if tag.name == "img", let imageSrc = tag.attributes["src"] {
                
                    if let url = URL(string: imageSrc) {
                        let textAttachment = NSTextAttachment()
                        
                        // Load image synchronously
                        if let data = try? Data(contentsOf: url) {
                            let image = UIImage(data: data)
                            textAttachment.image = image
                            
                            // Give it a fixed width
                            var maxWidth = UIScreen.main.bounds.width - 100
                            if maxWidth > 500 { maxWidth = 500 }
                            textAttachment.setImageWidth(width: maxWidth)
                            
                            // Add image
                            let imageAttrStr = NSAttributedString(attachment: textAttachment)
                            let nsrange = NSRange.init(detection.range, in: mutableAttrStr.string)
                            mutableAttrStr.insert(imageAttrStr, at: nsrange.location + locationShift)
                            locationShift += 1
                        }
                    }
                }
            default:
                break
            }
        }
        
        // Center the image
        mutableAttrStr.setAttachmentsAlignment(.center)
    }
}

extension NSTextAttachment {
    func setImageWidth(width: CGFloat) {
        guard let image = image else { return }
        let ratio = image.size.width / image.size.height
        bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: width, height: width / ratio)
    }
}

extension NSMutableAttributedString {
    func setAttachmentsAlignment(_ alignment: NSTextAlignment) {
        self.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: self.length), options: .longestEffectiveRangeNotRequired) { (attribute, range, stop) -> Void in
            if attribute is NSTextAttachment {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = alignment
                paragraphStyle.lineBreakMode = .byTruncatingTail
                self.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)
            }
        }
    }
}
