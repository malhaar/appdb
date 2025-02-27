//
//  API+IPACache.swift
//  appdb
//
//  Created by ned on 05/01/22.
//  Copyright © 2022 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON

extension API {

    static func getIPACacheStatus(success:@escaping (_ status: IPACacheStatus) -> Void, fail:@escaping (_ error: NSError) -> Void) {

        AF.request(endpoint, parameters: ["action": Actions.getIpaCacheStatus.rawValue, "lang": languageCode], headers: headersWithCookie)
            .responseObject(keyPath: "data") { (response: AFDataResponse<IPACacheStatus>) in
                switch response.result {
                case .success(let result):
                    success(result)
                case .failure(let error):
                    fail(error as NSError)
                }
            }
    }

    static func reinstallEverything(success:@escaping () -> Void, fail:@escaping (_ error: String) -> Void) {
        AF.request(endpoint, parameters: ["action": Actions.installFromCache.rawValue, "lang": languageCode], headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                       fail(json["errors"][0]["translated"].stringValue)
                    } else {
                        success()
                    }
                case .failure(let error):
                    fail(error.localizedDescription)
                }
            }
    }

    static func clearIpaCache(success:@escaping () -> Void) {
        AF.request(endpoint, parameters: ["action": Actions.clearIpaCache.rawValue, "lang": languageCode], headers: headersWithCookie)
            .response { _ in
                success()
            }
    }

    static func revalidateIpaCache(success:@escaping () -> Void) {
        AF.request(endpoint, parameters: ["action": Actions.revalidateIpaCache.rawValue, "lang": languageCode], headers: headersWithCookie)
            .response { _ in
                success()
            }
    }
}
