import SwiftUI
import WebKit

struct ContentView: View {
    @State private var volume: Double = 100

    var body: some View {
        ZStack(alignment: .bottom) {
            WebView(volume: $volume)
                .ignoresSafeArea(.all)

            VolumeControl(volume: $volume)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
        }
        .ignoresSafeArea(.all)
        .background(Color.black)
    }
}

private struct VolumeControl: View {
    @Binding var volume: Double

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Text("Volume \(Int(volume))%")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("500%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Slider(value: $volume, in: 0...500, step: 1)
                .tint(.white)

            HStack {
                Text("0%")
                Spacer()
                Text("100%")
                Spacer()
                Text("500%")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 0.5)
        )
        .shadow(radius: 10)
    }
}

struct WebView: UIViewRepresentable {
    @Binding var volume: Double

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let userContentController = WKUserContentController()

        if let jsURL = Bundle.main.url(forResource: "AudioBoost", withExtension: "js"),
           let js = try? String(contentsOf: jsURL, encoding: .utf8) {
            let script = WKUserScript(
                source: js,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
            userContentController.addUserScript(script)
        }

        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.allowsBackForwardNavigationGestures = true

        context.coordinator.webView = webView
        webView.load(URLRequest(url: URL(string: "https://asmr.one")!))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let value = max(0, min(volume, 500))
        let js = "window.VolumeBoost500 && window.VolumeBoost500.setVolume(\(value / 100.0));"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        weak var webView: WKWebView?

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            webView.evaluateJavaScript(
                "window.VolumeBoost500 && window.VolumeBoost500.setVolume(1.0);",
                completionHandler: nil
            )
        }
    }
}
