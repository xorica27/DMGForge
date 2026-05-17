import Foundation

public enum DMGProjectFactory {
    public static func makeDefault(appPath: String, appName: String, version: String) -> DMGProject {
        DMGProject(
            schemaVersion: 1,
            appName: appName,
            version: version,
            appPath: appPath,
            outputPath: "dist/\(appName)-macos-arm64.dmg",
            volumeName: "\(appName) \(version)",
            window: DMGWindow(width: 680, height: 420),
            layout: DMGLayout(
                appIcon: DMGLayout.defaultAppIcon,
                applicationsIcon: DMGLayout.defaultApplicationsIcon
            ),
            background: DMGBackground(
                mode: .generated,
                imagePath: nil,
                title: "Drag to install",
                description: "Drop \(appName) into Applications.",
                footer: "Packaged with DMGForge."
            )
        )
    }
}
