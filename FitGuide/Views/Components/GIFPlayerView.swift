import SwiftUI
import ImageIO
import UIKit

struct GIFPlayerView: UIViewRepresentable {
    let url: URL
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = contentMode
        iv.backgroundColor = .clear
        return iv
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
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
        if images != uiView.animationImages {
            uiView.animationImages = images
            uiView.animationDuration = totalDuration > 0 ? totalDuration : 0.1 * Double(max(count, 1))
            uiView.animationRepeatCount = 0
            uiView.startAnimating()
        }
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