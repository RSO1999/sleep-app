//
//  TrackEffectChain.swift
//  Sleep
//
//  Created by Copilot on 2026-04-06.
//

import Foundation
import AVFoundation

/// Modular per-track effect layer.
/// Keeps PlayerService focused on playback only.
/// Effects can be added here without tightly coupling them to PlayerService.
final class TrackEffectChain {
    private let engineHost: EngineHost

    /// Optional low-pass controller for the first effect in the chain.
    private var lowPassController: LowPassFilterController?

    /// The node that receives audio from the player or previous stage.
    private(set) var entryNode: AVAudioNode?

    /// The node that outputs into the track mixer.
    private(set) var exitNode: AVAudioNode?

    init(engineHost: EngineHost = .shared) {
        self.engineHost = engineHost
    }

    /// Returns true if the chain currently has no effects.
    var isEmpty: Bool {
        lowPassController == nil
    }

    /// Attach the chain nodes to the engine.
    func attach() {
        lowPassController?.attach()
    }

    /// Detach the chain nodes from the engine.
    func detach() {
        lowPassController?.detach()
        lowPassController = nil
        entryNode = nil
        exitNode = nil
    }

    /// Configure a low-pass effect for this chain.
    /// If the controller does not exist yet, it is created and attached.
    func enableLowPass(cutoff: Float = 200, bandwidth: Float = 0.5) {
        if lowPassController == nil {
            lowPassController = LowPassFilterController(engineHost: engineHost)
            lowPassController?.attach()
        }

        lowPassController?.setCutoff(cutoff)
        lowPassController?.setBandwidth(bandwidth)
        lowPassController?.setEnabled(true)
    }

    /// Disable the low-pass effect but keep the chain object alive.
    func disableLowPass() {
        lowPassController?.setEnabled(false)
    }

    /// Connect the chain between a source and destination.
    /// If the low-pass effect is enabled, the source is routed through it first.
    func connect(source: AVAudioNode, to destination: AVAudioNode, format: AVAudioFormat? = nil) {
        let resolvedFormat = format ?? engineHost.mainOutputFormat()

        if let lowPassController {
            lowPassController.connect(source: source, to: destination, format: resolvedFormat)
            entryNode = source
            exitNode = destination
        } else {
            // Pass-through if no effects are enabled.
            engineHost.connect(source: source, to: destination, format: resolvedFormat)
            entryNode = source
            exitNode = destination
        }
    }

    /// Disconnect the current chain from the engine.
    /// Safe to call multiple times.
    func disconnect() {
        if let lowPassController {
            lowPassController.detach()
        }

        if let entryNode {
            engineHost.disconnect(node: entryNode)
        }

        if let exitNode, exitNode !== entryNode {
            engineHost.disconnect(node: exitNode)
        }

        entryNode = nil
        exitNode = nil
    }

    /// Forward live low-pass cutoff updates.
    func setLowPassCutoff(_ frequency: Float) {
        lowPassController?.setCutoff(frequency)
    }

    /// Forward live low-pass enable/disable updates.
    func setLowPassEnabled(_ enabled: Bool) {
        if enabled {
            lowPassController?.setEnabled(true)
        } else {
            lowPassController?.setEnabled(false)
        }
    }
}
