import Foundation
import Testing
@testable import DMGForgeCore

@Test func defaultProjectUsesAppNameVersionAndConventionalLayout() throws {
    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )

    #expect(project.schemaVersion == 1)
    #expect(project.appName == "MyApp")
    #expect(project.version == "1.0.0")
    #expect(project.volumeName == "MyApp 1.0.0")
    #expect(project.outputPath == "dist/MyApp-macos-arm64.dmg")
    #expect(project.window.width == 680)
    #expect(project.window.height == 420)
    #expect(project.layout.appIcon.x == 190)
    #expect(project.layout.applicationsIcon.x == 500)
    #expect(project.background.title == "Drag to install")
    #expect(project.guideArrow.visible)
    #expect(project.guideArrow.color == "#444444")
    #expect(project.guideArrow.thickness == 7)
    #expect(!project.firstLaunchGuide.enabled)
    #expect(project.firstLaunchGuide.helpFileName == "First Launch Help.txt")
    #expect(project.firstLaunchGuide.securitySettingsShortcutName == "Open Security Settings.inetloc")
}

@Test func projectRoundTripsThroughPrettyJSON() throws {
    let original = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )

    let data = try original.prettyJSONData()
    let decoded = try DMGProject.decode(from: data)

    #expect(decoded == original)
    #expect(String(decoding: data, as: UTF8.self).contains("\"schemaVersion\" : 1"))
}

@Test func projectDecodesLegacyJSONWithoutGuideArrow() throws {
    let json = """
    {
      "schemaVersion": 1,
      "appName": "LegacyApp",
      "version": "1.0.0",
      "appPath": "dist/LegacyApp.app",
      "outputPath": "dist/LegacyApp.dmg",
      "volumeName": "LegacyApp 1.0.0",
      "window": {
        "width": 680,
        "height": 420
      },
      "layout": {
        "appIcon": { "x": 190, "y": 198 },
        "applicationsIcon": { "x": 500, "y": 198 }
      },
      "background": {
        "mode": "generated",
        "imagePath": null,
        "title": "Drag to install",
        "description": "Drop LegacyApp into Applications.",
        "footer": "Packaged with DMGForge."
      }
    }
    """

    let decoded = try DMGProject.decode(from: Data(json.utf8))

    #expect(decoded.guideArrow == .default)
    #expect(decoded.firstLaunchGuide == .default)
}

@Test func firstLaunchGuideDefaultHelpTextUsesAppName() throws {
    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )

    let helpText = project.firstLaunchGuide.resolvedHelpText(appName: project.appName)

    #expect(helpText.contains("Drag MyApp into Applications."))
    #expect(helpText.contains("Open Anyway"))
}

@Test func validatorAcceptsExistingAppBundle() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let appURL = tempRoot.appendingPathComponent("MyApp.app", isDirectory: true)
    let outputURL = tempRoot.appendingPathComponent("MyApp.dmg")
    try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    var project = DMGProjectFactory.makeDefault(
        appPath: appURL.path,
        appName: "MyApp",
        version: "1.0.0"
    )
    project.outputPath = outputURL.path

    let result = ProjectValidator().validate(project)

    #expect(result.isValid)
    #expect(result.issues.isEmpty)
}

@Test func validatorRejectsMissingAppBundle() throws {
    let project = DMGProjectFactory.makeDefault(
        appPath: "dist/Missing.app",
        appName: "Missing",
        version: "1.0.0"
    )

    let result = ProjectValidator().validate(project)

    #expect(!result.isValid)
    #expect(result.issues.contains(.missingAppBundle(path: "dist/Missing.app")))
}

@Test func validatorRejectsNonAppPathAndSmallWindow() throws {
    var project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.zip",
        appName: "MyApp",
        version: "1.0.0"
    )
    project.window = DMGWindow(width: 300, height: 200)

    let result = ProjectValidator().validate(project)

    #expect(!result.isValid)
    #expect(result.issues.contains(.appPathIsNotBundle(path: "dist/MyApp.zip")))
    #expect(result.issues.contains(.windowTooSmall(width: 300, height: 200)))
}

@Test func validatorRejectsInvalidGuideArrowSettings() throws {
    var project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    project.guideArrow.color = "red"
    project.guideArrow.thickness = 0

    let result = ProjectValidator().validate(project)

    #expect(result.issues.contains(.invalidGuideArrowColor(color: "red")))
    #expect(result.issues.contains(.invalidGuideArrowThickness(thickness: 0)))
}

@Test func validatorRejectsInvalidFirstLaunchGuideSettingsWhenEnabled() throws {
    var project = DMGProjectFactory.makeDefault(
        appPath: "dist/MyApp.app",
        appName: "MyApp",
        version: "1.0.0"
    )
    project.firstLaunchGuide.enabled = true
    project.firstLaunchGuide.helpFileName = ""
    project.firstLaunchGuide.securitySettingsShortcutName = "../Open Security Settings.inetloc"
    project.firstLaunchGuide.securitySettingsURL = ""

    let result = ProjectValidator().validate(project)

    #expect(result.issues.contains(.invalidFirstLaunchGuideFileName(name: "")))
    #expect(result.issues.contains(.invalidFirstLaunchGuideFileName(name: "../Open Security Settings.inetloc")))
    #expect(result.issues.contains(.invalidFirstLaunchGuideURL(url: "")))
}
