//
//  AudioCoordinator.swift
//  Sleep
//
//  Created by Ryan Ortiz on 3/23/26.
//

import Foundation
import AVFoundation

/// High-level facade that composes AudioSessionManager, EngineHost, and PlayerService.
/// Keeps track of PlayerService instances for layered playback.
/// This coordinator also provides the future entry point for per-track effect control.
final class AudioCoordinator {
    static let shared = AudioCoordinator()

    private let session = AudioSessionManager.shared
    private let engineHost = EngineHost.shared

    /// TrackID -> PlayerService
    private var players: [UUID: PlayerService] = [:]

    private init() {}

    /// Configure session, start engine, and register any in-app AUs later.
    /// The AVAudioEngine is started only after nodes are attached.
    func startAudio() {
        session.configure()
        do {
            try session.activate()
            print("AudioCoordinator: session activated (engine start deferred)")
        } catch {
            print("AudioCoordinator: error activating session: \(error)")
        }
    }

    func stopAudio() {
        engineHost.stopEngine()
        do {
            try session.deactivate()
        } catch {
            print("AudioCoordinator: error deactivating session: \(error)")
        }
    }

    /// Add a track from bundle by resource name and return the PlayerTrack id.
    /// Example: addTrackFromBundle(name: "music", ext: "wav")
    @discardableResult
    func addTrackFromBundle(name: String, ext: String, loop: Bool = false) -> UUID? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("AudioCoordinator: bundle resource not found: \(name).\(ext)")
            return nil
        }

        let track = PlayerTrack(url: url, name: name, loop: loop)
        let service = PlayerService(track: track)

        do {
            try engineHost.startEngine()
        } catch {
            print("AudioCoordinator: failed to start engine after attaching nodes: \(error)")
        }

        do {
            try service.load()
            try service.schedule()
        } catch {
            print("AudioCoordinator: failed to load/schedule track: \(error)")
        }

        players[track.id] = service
        return track.id
    }

    func removeTrack(id: UUID) {
        guard let svc = players.removeValue(forKey: id) else { return }
        svc.stop()
    }

    func playAll() {
        players.values.forEach { $0.play() }
    }

    func pauseAll() {
        players.values.forEach { $0.pause() }
    }

    func togglePlayback(for id: UUID) {
        guard let p = players[id] else { return }
        if p.isPlaying { p.pause() } else { p.play() }
    }

    /// Future effect entry point for a specific track.
    /// For now, this forwards into the track's modular effect chain.
    func toggleEffect(for id: UUID, enabled: Bool) {
        guard let p = players[id] else { return }
        p.effects.setLowPassEnabled(enabled)
    }

    /// Future parameter entry point for a specific track.
    /// Address-based control remains here so UI code does not need to know the effect internals.
    func setParameterForTrack(_ id: UUID, address: AUParameterAddress, value: AUValue) {
        guard let p = players[id] else { return }

        // Minimal routing for now: reserve this for future effect controller expansion.
        // If we later add more effect types, this can route by address.
        if address == 0 {
            p.effects.setLowPassCutoff(value)
        }
    }

    /// Convenience low-pass control for UI or future automation.
    func setLowPassCutoff(forTrack id: UUID, cutoff: Float) {
        guard let p = players[id] else { return }
        p.effects.setLowPassCutoff(cutoff)
    }
}
