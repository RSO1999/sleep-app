import SwiftUI
import Foundation


struct ContentView: View {
    @State private var trackAdded = false

    var body: some View {
        VStack {
            Text("Now Playing: Music Title")
                .font(.title)
                .padding()

            HStack(spacing: 24) {
                Button(action: {
                    if !trackAdded {
                        // Add music.wav from bundle and schedule it
                        if let id = AudioCoordinator.shared.addTrackFromBundle(name: "music", ext: "wav") {
                            print("Added track id: \(id)")
                            trackAdded = true
                        } else {
                            print("Failed to add track from bundle")
                        }
                    }
                }) {
                    Text(trackAdded ? "Track Ready" : "Add Track")
                }

                Button(action: {
                    // Simple play/pause for all tracks
                    if trackAdded {
                        AudioCoordinator.shared.playAll()
                    }
                }) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                }

                Button(action: {
                    if trackAdded {
                        AudioCoordinator.shared.pauseAll()
                    }
                }) {
                    Image(systemName: "pause.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                }
            }
            .foregroundColor(.blue)
        }
        .onAppear {
            // ensure session/engine already started at app init; safe to call again
            AudioCoordinator.shared.startAudio()
        }
    }
}
