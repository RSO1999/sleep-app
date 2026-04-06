//
//  PlayerTrack.swift
//  Sleep
//
//  Created by Ryan Ortiz on 3/23/26.
//

import Foundation

/// Lightweight model describing a track to be played.
struct PlayerTrack: Identifiable {
    let id: UUID
    let url: URL
    let name: String
    let loop: Bool

    init(id: UUID = UUID(), url: URL, name: String, loop: Bool = false) {
        self.id = id
        self.url = url
        self.name = name
        self.loop = loop
    }
}
