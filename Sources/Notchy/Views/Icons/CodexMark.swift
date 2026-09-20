import AppKit
import SwiftUI

struct CodexMark: View {
    var size: CGFloat = 16
    // nil keeps the mark's own artwork colour; a tint renders it as a template.
    var color: Color?

    private static let cachedImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "codex", withExtension: "svg"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.isTemplate = false
        // The SVG is authored at 20pt; rasterising from that up to a tinted
        // menu bar icon blurs, so give the vector rep a larger nominal size.
        image.size = NSSize(width: 128, height: 128)
        return image
    }()

    var body: some View {
        Group {
            if let codexImage = Self.cachedImage {
                if let color {
                    Image(nsImage: codexImage)
                        .resizable()
                        .interpolation(.high)
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(color)
                } else {
                    Image(nsImage: codexImage)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                }
            } else {
                Text("C")
                    .font(.system(size: size * 0.7, weight: .bold, design: .rounded))
                    .foregroundStyle(color ?? .primary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Codex")
    }
}
