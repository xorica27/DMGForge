import Foundation
import Testing
@testable import DMGForgeCore

@Test func finderAppleScriptContainsProjectLayout() throws {
    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/CoolApp.app",
        appName: "CoolApp",
        version: "2.0.0"
    )

    let script = DMGBuilder.finderAppleScript(
        project: project,
        mountPoint: "/Volumes/CoolApp 2.0.0",
        backgroundName: "background.png"
    )

    #expect(script.contains("set bounds of container window to {140, 140, 820, 560}"))
    #expect(script.contains("set background picture of viewOptions to file \".background:background.png\""))
    #expect(script.contains("set position of item \"CoolApp.app\" of container window to {190, 198}"))
    #expect(script.contains("set position of item \"Applications\" of container window to {500, 198}"))
}

@Test func stagingCopiesAppSymlinkAndBackground() throws {
    let tempRoot = try makeBuilderTempDirectory()
    defer { try? FileManager.default.removeItem(at: tempRoot) }
    let appURL = tempRoot.appendingPathComponent("dist/CoolApp.app", isDirectory: true)
    let outputURL = tempRoot.appendingPathComponent("dist/CoolApp.dmg")
    let stagingURL = tempRoot.appendingPathComponent("staging", isDirectory: true)
    try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)

    var project = DMGProjectFactory.makeDefault(
        appPath: appURL.path,
        appName: "CoolApp",
        version: "2.0.0"
    )
    project.outputPath = outputURL.path

    try DMGBuilder().stage(project: project, at: stagingURL)

    #expect(FileManager.default.fileExists(atPath: stagingURL.appendingPathComponent("CoolApp.app").path))
    let symlinkDestination = try FileManager.default.destinationOfSymbolicLink(
        atPath: stagingURL.appendingPathComponent("Applications").path
    )
    #expect(symlinkDestination == "/Applications")
    #expect(FileManager.default.fileExists(atPath: stagingURL.appendingPathComponent(".background/background.png").path))
}

private func makeBuilderTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
