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
/// For Phase 0/1 we support: startAudio(), addTrackFromBundle(), playAll(), pauseAll(), toggle per-track playback.
final class AudioCoordinator {
    static let shared = AudioCoordinator()

    private let session = AudioSessionManager.shared
    private let engineHost = EngineHost.shared

    /// TrackID -> PlayerService
    private var players: [UUID: PlayerService] = [:]

    private init() {}

    /// Configure session, start engine, and register any in‑app AUs later (Phase 2).
    /// does not start the AVAudioEngine immediately, as we want to ensure nodes are attached before starting.
    func startAudio() {
        session.configure()
        do {
            try session.activate()
            // Do not start the AVAudioEngine here; start it after nodes are attached
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
        
        // Create the track model from the bundled file URL, then inject it into PlayerService.
        // This is constructor dependency injection: PlayerService receives a PlayerTrack object
        // instead of creating or searching for the track itself.
        let track = PlayerTrack(url: url, name: name, loop: loop)
        let service = PlayerService(track: track)

        // Start engine now that nodes are attached (idempotent)
        do {
            try engineHost.startEngine()
        } catch {
            print("AudioCoordinator: failed to start engine after attaching nodes: \(error)")
            // We continue so caller still gets the track object; but playback will fail until engine starts
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
        // PlayerService deinit detaches nodes
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

    // Placeholder for Phase 2: enable/disable per-track effect
    func toggleEffect(for id: UUID) {
        // TODO: create EffectController for the track and connect it between playerNode and trackMixer
        print("AudioCoordinator: toggleEffect(for:) - not implemented yet (Phase 2)")
    }

    // Placeholder: per-track parameter control (Phase 2)
    func setParameterForTrack(_ id: UUID, address: AUParameterAddress, value: AUValue) {
        // TODO: forward to EffectController if instantiated
        print("AudioCoordinator: setParameterForTrack - not implemented yet")
    }
}
