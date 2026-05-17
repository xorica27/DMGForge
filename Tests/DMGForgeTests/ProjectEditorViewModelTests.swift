import AppKit
import Foundation
import Testing
import DMGForgeCore
@testable import DMGForge

@MainActor
@Test func editorSavesTweakedProjectCopy() throws {
    let tempRoot = try makeEditorTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let projectURL = tempRoot.appendingPathComponent("Edited.dmgproject")

    let viewModel = ProjectEditorViewModel()
    viewModel.project.background.description = "Drag the app over when the arrow feels right."

    try viewModel.saveProject(to: projectURL)

    let data = try Data(contentsOf: projectURL)
    let decoded = try DMGProject.decode(from: data)
    #expect(decoded.background.description == "Drag the app over when the arrow feels right.")
    #expect(viewModel.projectURL == projectURL)
}

@MainActor
@Test func editorLoadsProjectAndRefreshesPreview() throws {
    let tempRoot = try makeEditorTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let projectURL = tempRoot.appendingPathComponent("Loaded.dmgproject")

    var project = DMGProjectFactory.makeDefault(
        appPath: "dist/Loaded.app",
        appName: "Loaded",
        version: "2.0.0"
    )
    project.background.title = "Install Loaded"
    try project.prettyJSONData().write(to: projectURL)

    let viewModel = ProjectEditorViewModel()
    try viewModel.loadProject(from: projectURL)

    #expect(viewModel.project == project)
    #expect(viewModel.projectURL == projectURL)
    #expect(viewModel.previewImage != nil)
}

@MainActor
@Test func editorSwitchesToCustomBackgroundImage() throws {
    let tempRoot = try makeEditorTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let imageURL = tempRoot.appendingPathComponent("background.png")
    try makeEditorSolidPNG(color: .systemIndigo, size: NSSize(width: 80, height: 60), outputURL: imageURL)

    let viewModel = ProjectEditorViewModel()

    try viewModel.setBackgroundImage(imageURL)

    #expect(viewModel.project.background.mode == .image)
    #expect(viewModel.project.background.imagePath == imageURL.path)
    #expect(viewModel.previewImage != nil)
}

@MainActor
@Test func editorEnablesFirstLaunchGuideAndExpandsWindow() throws {
    let viewModel = ProjectEditorViewModel()

    viewModel.setFirstLaunchGuideEnabled(true)

    #expect(viewModel.project.firstLaunchGuide.enabled)
    #expect(viewModel.project.window.height == 560)
    #expect(viewModel.project.layout.appIcon == DMGPoint(x: 190, y: 210))
    #expect(viewModel.project.background.title == "Install MyApp")
    #expect(viewModel.previewImage != nil)
}

private func makeEditorTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makeEditorSolidPNG(color: NSColor, size: NSSize, outputURL: URL) throws {
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
