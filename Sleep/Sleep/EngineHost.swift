//
//  EngineHost.swift
//  Sleep
//
//  Created by Ryan Ortiz on 3/23/26.
//

import Foundation
import AVFoundation

/// Owns AVAudioEngine and provides basic attach/connect helpers.
/// Keep this as the single source of truth for engine lifecycle.


// This class is the audio graph manager
//it owns and runs the node graph
// it doesnt decide which nodes to create or connect, just provides helpers for those operations and starts the engine when needed
//
final class EngineHost {
    static let shared = EngineHost()

    let engine = AVAudioEngine()

    private init() {
        // Optionally tune engine here (e.g., manual rendering config later).
    }

    /// Start the engine. Call after session activation.
    func startEngine() throws {
        if engine.isRunning { return }
        do {
            try engine.start()
        } catch {
            print("EngineHost: engine.start() failed: \(error)")
            throw error
        }
    }

    func stopEngine() {
        if engine.isRunning {
            engine.stop()
        }
    }

    /// Attach node to engine (convenience).
    func attach(node: AVAudioNode) {
        engine.attach(node)
    }

    /// Detach node from engine (convenience).
    func detach(node: AVAudioNode) {
        engine.detach(node)
    }

    /// Connect source -> destination with optional format; if nil, uses mainMixer output format.
    /// Connects one audio node to another in the engine graph.
/// - Parameters:
///   - source: The node producing audio.
///   - destination: The node receiving audio.
///   - format: Optional audio format for the connection. If nil, the engine falls back to the
///     main mixer’s output format. This lets other classes choose which mixer or effect node to
///     route into, while keeping a safe default path to the main mixer when no custom destination
///     is provided.
    func connect(source: AVAudioNode, to destination: AVAudioNode, format: AVAudioFormat? = nil) {
        let fmt = format ?? engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(source, to: destination, format: fmt)
    }

    /// Disconnect node (all connections).
    func disconnect(node: AVAudioNode) {
        engine.disconnectNodeOutput(node)
        engine.disconnectNodeInput(node)
    }

    /// Convenience main output format
    func mainOutputFormat() -> AVAudioFormat {
        return engine.mainMixerNode.outputFormat(forBus: 0)
    }
}
