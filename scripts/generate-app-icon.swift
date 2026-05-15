#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = CommandLine.arguments.dropFirst().first.map {
    URL(fileURLWithPath: $0)
} ?? repoRoot.appendingPathComponent("Sources/DMGForge/Resources", isDirectory: true)

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

let svg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-label="DMGForge app icon">
  <defs>
    <linearGradient id="background" x1="512" y1="0" x2="512" y2="1024" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#08B7F0"/>
      <stop offset="0.46" stop-color="#098FE8"/>
      <stop offset="1" stop-color="#075CE7"/>
    </linearGradient>
    <radialGradient id="glow" cx="512" cy="220" r="720" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#3BD8FF" stop-opacity="0.7"/>
      <stop offset="0.55" stop-color="#0A94EA" stop-opacity="0.1"/>
      <stop offset="1" stop-color="#075CE7" stop-opacity="0"/>
    </radialGradient>
    <filter id="softShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="28" stdDeviation="22" flood-color="#003D91" flood-opacity="0.45"/>
    </filter>
    <linearGradient id="stroke" x1="300" y1="130" x2="760" y2="890" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#FFFFFF"/>
      <stop offset="0.55" stop-color="#F8FBFF"/>
      <stop offset="1" stop-color="#EAF5FF"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="1024" rx="190" fill="url(#background)"/>
  <rect width="1024" height="1024" rx="190" fill="url(#glow)"/>
  <g transform="translate(92 92) scale(0.82)">
    <g filter="url(#softShadow)" fill="none" stroke="url(#stroke)" stroke-width="72" stroke-linecap="round" stroke-linejoin="round">
      <path d="M488 164H608L784 340L850 274L930 354L864 420L944 500V612L894 662"/>
      <path d="M536 860H416L240 684L174 750L94 670L160 604L80 524V412L130 362"/>
      <path d="M318 640L534 424"/>
      <path d="M706 384L490 600"/>
    </g>
    <rect x="810" y="302" width="78" height="78" rx="14" transform="rotate(45 849 341)" fill="#0A91E8"/>
    <rect x="136" y="644" width="78" height="78" rx="14" transform="rotate(45 175 683)" fill="#0870E7"/>
  </g>
