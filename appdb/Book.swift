//
//  Book.swift
//  appdb
//
//  Created by ned on 12/10/2016.
//  Copyright © 2016 ned. All rights reserved.
//


import RealmSwift
import SwiftyJSON
import ObjectMapper

class Book: Object, Meta {
    
    convenience required init?(map: Map) { self.init() }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    static func type() -> ItemType {
        return .books
    }
    
    // iTunes data
    var lastParseItunes = ""
    
    @objc dynamic var name = ""
    @objc dynamic var id = ""
    @objc dynamic var image = ""
    
    // General
    @objc dynamic var categoryId = ""
    @objc dynamic var printLenght = ""
    @objc dynamic var published = ""
    @objc dynamic var author = ""
    
    // Text
    @objc dynamic var description_ = ""
    
    // Ratings
    @objc dynamic var numberOfRating = ""
    @objc dynamic var numberOfStars: Double = 0.0
    
    // Information
    @objc dynamic var updated = ""
    @objc dynamic var price = ""
    @objc dynamic var requirements = ""
    @objc dynamic var language = ""
    
    // Artist ID
    @objc dynamic var artistId = ""
    
    // Copyright
    @objc dynamic var publisher = ""
    
    // Related Books
    var relatedBooks = List<RelatedContent>()
    
    // Related Apps
    var reviews = List<Review>()
}

extension Book: Mappable {
    func mapping(map: Map) {
        
        name                    <- map["name"]
        id                      <- map["id"]
        image                   <- map["image"]
        price                   <- map["price"]
        categoryId              <- map["genre_id"]
        author                  <- map["pname"]
        updated                 <- map["added"]
        description_            <- map["description"]
        artistId                <- map["artist_id"]
        lastParseItunes         <- map["last_parse_itunes"]
        
        if let data = lastParseItunes.data(using: .utf8), let itunesParse = try? JSON(data: data) {
            
            // Information
            printLenght = itunesParse["printlength"].stringValue
            publisher = itunesParse["seller"].stringValue
            requirements = itunesParse["requirements"].stringValue
            published = itunesParse["published"].stringValue
            language = itunesParse["languages"].stringValue
            
            // Dirty fixes
            while published.hasPrefix(" ") { published = String(published.dropFirst()) }
            if published == "01.01.1970" { published = "" }
            if language.hasPrefix("Language: ") { language = String(language.dropFirst(10)) }
            if language.hasPrefix("Requirements") { language = "" }
            if printLenght.hasPrefix("Language") { printLenght = "" }
            
            // Ratings
            if !itunesParse["ratings"]["current"].stringValue.isEmpty {
                
                // numberOfRating
                let array = itunesParse["ratings"]["current"].stringValue.components(separatedBy: ", ")
                let array2 = "\(array[1])".components(separatedBy: " ")
                if let tmpNumber = Int(array2[0]) {
                    let num: NSNumber = NSNumber(value: tmpNumber)
                    numberOfRating = "(" + NumberFormatter.localizedString(from: num, number: .decimal) + ")"
                }
                
                // numberOfStars
                let array3 = itunesParse["ratings"]["current"].stringValue.components(separatedBy: " ")
                if let tmpStars = Double(array3[0]) {
                    numberOfStars = itunesParse["ratings"]["current"].stringValue.contains("half") ? tmpStars + 0.5 : tmpStars
                }
            } else if !itunesParse["ratings"]["count"].stringValue.isEmpty {
                
                // numberOfRating
                let count = itunesParse["ratings"]["count"].intValue
                numberOfRating = "(" + NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal) + ")"
                
                // numberOfStars
                numberOfStars = itunesParse["ratings"]["stars"].doubleValue
            }
            
            // Related Books
            let tmpRelated = List<RelatedContent>()
            for i in 0..<itunesParse["relatedapps"].count {
                let item = itunesParse["relatedapps"][i]
                if !item["type"].stringValue.isEmpty, !item["trackid"].stringValue.isEmpty, !item["artist"]["name"].stringValue.isEmpty {
                    tmpRelated.append(RelatedContent(
                        icon: item["image"].stringValue,
                        id: item["trackid"].stringValue,
                        name: item["name"].stringValue,
                        artist: item["artist"]["name"].stringValue
                    ))
                }
            }
            
            // Also Bought
            for i in 0..<itunesParse["alsobought"].count {
                let item = itunesParse["alsobought"][i]
                if !item["type"].stringValue.isEmpty, !item["trackid"].stringValue.isEmpty, !item["artist"]["name"].stringValue.isEmpty {
                    tmpRelated.append(RelatedContent(
                        icon: item["image"].stringValue,
                        id: item["trackid"].stringValue,
                        name: item["name"].stringValue,
                        artist: item["artist"]["name"].stringValue
                    ))
                }
            }; relatedBooks = tmpRelated
            
            // Reviews
            let tmpReviews = List<Review>()
            for i in 0..<itunesParse["reviews"].count {
                let item = itunesParse["reviews"][i]
                tmpReviews.append(Review(
                    author: item["author"].stringValue,
                    text: item["text"].stringValue,
                    title: item["title"].stringValue,
                    rating: item["rating"].doubleValue
                ))
            }; reviews = tmpReviews
        }

    }
}
