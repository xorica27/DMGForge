import AppKit
import Foundation
import Testing
@testable import DMGForgeCore

@Test func generatedPreviewWritesPNG() throws {
    let tempRoot = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let outputURL = tempRoot.appendingPathComponent("preview.png")

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )

    try PreviewRenderer().render(project: project, to: outputURL)

    let data = try Data(contentsOf: outputURL)
    #expect(data.starts(with: [0x89, 0x50, 0x4E, 0x47]))
    #expect(data.count > 1_000)
}

@Test func generatedPreviewDrawsAppIconAtConfiguredPosition() throws {
    let tempRoot = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let outputURL = tempRoot.appendingPathComponent("preview.png")

    var project = DMGProjectFactory.makeDefault(
        appPath: tempRoot.appendingPathComponent("NoIcon.app", isDirectory: true).path,
        appName: "NoIcon",
        version: "1.0.0"
    )
    project.layout.appIcon = DMGPoint(x: 180, y: 198)

    try PreviewRenderer().render(project: project, to: outputURL)

    let image = NSImage(contentsOf: outputURL)
    let tiffData = try #require(image?.tiffRepresentation)
    let bitmap = try #require(NSBitmapImageRep(data: tiffData))
    let scale = bitmap.pixelsWide / project.window.width
    let centerX = project.layout.appIcon.x * scale
    let centerY = (project.window.height - project.layout.appIcon.y) * scale
    let changedPixels = countNonBackgroundPixels(
        in: bitmap,
        xRange: (centerX - 50 * scale)..<(centerX + 50 * scale),
        yRange: (centerY - 50 * scale)..<(centerY + 50 * scale)
    )

    #expect(changedPixels > 300)
}

@Test func imageBackgroundRenderOverlaysProjectCopyOnCustomBackground() throws {
    let tempRoot = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let sourceURL = tempRoot.appendingPathComponent("source.png")
    let outputURL = tempRoot.appendingPathComponent("preview.png")
    let backgroundColor = NSColor(calibratedRed: 0.25, green: 0.72, blue: 0.82, alpha: 1)
    try makeSolidPNG(color: backgroundColor, size: NSSize(width: 680, height: 420), outputURL: sourceURL)

    var project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    project.background = DMGBackground(
        mode: .image,
        imagePath: sourceURL.path,
        title: "Install MyApp",
        description: "Drag MyApp into Applications.",
        footer: "Signed and ready."
    )

    try PreviewRenderer().renderBackground(project: project, to: outputURL)

    let outputImage = NSImage(contentsOf: outputURL)
    let tiffData = try #require(outputImage?.tiffRepresentation)
    let bitmap = try #require(NSBitmapImageRep(data: tiffData))
    let scale = bitmap.pixelsWide / project.window.width
    let sampledBackground = try #require(bitmap.colorAt(x: 10, y: 10))
    let copyPixels = countPixelsDifferentFrom(
        sampledBackground,
        in: bitmap,
        xRange: 80 * scale..<600 * scale,
        yRange: 70 * scale..<140 * scale
    )

    #expect(copyPixels > 100)
}

@Test func generatedBackgroundDrawsDefaultDarkGreyArrow() throws {
    let tempRoot = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let outputURL = tempRoot.appendingPathComponent("preview.png")

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )

    try PreviewRenderer().renderBackground(project: project, to: outputURL)

    let outputImage = NSImage(contentsOf: outputURL)
    let tiffData = try #require(outputImage?.tiffRepresentation)
    let bitmap = try #require(NSBitmapImageRep(data: tiffData))
    let scale = bitmap.pixelsWide / project.window.width
    let arrowPixels = countDarkGreyArrowPixels(
        in: bitmap,
        xRange: 270 * scale..<410 * scale,
        yRange: 180 * scale..<260 * scale
    )

    #expect(arrowPixels > 100)
}

@Test func generatedBackgroundSkipsArrowWhenGuideArrowIsHidden() throws {
    let tempRoot = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let outputURL = tempRoot.appendingPathComponent("preview.png")

    var project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    project.guideArrow.visible = false

    try PreviewRenderer().renderBackground(project: project, to: outputURL)

    let outputImage = NSImage(contentsOf: outputURL)
    let tiffData = try #require(outputImage?.tiffRepresentation)
    let bitmap = try #require(NSBitmapImageRep(data: tiffData))
    let scale = bitmap.pixelsWide / project.window.width
    let arrowPixels = countDarkGreyArrowPixels(
        in: bitmap,
        xRange: 270 * scale..<410 * scale,
        yRange: 180 * scale..<260 * scale
    )

    #expect(arrowPixels == 0)
}

private func makeTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makeSolidPNG(color: NSColor, size: NSSize, outputURL: URL) throws {
    let image = NSImage(size: size)
    image.lockFocus()
    color.setFill()
    NSRect(origin: .zero, size: size).fill()
    image.unlockFocus()

    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    try pngData.write(to: outputURL)
}

private func countNonBackgroundPixels(
    in bitmap: NSBitmapImageRep,
    xRange: Range<Int>,
    yRange: Range<Int>
) -> Int {
    var count = 0

    for x in xRange {
        for y in yRange {
            guard let color = bitmap.colorAt(x: x, y: y) else { continue }
            if abs(color.redComponent - 0.965) > 0.02 ||
                abs(color.greenComponent - 0.968) > 0.02 ||
                abs(color.blueComponent - 0.976) > 0.02 {
                count += 1
            }
        }
    }

    return count
}

private func countPixelsDifferentFrom(
    _ expected: NSColor,
    in bitmap: NSBitmapImageRep,
    xRange: Range<Int>,
    yRange: Range<Int>
) -> Int {
    let expectedRGB = expected.usingColorSpace(.deviceRGB) ?? expected
    var count = 0

    for x in xRange {
        for y in yRange {
            guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
            if abs(color.redComponent - expectedRGB.redComponent) > 0.02 ||
                abs(color.greenComponent - expectedRGB.greenComponent) > 0.02 ||
                abs(color.blueComponent - expectedRGB.blueComponent) > 0.02 {
                count += 1
            }
        }
    }

    return count
}

private func countDarkGreyArrowPixels(
    in bitmap: NSBitmapImageRep,
    xRange: Range<Int>,
    yRange: Range<Int>
) -> Int {
    var count = 0

    for x in xRange {
        for y in yRange {
            guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
            if color.redComponent > 0.35 && color.redComponent < 0.58 &&
                color.greenComponent > 0.35 && color.greenComponent < 0.58 &&
                color.blueComponent > 0.35 && color.blueComponent < 0.58 {
                count += 1
            }
        }
    }

    return count
}
