import AppKit
import Foundation

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
        try fileManager.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        switch project.background.mode {
        case .image:
            let imagePath = project.background.imagePath ?? ""
            guard fileManager.fileExists(atPath: imagePath) else {
                throw PreviewRenderError.missingCustomImage(path: imagePath)
            }

            if fileManager.fileExists(atPath: outputURL.path) {
                try fileManager.removeItem(at: outputURL)
            }
            try fileManager.copyItem(at: URL(fileURLWithPath: imagePath), to: outputURL)

        case .generated:
            let image = generatedImage(for: project)
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                throw PreviewRenderError.cannotCreatePNG
            }
            try pngData.write(to: outputURL)
        }
    }

    private func generatedImage(for project: DMGProject) -> NSImage {
        let size = NSSize(width: project.window.width, height: project.window.height)
        let image = NSImage(size: size)
        let bounds = NSRect(origin: .zero, size: size)

        image.lockFocus()
        drawBackground(in: bounds)
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
        drawArrow(centerY: CGFloat(project.layout.appIcon.y + project.layout.applicationsIcon.y) / 2 + 22)
        drawCentered(
            project.background.footer,
            rect: NSRect(x: 90, y: 38, width: size.width - 180, height: 18),
            font: NSFont.systemFont(ofSize: 11, weight: .regular),
            color: NSColor(calibratedRed: 0.52, green: 0.54, blue: 0.60, alpha: 1)
        )
        image.unlockFocus()

        return image
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

    private func drawArrow(centerY: CGFloat) {
        let arrowColor = NSColor(calibratedRed: 1, green: 0.16, blue: 0.25, alpha: 0.95)
        arrowColor.setStroke()

        let arrowPath = NSBezierPath()
        arrowPath.lineWidth = 7
        arrowPath.lineCapStyle = .round
        arrowPath.lineJoinStyle = .round
        arrowPath.move(to: NSPoint(x: 285, y: centerY))
        arrowPath.line(to: NSPoint(x: 395, y: centerY))
        arrowPath.stroke()

        let arrowHead = NSBezierPath()
        arrowHead.lineWidth = 7
        arrowHead.lineCapStyle = .round
        arrowHead.lineJoinStyle = .round
        arrowHead.move(to: NSPoint(x: 370, y: centerY + 25))
        arrowHead.line(to: NSPoint(x: 395, y: centerY))
        arrowHead.line(to: NSPoint(x: 370, y: centerY - 25))
        arrowHead.stroke()
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
