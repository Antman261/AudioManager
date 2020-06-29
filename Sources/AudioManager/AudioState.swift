//
//  AudioState.swift
//
//  Created by Anthony Manning-Franklin on 28/6/20.
//  Copyright © 2020 Anthony Manning-Franklin. All rights reserved.
//

import Foundation

public struct AudioState {
    public let volume: Float64
    public let muted: Bool
    public var dictionary: [String: Any] {
        return ["volume": volume,
                "muted": muted]
    }
}

extension AudioState {
    public init?(json: [String : Any]) {
        guard let volume = json["volume"] as? Float64,
            let muted = json["muted"] as? Bool
            else {
                return nil
        }
        self.volume = volume
        self.muted = muted
    }
}
