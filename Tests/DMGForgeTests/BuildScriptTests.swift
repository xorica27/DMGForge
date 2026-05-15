import Foundation
import Testing

@Test func buildScriptBundlesDeclaredAppIcon() throws {
    let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let scriptURL = repoRoot.appendingPathComponent("scripts/build.sh")
    let iconURL = repoRoot.appendingPathComponent("Sources/DMGForge/Resources/AppIcon.icns")
    let pngURL = repoRoot.appendingPathComponent("Sources/DMGForge/Resources/AppIcon.png")
    let script = try String(contentsOf: scriptURL, encoding: .utf8)

    #expect(FileManager.default.fileExists(atPath: iconURL.path))
    #expect(FileManager.default.fileExists(atPath: pngURL.path))
    #expect(script.contains("CFBundleIconFile"))
    #expect(script.contains("AppIcon.icns"))
    #expect(script.contains("Contents/Resources/$ICON_NAME"))
}
