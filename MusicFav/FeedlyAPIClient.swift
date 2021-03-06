//
//  FeedlyAPIClient.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 12/21/14.
//  Copyright (c) 2014 Hiroki Kumamoto. All rights reserved.
//

import UIKit
import SwiftyJSON
import ReactiveCocoa
import LlamaKit
import FeedlyKit
import Alamofire
import NXOAuth2Client

struct FeedlyAPIClientConfig {
    static let baseUrl      = "https://sandbox.feedly.com"
    static let authPath     = "/v3/auth/auth"
    static let tokenPath    = "/v3/auth/token"
    static let accountType  = "Feedly"
    static let redirectUrl  = "http://localhost"
    static let scopeUrl     = "https://cloud.feedly.com/subscriptions"
    static let authUrl      = String(format: "%@/%@", baseUrl, authPath)
    static let tokenUrl     = String(format: "%@/%@", baseUrl, tokenPath)
    static let perPage      = 15

    static var clientId     = "sandbox"
    static var clientSecret = "8LDQOW8KPYFPCQV2UL6J"
    static var target       = CloudAPIClient.Target.Sandbox
}

class FeedlyAPIClient {
    class func alertController(#error:NSError, handler: (UIAlertAction!) -> Void) -> UIAlertController {
        let ac = UIAlertController(title: "Network error".localize(),
                                 message: "Sorry, network error occured.".localize(),
                          preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK".localize(), style: UIAlertActionStyle.Default, handler: handler)
        ac.addAction(okAction)
        return ac
    }

    class var sharedInstance : FeedlyAPIClient {
        struct Static {
            static let instance : FeedlyAPIClient = FeedlyAPIClient()
        }
        return Static.instance
    }

    init() {
        loadConfig()
    }

    func loadConfig() {
        let bundle = NSBundle.mainBundle()
        if let path = bundle.pathForResource("feedly", ofType: "json") {
            let data     = NSData(contentsOfFile: path)
            let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!,
                options: NSJSONReadingOptions.MutableContainers,
                error: nil)
            if let obj: AnyObject = jsonObject {
                let json = JSON(obj)
                if json["target"].stringValue == "production" {
                    FeedlyAPIClientConfig.target = .Production
                }
                if let clientId = json["client_id"].string {
                    FeedlyAPIClientConfig.clientId = clientId
                }
                if let clientSecret = json["client_secret"].string {
                    FeedlyAPIClientConfig.clientSecret = clientSecret
                }
            }
        }
    }

    private var _account: NXOAuth2Account?
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    var isLoggedIn: Bool {
        return account != nil
    }

    var _client: CloudAPIClient = CloudAPIClient()
    var client: CloudAPIClient {
        get {
            CloudAPIClient.Config.accessToken = account?.accessToken.accessToken
            return _client
        }
    }

    var account: NXOAuth2Account? {
        get {
            if let a = _account {
                return a
            }
            let store = NXOAuth2AccountStore.sharedStore() as NXOAuth2AccountStore
            for account in store.accounts as [NXOAuth2Account] {
                if account.accountType == "Feedly" {
                    _account = account
                    return account
                }
            }
            return nil
        }
    }
    private var _profile: Profile?
    var profile: Profile? {
        get {
            if let p = _profile {
                return p
            }
            if let data: NSData = userDefaults.objectForKey("profile") as? NSData {
                _profile = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Profile
                return _profile
            }
            return nil
        }
        set(profile) {
            if let p = profile {
                userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(p), forKey: "profile")
            } else {
                userDefaults.removeObjectForKey("profile")
            }
            _profile = profile
        }
    }

    func clearAllAccount() {
        let store = NXOAuth2AccountStore.sharedStore() as NXOAuth2AccountStore
        for account in store.accounts as [NXOAuth2Account] {
            if account.accountType == "Feedly" {
                store.removeAccount(account)
            }
        }
        _account = nil
    }

    func fetchProfile() -> ColdSignal<Profile> {
        return ColdSignal { (sink, disposable) in
            let req = self.client.fetchProfile({ (req, res, profile, error) -> Void in
                if let e = error {
                    sink.put(.Error(e))
                } else {
                    sink.put(Event.Next(Box(profile!)))
                    sink.put(.Completed)
                }
            })
            disposable.addDisposable({ req.cancel() })
        }
    }

    func fetchSubscriptions() -> ColdSignal<[Subscription]> {
        return ColdSignal { (sink, disposable) in
            let req = self.client.fetchSubscriptions({ (req, res, subscriptions, error) -> Void in
                if let e = error {
                    sink.put(.Error(e))
                } else {
                    sink.put(.Next(Box(subscriptions!)))
                    sink.put(.Completed)
                }
            })
            disposable.addDisposable({ req.cancel() })
        }
    }

    func fetchEntries(#streamId: String, newerThan: Int64, unreadOnly: Bool) -> ColdSignal<PaginatedEntryCollection> {
        var paginationParams        = PaginationParams()
        paginationParams.unreadOnly = unreadOnly
        paginationParams.count      = FeedlyAPIClientConfig.perPage
        paginationParams.newerThan  = newerThan
        return fetchEntries(streamId: streamId, paginationParams: paginationParams)
    }

    func fetchEntries(#streamId: String, continuation: String?, unreadOnly: Bool) -> ColdSignal<PaginatedEntryCollection> {
        var paginationParams          = PaginationParams()
        paginationParams.unreadOnly   = unreadOnly
        paginationParams.count        = FeedlyAPIClientConfig.perPage
        paginationParams.continuation = continuation
        return fetchEntries(streamId: streamId, paginationParams: paginationParams)
    }

    func fetchEntries(#streamId: String, paginationParams: PaginationParams) -> ColdSignal<PaginatedEntryCollection> {
        return ColdSignal { (sink, disposable) in
            let req = self.client.fetchContents(streamId, paginationParams: paginationParams, completionHandler: { (req, res, entries, error) -> Void in
                if let e = error {
                    sink.put(.Error(e))
                } else {
                    sink.put(.Next(Box(entries!)))
                    sink.put(.Completed)
                }
            })
            disposable.addDisposable({ req.cancel() })
        }
    }

    func fetchFeedsByIds(feedIds: [String]) -> ColdSignal<[Feed]> {
        return ColdSignal { (sink, disposable) in
            let req = self.client.fetchFeeds(feedIds, completionHandler: { (req, res, feeds, error) -> Void in
                if let e = error {
                    sink.put(.Error(e))
                } else {
                    sink.put(.Next(Box(feeds!)))
                    sink.put(.Completed)
                }
            })
            disposable.addDisposable({ req.cancel() })
        }
    }

    func fetchCategories() -> ColdSignal<[FeedlyKit.Category]> {
        return ColdSignal { (sink, disposable) in
            let req = self.client.fetchCategories({ (req, res, categories, error) -> Void in
                if let e = error {
                    sink.put(.Error(e))
                } else {
                    sink.put(.Next(Box(categories!)))
                    sink.put(.Completed)
                }
            })
            disposable.addDisposable({ req.cancel() })
        }
    }

    func searchFeeds(query: SearchQueryOfFeed) -> ColdSignal<[Feed]> {
        return ColdSignal { (sink, disposable) in
            let req = self.client.searchFeeds(query, completionHandler: { (req, res, feedResults, error) -> Void in
                if let e = error {
                    sink.put(.Error(e))
                } else {
                    if let _feedResults = feedResults {
                        sink.put(.Next(Box(_feedResults.results)))
                        sink.put(.Completed)
                    }
                }
            })
            disposable.addDisposable({ req.cancel() })
        }
    }
}