</svg>
"""

try svg.write(
    to: resourcesURL.appendingPathComponent("AppIcon.svg"),
    atomically: true,
    encoding: .utf8
)

func drawCable(_ context: CGContext, points: [CGPoint], width: CGFloat) {
    guard let first = points.first else { return }
    context.beginPath()
    context.move(to: first)
    for point in points.dropFirst() {
        context.addLine(to: point)
    }
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setLineWidth(width)
    context.setStrokeColor(NSColor.white.cgColor)
    context.setShadow(
        offset: CGSize(width: 0, height: 28),
        blur: 24,
        color: NSColor(calibratedRed: 0.0, green: 0.19, blue: 0.48, alpha: 0.42).cgColor
    )
    context.strokePath()

    context.beginPath()
    context.move(to: first)
    for point in points.dropFirst() {
        context.addLine(to: point)
    }
    context.setShadow(offset: .zero, blur: 0, color: nil)
    context.setStrokeColor(NSColor(calibratedWhite: 0.985, alpha: 1).cgColor)
    context.setLineWidth(width * 0.86)
    context.strokePath()
}

func drawIcon(size: Int) -> NSImage {
    let canvas = CGFloat(size)
    let image = NSImage(size: CGSize(width: canvas, height: canvas))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    context.saveGState()
    context.scaleBy(x: canvas / 1024, y: canvas / 1024)
    context.translateBy(x: 0, y: 1024)
    context.scaleBy(x: 1, y: -1)

    let bounds = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let backgroundPath = CGPath(
        roundedRect: bounds,
        cornerWidth: 190,
        cornerHeight: 190,
        transform: nil
    )
    context.addPath(backgroundPath)
    context.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let backgroundGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            NSColor(calibratedRed: 0.03, green: 0.72, blue: 0.94, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.03, green: 0.55, blue: 0.91, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.03, green: 0.36, blue: 0.91, alpha: 1).cgColor
        ] as CFArray,
        locations: [0, 0.46, 1]
    )!
    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: 512, y: 0),
        end: CGPoint(x: 512, y: 1024),
        options: []
    )

    let glowGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            NSColor(calibratedRed: 0.23, green: 0.85, blue: 1, alpha: 0.45).cgColor,
            NSColor(calibratedRed: 0.03, green: 0.55, blue: 0.91, alpha: 0).cgColor
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        glowGradient,
        startCenter: CGPoint(x: 512, y: 220),
        startRadius: 0,
        endCenter: CGPoint(x: 512, y: 220),
        endRadius: 720,
        options: [.drawsAfterEndLocation]
    )

    context.saveGState()
    context.translateBy(x: 512, y: 512)
    context.scaleBy(x: 0.82, y: 0.82)
    context.translateBy(x: -512, y: -512)

    drawCable(context, points: [
        CGPoint(x: 488, y: 164),
        CGPoint(x: 608, y: 164),
        CGPoint(x: 784, y: 340),
        CGPoint(x: 850, y: 274),
        CGPoint(x: 930, y: 354),
        CGPoint(x: 864, y: 420),
        CGPoint(x: 944, y: 500),
        CGPoint(x: 944, y: 612),
        CGPoint(x: 894, y: 662)
    ], width: 72)

    drawCable(context, points: [
        CGPoint(x: 536, y: 860),
        CGPoint(x: 416, y: 860),
        CGPoint(x: 240, y: 684),
        CGPoint(x: 174, y: 750),
        CGPoint(x: 94, y: 670),
        CGPoint(x: 160, y: 604),
        CGPoint(x: 80, y: 524),
        CGPoint(x: 80, y: 412),
        CGPoint(x: 130, y: 362)
    ], width: 72)

    drawCable(context, points: [
        CGPoint(x: 318, y: 640),
        CGPoint(x: 534, y: 424)
    ], width: 72)

    drawCable(context, points: [
        CGPoint(x: 706, y: 384),
        CGPoint(x: 490, y: 600)
    ], width: 72)

    context.setShadow(offset: .zero, blur: 0, color: nil)
    context.setFillColor(NSColor(calibratedRed: 0.04, green: 0.57, blue: 0.91, alpha: 1).cgColor)
    context.saveGState()
    context.translateBy(x: 849, y: 341)
    context.rotate(by: .pi / 4)
    context.fill(CGRect(x: -39, y: -39, width: 78, height: 78))
    context.restoreGState()

    context.setFillColor(NSColor(calibratedRed: 0.03, green: 0.44, blue: 0.91, alpha: 1).cgColor)
    context.saveGState()
    context.translateBy(x: 175, y: 683)
    context.rotate(by: .pi / 4)
    context.fill(CGRect(x: -39, y: -39, width: 78, height: 78))
    context.restoreGState()

    context.restoreGState()

    context.restoreGState()
    image.unlockFocus()
    return image
}

func writePNG(size: Int, name: String, to directory: URL) throws {
    let image = drawIcon(size: size)
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }
    try data.write(to: directory.appendingPathComponent(name))
}

let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconFiles: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for (size, name) in iconFiles {
    try writePNG(size: size, name: name, to: iconsetURL)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c", "icns",
    iconsetURL.path,
    "-o", resourcesURL.appendingPathComponent("AppIcon.icns").path
]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw CocoaError(.fileWriteUnknown)
}

try? FileManager.default.removeItem(at: iconsetURL)
print("Wrote \(resourcesURL.appendingPathComponent("AppIcon.svg").path)")
print("Wrote \(resourcesURL.appendingPathComponent("AppIcon.icns").path)")
