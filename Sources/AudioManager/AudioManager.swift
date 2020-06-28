//
//  AudioManager.swift
//
//  Created by Anthony Manning-Franklin on 28/6/20.
//  Copyright © 2020 Anthony Manning-Franklin. All rights reserved.
//

import Foundation

public class AudioManager {
    var audioController: AudioController
    
    init() {
        audioController = AudioController()
    }
    
    public func getAudioState() throws -> AudioState {
        return AudioState(volume: try Float64(audioController.getSystemVolume()),
                          muted: try audioController.isSystemAudioMuted())
    }
    
    public func setAudioState(_ state: AudioState) throws -> AudioState {
        try audioController.setSystemVolume(Float(state.volume))
        try audioController.setSystemAudioMuted(state.muted)
        return try getAudioState()
    }
}
