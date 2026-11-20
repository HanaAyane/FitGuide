import SwiftUI
import ImageIO
import UIKit

struct GIFPlayerView: UIViewRepresentable {
    let url: URL
    var contentMode: UIView.ContentMode = .scaleAspectFit

    final class Coordinator {
        var loadedURL: URL?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = contentMode
        iv.backgroundColor = .clear
        return iv
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.contentMode = contentMode
        guard context.coordinator.loadedURL != url else { return }

        uiView.stopAnimating()
        uiView.animationImages = nil
        uiView.image = nil

        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
        let count = CGImageSourceGetCount(src)
        guard count > 0 else { return }
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0
        for i in 0..<count {
            guard let cg = CGImageSourceCreateImageAtIndex(src, i, nil) else { continue }
            let dur = frameDuration(at: i, src: src)
            images.append(UIImage(cgImage: cg))
            totalDuration += dur
        }
        guard !images.isEmpty else { return }
        uiView.animationImages = images
        uiView.animationDuration = totalDuration > 0
            ? totalDuration
            : 0.1 * Double(max(count, 1))
        uiView.animationRepeatCount = 0
        uiView.startAnimating()
        context.coordinator.loadedURL = url
    }

    static func dismantleUIView(_ uiView: UIImageView, coordinator: Coordinator) {
        uiView.stopAnimating()
        uiView.animationImages = nil
        uiView.image = nil
        coordinator.loadedURL = nil
    }

    private func frameDuration(at index: Int, src: CGImageSource) -> TimeInterval {
        let opts = CGImageSourceCopyPropertiesAtIndex(src, index, nil) as? [CFString: Any] ?? [:]
        if let gifProps = opts[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
            if let d = gifProps[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval, d > 0 {
                return d
            }
            if let d = gifProps[kCGImagePropertyGIFDelayTime] as? TimeInterval {
                return d
            }
        }
        return 0.1
    }
}
