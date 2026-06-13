// Renders the Notchy logo as a PNG at the requested size.
// Usage: swift gen-icon.swift <size> <output.png>
//
// The mark is the product itself: a flat charcoal squircle with the
// signature notch hanging from the top edge and two status dots peeking
// out like eyes — a little face you glance at to read your agent.

import AppKit
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 3, let size = Int(args[1]) else {
    FileHandle.standardError.write("usage: gen-icon.swift <size-px> <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let outputPath = args[2]
let S = CGFloat(size)

// Palette (flat, no gradients).
let bgColor    = CGColor(red: 0.106, green: 0.118, blue: 0.149, alpha: 1) // #1b1e26
let notchColor = CGColor(red: 0,     green: 0,     blue: 0,     alpha: 1) // #000000
let eyeColor   = CGColor(red: 0.957, green: 0.957, blue: 0.961, alpha: 1) // #f4f4f5

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: Int(S),
    height: Int(S),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write("failed to create CGContext\n".data(using: .utf8)!)
    exit(1)
}

// Flip to a top-left origin so all geometry reads top-down.
ctx.translateBy(x: 0, y: S)
ctx.scaleBy(x: 1, y: -1)
ctx.interpolationQuality = .high

// MARK: Background — flat charcoal squircle.
let radius = S * 0.2237
let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: S, height: S),
                    cornerWidth: radius, cornerHeight: radius, transform: nil)
ctx.addPath(bgPath)
ctx.setFillColor(bgColor)
ctx.fillPath()

// MARK: The notch — flat top, rounded bottom corners, hanging from the top.
// Drawn as a fully-rounded rect whose top edge sits above the canvas, so the
// background clip shaves the top corners and leaves a flat top.
let nW = S * 0.58
let nX = (S - nW) / 2
let nBottom = S * 0.50
let nR = S * 0.13
let notchPath = CGPath(roundedRect: CGRect(x: nX, y: -nR, width: nW, height: nBottom + nR),
                       cornerWidth: nR, cornerHeight: nR, transform: nil)
ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()
ctx.addPath(notchPath)
ctx.setFillColor(notchColor)
ctx.fillPath()
ctx.restoreGState()

// MARK: Eyes — two flat status dots inside the notch.
let eyeR = S * 0.066
let eyeY = S * 0.255
for eyeX in [S * 0.5 - S * 0.125, S * 0.5 + S * 0.125] {
    ctx.setFillColor(eyeColor)
    ctx.fillEllipse(in: CGRect(x: eyeX - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2))
}

// MARK: Write PNG.
guard let image = ctx.makeImage() else {
    FileHandle.standardError.write("failed to create image\n".data(using: .utf8)!)
    exit(1)
}
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    FileHandle.standardError.write("failed to open destination\n".data(using: .utf8)!)
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
if !CGImageDestinationFinalize(dest) {
    FileHandle.standardError.write("failed to write png\n".data(using: .utf8)!)
    exit(1)
}
print("wrote \(outputPath) (\(size)x\(size))")
