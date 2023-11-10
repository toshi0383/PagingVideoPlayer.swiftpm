import AVKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { proxy in
            PagedScrollView {
                LazyHStack(spacing: 0) {
                    ForEach(0...3, id: \.self) { index in
                        VideoPlayerView(videoURL: URL(string: "https://your_video_url_here\(index)")!)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
            }
        }
    }
}

struct VideoPlayerView: View {
    var videoURL: URL
    private var player: AVPlayer

    init(videoURL: URL) {
        self.videoURL = videoURL
        self.player = AVPlayer(url: videoURL)
    }

    var body: some View {
        VStack {
            VideoPlayer(player: player)
            Button("Play") {
                player.play() // 再生ボタン
            }
        }
        .onScrollPageChanged { isAppeared in
            if !isAppeared {
                player.pause()
                print("pause: \(Date()) \(videoURL)")
            }
        }
    }
}

extension View {
    func onScrollPageChanged(onAppearOrDisappear: @escaping (Bool) -> Void) -> some View {
        modifier(ScrollViewOffsetModifier(onAppearOrDisappear: onAppearOrDisappear))
    }
}

struct ScrollViewOffsetModifier: ViewModifier {
    var onAppearOrDisappear: (Bool) -> Void
    @State var isMinXLessThanThreshold: Bool?
    @State var isMaxXGreaterThanThreshold: Bool?
    @State var isOnScreenAndNotFired = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ViewMinMaxXKey.self,
                        value: .init(minX: proxy.frame(in: .global).minX, maxX: proxy.frame(in: .global).maxX)
                    )
                }
            )
            .onPreferenceChange(ViewMinMaxXKey.self) { m in
                let threshold = (m.maxX - m.minX) / 2
                let wasMinXLessThanThreshold = isMinXLessThanThreshold
                let wasMaxXGreaterThanThreshold = isMaxXGreaterThanThreshold
                isMinXLessThanThreshold = m.minX < threshold
                isMaxXGreaterThanThreshold = m.maxX > threshold

                if let wasMinXLessThanThreshold, wasMinXLessThanThreshold != isMinXLessThanThreshold {
                    onAppearOrDisappear(!wasMinXLessThanThreshold)
                } else if let wasMaxXGreaterThanThreshold, wasMaxXGreaterThanThreshold != isMaxXGreaterThanThreshold {
                    onAppearOrDisappear(!wasMaxXGreaterThanThreshold)
                }
            }
    }

    private struct ViewMinMaxXKey: PreferenceKey {
        struct Value: Equatable {
            let minX: CGFloat
            let maxX: CGFloat
            static var zero: Value = .init(minX: 0, maxX: 0)
        }
        static var defaultValue: Value = .zero
        static func reduce(value: inout Value, nextValue: () -> Value) {
            let n = nextValue()
            value = .init(minX: value.minX + n.minX, maxX: value.maxX + n.maxX)
        }
    }

}

struct PagedScrollView<Content: View>: UIViewRepresentable {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        let hostView = UIHostingController(rootView: content)
        hostView.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hostView.view)
        hostView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostView.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostView.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostView.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostView.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {}
}
