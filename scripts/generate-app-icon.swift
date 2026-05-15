#!/usr/bin/env swift

import AppKit
import Foundation

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = repoRoot.appendingPathComponent("Sources/DMGForge/Resources", isDirectory: true)
let appIconPNG = resourcesURL.appendingPathComponent("AppIcon.png")
let appIconICNS = resourcesURL.appendingPathComponent("AppIcon.icns")

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

if CommandLine.arguments.count > 1 {
    let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
        fputs("Source PNG does not exist: \(sourceURL.path)\n", stderr)
        exit(1)
    }
    if sourceURL.standardizedFileURL != appIconPNG.standardizedFileURL {
        try? FileManager.default.removeItem(at: appIconPNG)
        try FileManager.default.copyItem(at: sourceURL, to: appIconPNG)
    }
}

guard FileManager.default.fileExists(atPath: appIconPNG.path) else {
    fputs("Missing source PNG: \(appIconPNG.path)\n", stderr)
    fputs("Usage: scripts/generate-app-icon.swift [/path/to/source.png]\n", stderr)
    exit(1)
}

guard let sourceImage = NSImage(contentsOf: appIconPNG) else {
    fputs("Could not read source PNG: \(appIconPNG.path)\n", stderr)
    exit(1)
}

func resizedPNG(size: Int) throws -> Data {
    let canvasSize = CGSize(width: size, height: size)
    let image = NSImage(size: canvasSize)

    image.lockFocus()
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: canvasSize).fill()
    sourceImage.draw(
        in: NSRect(origin: .zero, size: canvasSize),
        from: NSRect(origin: .zero, size: sourceImage.size),
        operation: .copy,
        fraction: 1,
        respectFlipped: false,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw CocoaError(.fileWriteUnknown)
    }

    return data
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
    try resizedPNG(size: size).write(to: iconsetURL.appendingPathComponent(name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", appIconICNS.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fputs("iconutil failed with status \(process.terminationStatus)\n", stderr)
    exit(process.terminationStatus)
}

try? FileManager.default.removeItem(at: iconsetURL)

print("Wrote \(appIconPNG.path)")
print("Wrote \(appIconICNS.path)")
