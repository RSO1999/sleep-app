//
//  TrackEffectChain.swift
//  Sleep
//


import Foundation
import AVFoundation

/// Modular per-track effect layer.
/// Keeps PlayerService focused on playback only.
/// Effects can be added here without tightly coupling them to PlayerService.
final class TrackEffectChain {
    private let engineHost: EngineHost

    /// The first node in the chain that receives audio from the player.
    /// For now this is the final output of the chain as well.
    private(set) var entryNode: AVAudioNode?

    /// The last node in the chain that outputs to the track mixer.
    /// In the initial version this is the same as `entryNode`.
    private(set) var exitNode: AVAudioNode?

    init(engineHost: EngineHost = .shared) {
        self.engineHost = engineHost
    }

    /// Returns true if the chain currently has no effects.
    var isEmpty: Bool {
        entryNode == nil && exitNode == nil
    }

    /// Attach and connect the chain between a source and destination.
    /// In the first version, this simply passes audio through unchanged.
    func connect(source: AVAudioNode, to destination: AVAudioNode, format: AVAudioFormat? = nil) {
        let resolvedFormat = format ?? engineHost.mainOutputFormat()

        // No effects yet: direct connection.
        engineHost.connect(source: source, to: destination, format: resolvedFormat)

        entryNode = source
        exitNode = destination
    }

    /// Disconnect the current chain from the engine.
    /// Safe to call multiple times.
    func disconnect() {
        if let entryNode {
            engineHost.disconnect(node: entryNode)
        }

        if let exitNode, exitNode !== entryNode {
            engineHost.disconnect(node: exitNode)
        }

        entryNode = nil
        exitNode = nil
    }
}
