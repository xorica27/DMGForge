import Foundation
import Testing
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

