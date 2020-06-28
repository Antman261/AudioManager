//
//  AudioController.swift
//
//  Created by Anthony Manning-Franklin on 28/6/20.
//  Copyright © 2020 Anthony Manning-Franklin. All rights reserved.
//

import Foundation
import CoreAudioKit

public enum AudioControllerError: Error {
    case audioDeviceUnknown
    case cannotGetDefaultAudioDevice
    case audioDeviceHasNoVolumeControl
    case cannotReadVolumeControl
    case audioDeviceHasNoMuteControl
    case unknownOsError
}

public class AudioController {
    var audioDeviceId: AudioDeviceID;
    var bufferSize: UInt32;
    var deviceAddress: AudioObjectPropertyAddress;
    var volumeAddress: AudioObjectPropertyAddress;
    var mutedAddress: AudioObjectPropertyAddress;
    
    init() {
        audioDeviceId = kAudioObjectUnknown
        bufferSize = UInt32(MemoryLayout.size(ofValue: audioDeviceId))
        deviceAddress = AudioController.getDevicePropertyAddress(kAudioHardwarePropertyDefaultOutputDevice)
        volumeAddress = AudioController.getDevicePropertyAddress(kAudioHardwareServiceDeviceProperty_VirtualMasterVolume)
        mutedAddress = AudioController.getDevicePropertyAddress(kAudioDevicePropertyMute)
        audioDeviceId = getDefaultOutputDevice()
    }
    
    func getSystemVolume() throws -> Float {
        var volume: Float32 = 0
        do {
            guard try isDeviceKnown(),
                try checkVolumeControl()
                else {
                return 0.0
            }
            
            let error: OSStatus = getAudioDevicePropertyData(&volumeAddress, &bufferSize, &volume)
            if (error != noErr) {
                print("Unable to read volume for device 0x%0x", audioDeviceId)
                throw AudioControllerError.cannotReadVolumeControl
            }
        } catch let err {
            throw err
        }
        
        return AudioController.getBoundedVolumeFromFloat(volume)
    }
    
    func isSystemAudioMuted() throws -> Bool {
        var muted: UInt32 = 0
        var mutedSize = UInt32(4) // Because obviously a 32bit int is 4 bytes in size
        
        guard try isDeviceKnown(),
            checkHasMuteCanMute()
            else {
            return false
        }
        
        let getMutedErr = getAudioDevicePropertyData(&mutedAddress, &mutedSize, &muted)
        return getMutedErr == noErr && muted != 0
    }
    
    func setSystemAudioMuted(_ muted: Bool) throws {
        var mutableMuted = muted ? 1 : 0
        do {
            guard try isDeviceKnown(),
                checkHasMuteCanMute()
                else {
                    throw AudioControllerError.audioDeviceHasNoMuteControl
            }
        } catch let e {
            throw e
        }
        let mutedSize = UInt32(MemoryLayout.size(ofValue: mutableMuted))
        let err = setAudioDevicePropertyData(&mutedAddress, mutedSize, &mutableMuted)
        if (err != noErr) {
            print("Error muting device: \(err)")
            throw AudioControllerError.unknownOsError
        }
    }
    
    func setSystemVolume(_ volume: Float) throws {
        var newVolume = AudioController.getBoundedVolumeFromFloat(volume)
        let newVolumeSize = UInt32(MemoryLayout.size(ofValue: newVolume))
        do {
            guard try isDeviceKnown(),
                try checkVolumeControl()
                else {
                    throw AudioControllerError.audioDeviceHasNoVolumeControl
            }
        } catch let e {
            throw e
        }
        let err = setAudioDevicePropertyData(&volumeAddress, newVolumeSize, &newVolume)
        if (err != noErr) {
            print("Error muting device: \(err)")
            throw AudioControllerError.unknownOsError
        }
    }
    
    private func getDefaultOutputDevice() -> AudioDeviceID {
        if (!AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &deviceAddress)) {
            print("Unable to get default audio device")
        }
        let error: OSStatus = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &deviceAddress, UInt32(0), nil, &bufferSize, &audioDeviceId)
        if (error != noErr) {
            print("Unable to get output audio device")
        }
        return audioDeviceId
    }
    private static func getDevicePropertyAddress(_ property: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress.init(
            mSelector: property,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )
    }
    private static func getBoundedVolumeFromFloat(_ unboundedFloat: Float) -> Float {
        return unboundedFloat > 1.0 ? 1.0 : unboundedFloat < 0.0 ? 0.0 : unboundedFloat
    }
    private func isDeviceKnown() throws -> Bool {
        if (audioDeviceId == kAudioObjectUnknown) {
            throw AudioControllerError.audioDeviceUnknown
        }
        return true
    }
    private func checkVolumeControl() throws -> Bool {
        if (!AudioObjectHasProperty(audioDeviceId, &volumeAddress)) {
            print("No volume control for device 0x%0x", audioDeviceId)
            throw AudioControllerError.audioDeviceHasNoVolumeControl
        }
        return true
    }
    private func checkHasMuteCanMute() -> Bool {
        var canMute: DarwinBoolean = true
        let hasMute: Bool = AudioObjectHasProperty(audioDeviceId, &mutedAddress)
        if (hasMute) {
            let err = AudioObjectIsPropertySettable(audioDeviceId, &mutedAddress, &canMute)
            return err == noErr && canMute.boolValue
        }
        return false
    }
    private func getAudioDevicePropertyData(_ propertyAddress: UnsafePointer<AudioObjectPropertyAddress>,
                                            _ propertySize: UnsafeMutablePointer<UInt32>,
                                            _ propertyData: UnsafeMutableRawPointer) -> OSStatus {
        return AudioObjectGetPropertyData(audioDeviceId, propertyAddress, 0, nil, propertySize, propertyData)
    }
    private func setAudioDevicePropertyData(_ propertyAddress: UnsafePointer<AudioObjectPropertyAddress>,
                                            _ propertySize: UInt32,
                                            _ propertyData: UnsafeMutableRawPointer) -> OSStatus {
        return AudioObjectSetPropertyData(audioDeviceId, propertyAddress, 0, nil, propertySize, propertyData)
    }
}
