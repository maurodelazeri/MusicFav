//
//  XCDYouTubeClient.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 4/7/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import XCDYouTubeKit
import ReactiveCocoa
import LlamaKit

struct XCDYouTubeClientConfig {
    static var languageIdentifier: String? = "en"
}

extension XCDYouTubeClient {
    func fetchVideo(identifier: String, errorOnFailure: Bool) -> ColdSignal<XCDYouTubeVideo> {
        return ColdSignal { (sink, disposable) in
            self.getVideoWithIdentifier(identifier, completionHandler: { (video, error) -> Void in
                if let e = error {
                    if errorOnFailure {
                        sink.put(.Error(error))
                    } else {
                        sink.put(.Completed)
                    }
                    return
                }
                sink.put(.Next(Box(video)))
                sink.put(.Completed)
            })
            return
        }
    }
}
