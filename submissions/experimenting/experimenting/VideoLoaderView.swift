import SwiftUI
import AVKit

struct VideoLoaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var authManager: AuthManager

    @State private var player: AVPlayer?
    @State private var playerItem: AVPlayerItem?
    @State private var showContentView = false

    var body: some View {
        Group {
            if showContentView {
                ContentView(authManager: authManager)
            } else {
                ZStack {
                    Color("intro")
                        .ignoresSafeArea()

                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(width: 480, height: 270)
                            .cornerRadius(12)
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                            .offset(x: 16, y: -45)
                    } else {
                        ProgressView()
                            .tint(.gray)
                    }
                }
                .onAppear { setupVideo() }
                .onChange(of: colorScheme) { _ in
                    guard !showContentView else { return }
                    reloadVideoForTheme()
                }
                .onDisappear { cleanup() }
            }
        }
    }

    private func setupVideo() {
        let baseName = (colorScheme == .dark) ? "darkfindly" : "findly"

        guard let url = Bundle.main.url(forResource: baseName, withExtension: "mp4") else {
            print("cant find ts file:  \(baseName).mp4 in bundle. (Scheme: \(colorScheme == .dark ? "dark" : "light"))")

            if colorScheme == .dark,
               let fallback = Bundle.main.url(forResource: "findly", withExtension: "mp4") {
                print("using og findly.mp4")
                startPlayer(with: fallback)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showContentView = true
                }
            }
            return
        }

        print("loading video: \(baseName).mp4")
        startPlayer(with: url)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !showContentView {
                withAnimation { showContentView = true }
            }
        }
    }

    private func startPlayer(with url: URL) {
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
    }

    private func reloadVideoForTheme() {
        cleanup()
        setupVideo()
    }

    private func cleanup() {
        player?.pause()
        player = nil
        playerItem = nil
    }
}
