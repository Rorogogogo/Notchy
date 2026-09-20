import SwiftUI

// MARK: - Claude crab icon (pixel-art, ported from Vibe Notch's ClaudeCrabIcon)

struct ClaudeCrabIcon: View {
    var size: CGFloat = 14
    var color: Color = Color(red: 0.85, green: 0.47, blue: 0.34)
    // nil punches the eyes out of the body so whatever sits behind shows through,
    // which is what a tinted menu bar icon needs.
    var eyeColor: Color? = .black

    private static let aspect: CGFloat = 66.0 / 52.0

    var body: some View {
        Canvas { ctx, canvasSize in
            let scale = canvasSize.height / 52.0

            func scaled(_ rect: CGRect) -> Path {
                Path(rect).applying(CGAffineTransform(scaleX: scale, y: scale))
            }

            // Antennae
            ctx.fill(scaled(CGRect(x: 0,  y: 13, width: 6, height: 13)), with: .color(color))
            ctx.fill(scaled(CGRect(x: 60, y: 13, width: 6, height: 13)), with: .color(color))

            // Legs (static, no walking animation)
            for x in [CGFloat(6), 18, 42, 54] {
                ctx.fill(scaled(CGRect(x: x, y: 39, width: 6, height: 13)), with: .color(color))
            }

            // Body
            ctx.fill(scaled(CGRect(x: 6, y: 0, width: 54, height: 39)), with: .color(color))

            // Eyes
            let eyes = [CGRect(x: 12, y: 13, width: 6, height: 6.5), CGRect(x: 48, y: 13, width: 6, height: 6.5)]
            if let eyeColor {
                for eye in eyes { ctx.fill(scaled(eye), with: .color(eyeColor)) }
            } else {
                ctx.blendMode = .destinationOut
                for eye in eyes { ctx.fill(scaled(eye), with: .color(.black)) }
            }
        }
        .frame(width: size * Self.aspect, height: size)
        .accessibilityLabel("Claude")
    }
}
