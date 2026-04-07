//
//  LowPassFilterController.swift
//  Sleep
//

import Foundation
import AVFoundation

/// Modular low-pass filter wrapper for one track.
/// Keeps filter-specific logic out of PlayerService.
final class LowPassFilterController {
    private let engineHost: EngineHost

    /// EQ node used to implement a low-pass filter.
    private(set) lazy var filterNode = AVAudioUnitEQ(numberOfBands: 1)

    /// Whether the filter is currently enabled.
    private(set) var isEnabled: Bool = true

    /// The low-pass band configuration.
    private var lowPassBand: AVAudioUnitEQFilterParameters {
        filterNode.bands[0]
    }

    init(engineHost: EngineHost = .shared) {
        self.engineHost = engineHost
        configureFilter()
    }

    private func configureFilter() {
        let band = lowPassBand
        band.filterType = .lowPass
        band.frequency = 500.0
        band.bandwidth = 0.5
        band.bypass = false
        isEnabled = true
    }

    /// Attach the filter to the engine once.
    func attach() {
        engineHost.attach(node: filterNode)
    }

    /// Detach the filter from the engine.
    func detach() {
        engineHost.disconnect(node: filterNode)
        engineHost.detach(node: filterNode)
    }

    /// Connect source -> filter -> destination.
    func connect(source: AVAudioNode, to destination: AVAudioNode, format: AVAudioFormat? = nil) {
        let resolvedFormat = format ?? engineHost.mainOutputFormat()
        engineHost.connect(source: source, to: filterNode, format: resolvedFormat)
        engineHost.connect(source: filterNode, to: destination, format: resolvedFormat)
    }

    /// Update the cutoff frequency in realtime.
    func setCutoff(_ frequency: Float) {
        lowPassBand.frequency = max(20, min(frequency, 20_000))
    }

    /// Update resonance / bandwidth-ish behavior.
    /// AVAudioUnitEQ uses bandwidth rather than true resonance.
    func setBandwidth(_ bandwidth: Float) {
        lowPassBand.bandwidth = max(0.05, bandwidth)
    }

    /// Enable or bypass the filter.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        lowPassBand.bypass = !enabled
    }
}
