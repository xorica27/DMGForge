import AppKit
import Foundation
import UniformTypeIdentifiers

public enum PreviewRenderError: Error, Equatable, CustomStringConvertible, LocalizedError {
    case missingCustomImage(path: String)
    case cannotCreatePNG

    public var description: String {
        switch self {
        case .missingCustomImage(let path):
            "Custom background image does not exist: \(path)"
        case .cannotCreatePNG:
            "Could not render preview PNG."
        }
    }

    public var errorDescription: String? {
        description
    }
}

public struct PreviewRenderer {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func render(project: DMGProject, to outputURL: URL) throws {
        try render(project: project, to: outputURL, includesFinderItems: true)
    }

    public func renderBackground(project: DMGProject, to outputURL: URL) throws {
        try render(project: project, to: outputURL, includesFinderItems: false)
    }

    private func render(project: DMGProject, to outputURL: URL, includesFinderItems: Bool) throws {
        try fileManager.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let image = try renderedImage(for: project, includesFinderItems: includesFinderItems)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw PreviewRenderError.cannotCreatePNG
        }
        try pngData.write(to: outputURL)
    }

    private func renderedImage(for project: DMGProject, includesFinderItems: Bool) throws -> NSImage {
        let size = NSSize(width: project.window.width, height: project.window.height)
        let image = NSImage(size: size)
        let bounds = NSRect(origin: .zero, size: size)

        image.lockFocus()
        switch project.background.mode {
        case .generated:
            drawBackground(in: bounds)
        case .image:
            try drawCustomBackground(for: project, in: bounds)
        }

        drawProjectCopy(for: project, in: bounds)

        if includesFinderItems {
            drawFinderItems(for: project)
        }
        image.unlockFocus()

        return image
    }

    private func drawProjectCopy(for project: DMGProject, in bounds: NSRect) {
        let size = bounds.size
        drawCentered(
            project.background.title,
            rect: NSRect(x: 120, y: size.height - 75, width: size.width - 240, height: 26),
            font: NSFont.systemFont(ofSize: 17, weight: .semibold),
            color: NSColor(calibratedRed: 0.20, green: 0.22, blue: 0.26, alpha: 1)
        )
        drawCentered(
            project.background.description,
            rect: NSRect(x: 90, y: size.height - 105, width: size.width - 180, height: 22),
            font: NSFont.systemFont(ofSize: 12, weight: .regular),
            color: NSColor(calibratedRed: 0.46, green: 0.48, blue: 0.54, alpha: 1)
        )
        if project.guideArrow.visible {
            let finderCenterY = CGFloat(project.layout.appIcon.y + project.layout.applicationsIcon.y) / 2
            drawArrow(
                centerY: size.height - finderCenterY + 22,
                arrow: project.guideArrow
            )
        }
        drawCentered(
            project.background.footer,
            rect: NSRect(x: 90, y: 38, width: size.width - 180, height: 18),
            font: NSFont.systemFont(ofSize: 11, weight: .regular),
            color: NSColor(calibratedRed: 0.52, green: 0.54, blue: 0.60, alpha: 1)
        )
    }

    private func drawCustomBackground(for project: DMGProject, in bounds: NSRect) throws {
        let imagePath = project.background.imagePath ?? ""
        guard fileManager.fileExists(atPath: imagePath),
              let image = NSImage(contentsOfFile: imagePath) else {
            throw PreviewRenderError.missingCustomImage(path: imagePath)
        }

        image.draw(
            in: bounds,
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1
        )
    }

    private func drawBackground(in bounds: NSRect) {
        NSColor(calibratedRed: 0.965, green: 0.968, blue: 0.976, alpha: 1).setFill()
        bounds.fill()

        let topLine = NSBezierPath()
        topLine.lineWidth = 1
        NSColor(calibratedWhite: 1, alpha: 0.75).setStroke()
        topLine.move(to: NSPoint(x: bounds.minX, y: bounds.maxY - 1))
        topLine.line(to: NSPoint(x: bounds.maxX, y: bounds.maxY - 1))
        topLine.stroke()
    }

    private func drawArrow(centerY: CGFloat, arrow: DMGGuideArrow) {
        let arrowColor = NSColor(hex: arrow.color) ?? NSColor(calibratedWhite: 0.267, alpha: 1)
        arrowColor.setStroke()
        let lineWidth = max(1, CGFloat(arrow.thickness))

        let arrowPath = NSBezierPath()
        arrowPath.lineWidth = lineWidth
        arrowPath.lineCapStyle = .round
        arrowPath.lineJoinStyle = .round
        arrowPath.move(to: NSPoint(x: 285, y: centerY))
        arrowPath.line(to: NSPoint(x: 395, y: centerY))
        arrowPath.stroke()

        let arrowHead = NSBezierPath()
        arrowHead.lineWidth = lineWidth
        arrowHead.lineCapStyle = .round
        arrowHead.lineJoinStyle = .round
        arrowHead.move(to: NSPoint(x: 370, y: centerY + 25))
        arrowHead.line(to: NSPoint(x: 395, y: centerY))
        arrowHead.line(to: NSPoint(x: 370, y: centerY - 25))
        arrowHead.stroke()
    }

    private func drawFinderItems(for project: DMGProject) {
        let appLabel = URL(fileURLWithPath: project.appPath).lastPathComponent
        drawFinderIcon(
            appIcon(for: project.appPath),
            label: appLabel.isEmpty ? "\(project.appName).app" : appLabel,
            center: project.layout.appIcon,
            canvasHeight: project.window.height
        )
        drawFinderIcon(
            NSWorkspace.shared.icon(forFile: "/Applications"),
            label: "Applications",
            center: project.layout.applicationsIcon,
            canvasHeight: project.window.height
        )

        if project.firstLaunchGuide.enabled {
            drawFinderIcon(
                fileIcon(forExtension: "inetloc"),
                label: project.firstLaunchGuide.securitySettingsShortcutName,
                center: project.firstLaunchGuide.securitySettingsIcon,
                canvasHeight: project.window.height
            )
            drawFinderIcon(
                fileIcon(forExtension: "txt"),
                label: project.firstLaunchGuide.helpFileName,
                center: project.firstLaunchGuide.helpFileIcon,
                canvasHeight: project.window.height
            )
        }
    }

    private func appIcon(for appPath: String) -> NSImage {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: appPath, isDirectory: &isDirectory) {
            return NSWorkspace.shared.icon(forFile: appPath)
        }

        return NSWorkspace.shared.icon(for: .applicationBundle)
    }

    private func fileIcon(forExtension fileExtension: String) -> NSImage {
        let contentType = UTType(filenameExtension: fileExtension) ?? .data
        return NSWorkspace.shared.icon(for: contentType)
    }

    private func drawFinderIcon(_ icon: NSImage, label: String, center point: DMGPoint, canvasHeight: Int) {
        let iconSize: CGFloat = 96
        let center = NSPoint(x: CGFloat(point.x), y: CGFloat(canvasHeight - point.y))
        let iconRect = NSRect(
            x: center.x - iconSize / 2,
            y: center.y - iconSize / 2,
            width: iconSize,
            height: iconSize
        )

        icon.draw(in: iconRect)

        drawLabelShadow(label, rect: NSRect(x: center.x - 76, y: iconRect.minY - 42, width: 152, height: 34))
    }

    private func drawLabelShadow(_ text: String, rect: NSRect) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byWordWrapping
        let font = NSFont.systemFont(ofSize: 12, weight: .regular)

        text.draw(
            in: rect.offsetBy(dx: 0, dy: -1),
            withAttributes: [
                .font: font,
                .foregroundColor: NSColor.white.withAlphaComponent(0.85),
                .paragraphStyle: style
            ]
        )
        text.draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.18, alpha: 1),
                .paragraphStyle: style
            ]
        )
    }

    private func drawCentered(_ text: String, rect: NSRect, font: NSFont, color: NSColor) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        text.draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style
            ]
        )
    }
}

private extension NSColor {
    convenience init?(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard raw.count == 6, let value = Int(raw, radix: 16) else {
            return nil
        }

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        self.init(calibratedRed: red, green: green, blue: blue, alpha: 0.95)
    }
}
