//
//  PlayerService.swift
//  Sleep
//
//  Created by Ryan Ortiz on 3/23/26.
//

import Foundation
import AVFoundation

/// Manages one track’s playback using an AVAudioPlayerNode and a per-track mixer node.
/// Handles loading, scheduling, playback control, and cleanup.
/// Effects are routed through a modular TrackEffectChain so this class stays playback-focused.
final class PlayerService {
    // This service receives a PlayerTrack model, not a raw audio file.
    // PlayerTrack holds metadata + file location.
    // PlayerService.load() opens the real audio file using track.url.
    let track: PlayerTrack

    // Produces the audio for this track.
    private(set) lazy var playerNode = AVAudioPlayerNode()

    // Handles per-track mixing, gain, and pan.
    private(set) lazy var trackMixer = AVAudioMixerNode()

    // Modular effect layer. Starts empty but gives us a place to add effects later
    // without changing PlayerService's responsibilities.
    private let effectChain = TrackEffectChain()

    private var audioFile: AVAudioFile?

    // Uses the shared engine host; does not own the singleton.
    private let engineHost = EngineHost.shared

    init(track: PlayerTrack) {
        self.track = track

        // Attach nodes to the engine.
        engineHost.attach(node: playerNode)
        engineHost.attach(node: trackMixer)

        // Enable low-pass by default so the effect node exists before connecting the chain.
        effectChain.enableLowPass()

        // Route the player through the effect chain and then into the track mixer.
        // For now the chain is pass-through, so this is effectively:
        // playerNode -> trackMixer -> mainMixerNode
        effectChain.connect(source: playerNode, to: trackMixer, format: nil)

        // Final output into the main mixer.
        engineHost.connect(source: trackMixer, to: engineHost.engine.mainMixerNode, format: nil)
    }

    deinit {
        // Clean up connections and detach nodes.
        effectChain.disconnect()
        engineHost.disconnect(node: trackMixer)
        engineHost.detach(node: playerNode)
        engineHost.detach(node: trackMixer)
    }

    /// Loads the audio file for this track from the URL specified in the PlayerTrack model.
    func load() throws {
        audioFile = try AVAudioFile(forReading: track.url)
    }

    /// Schedules playback from the file.
    /// If `startAt` is provided, playback starts at that audio time.
    func schedule(startAt: AVAudioTime? = nil) throws {
        if audioFile == nil {
            audioFile = try AVAudioFile(forReading: track.url)
        }

        guard let file = audioFile else {
            throw NSError(
                domain: "PlayerService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Audio file not loaded"]
            )
        }

        if playerNode.isPlaying {
            playerNode.stop()
        }

        file.framePosition = 0

        playerNode.scheduleFile(file, at: startAt) { [weak self] in
            guard let self = self else { return }
            if self.track.loop {
                DispatchQueue.main.async {
                    do {
                        try self.schedule(startAt: nil)
                        self.play()
                    } catch {
                        print("PlayerService: failed to reschedule loop: \(error)")
                    }
                }
            }
        }
    }

    func play() {
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    func pause() {
        if playerNode.isPlaying {
            playerNode.pause()
        }
    }

    func stop() {
        playerNode.stop()
    }

    var isPlaying: Bool {
        playerNode.isPlaying
    }

    /// Adjusts per-track gain through the mixer node.
    func setGain(_ gain: Float) {
        trackMixer.outputVolume = gain
    }

    /// Adjusts per-track pan through the mixer node.
    func setPan(_ pan: Float) {
        trackMixer.pan = pan
    }

    /// Access to the modular effect chain for future effect wiring.
    var effects: TrackEffectChain {
        effectChain
    }
}
