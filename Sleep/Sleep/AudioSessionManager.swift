//
//  AudioSessionManager.swift
//  Sleep
//
//  Created by Ryan Ortiz on 3/23/26.
//

import Foundation
import AVFoundation

// This file configures how the system will handle the audio session for this app
// It is set to playback so the apps is treated as a playback app
// it doesnt play back audio directly it configures routing, interruptions, and silent switch handlling
// its configured then activated when audio begins
// it doesnt configure sample rate just reads it from the current system

/// Manages AVAudioSession configuration/activation.
final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    /// Configure session; safe to call multiple times.
    func configure(category: AVAudioSession.Category = .playback,
                   mode: AVAudioSession.Mode = .default,
                   options: AVAudioSession.CategoryOptions = []) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(category, mode: mode, options: options)
            // Do not activate here if caller wants to control activation timing.
        } catch {
            print("AudioSessionManager: Failed to set category: \(error)")
        }
    }

    /// Activate the audio session.
    func activate() throws {
        try AVAudioSession.sharedInstance().setActive(true)
    }

    /// Deactivate the audio session.
    func deactivate() throws {
        try AVAudioSession.sharedInstance().setActive(false)
    }

    /// Convenience: current sample rate the session is using.
    var sampleRate: Double {
        return AVAudioSession.sharedInstance().sampleRate
    }
}
