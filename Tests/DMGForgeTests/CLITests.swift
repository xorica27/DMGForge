import Foundation
import Testing
import DMGForgeCore
@testable import DMGForge

@Test func cliInitWritesProjectFile() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("MyApp.dmgproject")
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let result = CLI().run(arguments: [
        "init",
        "--app", "dist/MyApp.app",
        "--name", "MyApp",
        "--version", "1.0.0",
        "--output", projectURL.path
    ])

    #expect(result == .success)
    #expect(FileManager.default.fileExists(atPath: projectURL.path))
    let data = try Data(contentsOf: projectURL)
    let json = String(decoding: data, as: UTF8.self)
    #expect(json.contains("\"appName\" : \"MyApp\""))
}

@Test func cliValidateRejectsMissingProjectFile() throws {
    let result = CLI().run(arguments: ["validate", "/tmp/not-a-real-project.dmgproject"])

    #expect(result == .failure)
}

@Test func cliUnknownCommandReturnsUsageError() throws {
    let result = CLI().run(arguments: ["shipit"])

    #expect(result == .usageError)
}

@Test func cliHelpReturnsSuccess() throws {
    let result = CLI().run(arguments: ["--help"])

    #expect(result == .success)
}

@Test func cliPreviewWritesPNG() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("MyApp.dmgproject")
    let previewURL = tempRoot.appendingPathComponent("preview.png")
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    try project.prettyJSONData().write(to: projectURL)

    let result = CLI().run(arguments: ["preview", projectURL.path, "--output", previewURL.path])

    #expect(result == .success)
    #expect(FileManager.default.fileExists(atPath: previewURL.path))
}

@Test func cliExportDryRunValidatesProjectWithoutWritingDMG() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let appURL = tempRoot.appendingPathComponent("dist/MyApp.app", isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("packaging/MyApp.dmgproject")
    let outputURL = tempRoot.appendingPathComponent("dist/MyApp.dmg")
    try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: projectURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    var project = DMGProjectFactory.makeDefault(
        appPath: appURL.path,
        appName: "MyApp",
        version: "1.0.0"
    )
    project.outputPath = outputURL.path
    try project.prettyJSONData().write(to: projectURL)

    let result = CLI().run(arguments: ["export", projectURL.path, "--dry-run"])

    #expect(result == .success)
    #expect(!FileManager.default.fileExists(atPath: outputURL.path))
}

@Test func cliCopyUpdatesProjectTextFields() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("MyApp.dmgproject")
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    try project.prettyJSONData().write(to: projectURL)

    let result = CLI().run(arguments: [
        "copy",
        projectURL.path,
        "--title", "Install MyApp",
        "--description", "Drag MyApp into Applications.",
        "--footer", "Signed and ready."
    ])

    let updated = try DMGProject.decode(from: Data(contentsOf: projectURL))
    #expect(result == .success)
    #expect(updated.background.title == "Install MyApp")
    #expect(updated.background.description == "Drag MyApp into Applications.")
    #expect(updated.background.footer == "Signed and ready.")
}

@Test func cliBackgroundSetsCustomImageAndGeneratedMode() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("MyApp.dmgproject")
    let imageURL = tempRoot.appendingPathComponent("background.png")
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    try Data([0x89, 0x50, 0x4E, 0x47]).write(to: imageURL)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    try project.prettyJSONData().write(to: projectURL)

    let imageResult = CLI().run(arguments: [
        "background",
        projectURL.path,
        "--image", imageURL.path
    ])
    let imageProject = try DMGProject.decode(from: Data(contentsOf: projectURL))

    let generatedResult = CLI().run(arguments: [
        "background",
        projectURL.path,
        "--generated"
    ])
    let generatedProject = try DMGProject.decode(from: Data(contentsOf: projectURL))

    #expect(imageResult == .success)
    #expect(imageProject.background.mode == .image)
    #expect(imageProject.background.imagePath == imageURL.path)
    #expect(generatedResult == .success)
    #expect(generatedProject.background.mode == .generated)
    #expect(generatedProject.background.imagePath == nil)
}

@Test func cliArrowUpdatesGuideArrowSettings() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("MyApp.dmgproject")
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    try project.prettyJSONData().write(to: projectURL)

    let hideResult = CLI().run(arguments: ["arrow", projectURL.path, "--hide"])
    let hiddenProject = try DMGProject.decode(from: Data(contentsOf: projectURL))

    let customResult = CLI().run(arguments: [
        "arrow",
        projectURL.path,
        "--show",
        "--color", "#FFFFFF",
        "--thickness", "5"
    ])
    let customProject = try DMGProject.decode(from: Data(contentsOf: projectURL))

    #expect(hideResult == .success)
    #expect(!hiddenProject.guideArrow.visible)
    #expect(customResult == .success)
    #expect(customProject.guideArrow.visible)
    #expect(customProject.guideArrow.color == "#FFFFFF")
    #expect(customProject.guideArrow.thickness == 5)
}

@Test func cliArrowRejectsInvalidThickness() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("MyApp.dmgproject")
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    try project.prettyJSONData().write(to: projectURL)

    let result = CLI().run(arguments: ["arrow", projectURL.path, "--thickness", "0"])

    #expect(result == .usageError)
}

@Test func cliFirstLaunchTogglesUnsignedAppGuide() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("MyApp.dmgproject")
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    try project.prettyJSONData().write(to: projectURL)

    let enableResult = CLI().run(arguments: ["first-launch", projectURL.path, "--enable"])
    let enabledProject = try DMGProject.decode(from: Data(contentsOf: projectURL))

    let disableResult = CLI().run(arguments: ["first-launch", projectURL.path, "--disable"])
    let disabledProject = try DMGProject.decode(from: Data(contentsOf: projectURL))

    #expect(enableResult == .success)
    #expect(enabledProject.firstLaunchGuide.enabled)
    #expect(enabledProject.window.height == 560)
    #expect(enabledProject.layout.appIcon == DMGPoint(x: 190, y: 210))
    #expect(enabledProject.layout.applicationsIcon == DMGPoint(x: 500, y: 210))
    #expect(enabledProject.background.title == "Install MyApp")
    #expect(enabledProject.background.description == "Drag to Applications. If macOS blocks first open, use the helper below.")
    #expect(enabledProject.background.footer.isEmpty)
    #expect(disableResult == .success)
    #expect(!disabledProject.firstLaunchGuide.enabled)
}

@Test func cliReviewDryRunValidatesProjectWithoutWritingDMG() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let appURL = tempRoot.appendingPathComponent("dist/MyApp.app", isDirectory: true)
    let projectURL = tempRoot.appendingPathComponent("packaging/MyApp.dmgproject")
    let outputURL = tempRoot.appendingPathComponent("dist/MyApp.dmg")
    try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: projectURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    var project = DMGProjectFactory.makeDefault(
        appPath: appURL.path,
        appName: "MyApp",
        version: "1.0.0"
    )
    project.outputPath = outputURL.path
    try project.prettyJSONData().write(to: projectURL)

    let result = CLI().run(arguments: ["review", projectURL.path, "--dry-run"])

    #expect(result == .success)
    #expect(!FileManager.default.fileExists(atPath: outputURL.path))
}
