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

@Test func finderAppleScriptPositionsFirstLaunchGuideItemsWhenEnabled() throws {
    var project = DMGProjectFactory.makeDefault(
        appPath: "dist/CoolApp.app",
        appName: "CoolApp",
        version: "2.0.0"
    )
    project.setFirstLaunchGuideEnabled(true)

    let script = DMGBuilder.finderAppleScript(
        project: project,
        mountPoint: "/Volumes/CoolApp 2.0.0",
        backgroundName: "background.png"
    )

    #expect(script.contains("set icon size of viewOptions to 96"))
    #expect(script.contains("set position of item \"CoolApp.app\" of container window to {190, 210}"))
    #expect(script.contains("set position of item \"Applications\" of container window to {500, 210}"))
    #expect(script.contains("set position of item \"Open Security Settings.inetloc\" of container window to {190, 420}"))
    #expect(script.contains("set position of item \"First Launch Help.txt\" of container window to {500, 420}"))
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

@Test func stagingWritesFirstLaunchGuideFilesWhenEnabled() throws {
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
    project.setFirstLaunchGuideEnabled(true)

    try DMGBuilder().stage(project: project, at: stagingURL)

    let shortcutURL = stagingURL.appendingPathComponent("Open Security Settings.inetloc")
    let helpURL = stagingURL.appendingPathComponent("First Launch Help.txt")
    let shortcut = try String(contentsOf: shortcutURL, encoding: .utf8)
    let help = try String(contentsOf: helpURL, encoding: .utf8)

    #expect(shortcut.contains("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"))
    #expect(help.contains("Drag CoolApp into Applications."))
    #expect(help.contains("Open Anyway"))
}

private func makeBuilderTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
