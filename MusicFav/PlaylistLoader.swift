//
//  PlaylistLoader.swift
//  MusicFav
//
//  Created by Hiroki Kumamoto on 4/5/15.
//  Copyright (c) 2015 Hiroki Kumamoto. All rights reserved.
//

import Foundation
import ReactiveCocoa
import LlamaKit


class PlaylistLoader {
    let playlist: Playlist
    var signal:   ColdSignal<Track>?
    init(playlist: Playlist) {
        self.playlist = playlist
    }

    deinit {
        
    }

    func dispose() {
    }

    func fetchTracks() -> ColdSignal<Track> {
        var pairs: [(Int, Track)] = []
        for i in 0..<playlist.tracks.count {
            let pair = (i, playlist.tracks[i])
            pairs.append(pair)
        }
        signal = pairs.map {
            self.fetchTrack($0.0, track: $0.1)
            }.reduce(ColdSignal<Track>.empty(), combine: { (signal, nextSignal) in
                signal.concat(nextSignal)
            })
        return signal!
    }

    func fetchTrack(index: Int, track: Track) -> ColdSignal<Track> {
        return track.fetchTrackDetail(false).map { t -> Track in
            Playlist.notifyChange(.TrackUpdated(self.playlist, t))
            self.playlist.sink.put(index)
            return t
        }
    }

    func uploadTrackToCacheServer() {
        
    }
}
