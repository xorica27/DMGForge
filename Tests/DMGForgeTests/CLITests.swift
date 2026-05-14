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
