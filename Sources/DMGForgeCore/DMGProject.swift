import Foundation

public struct DMGProject: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var appName: String
    public var version: String
    public var appPath: String
    public var outputPath: String
    public var volumeName: String
    public var window: DMGWindow
    public var layout: DMGLayout
    public var background: DMGBackground
    public var guideArrow: DMGGuideArrow
    public var firstLaunchGuide: DMGFirstLaunchGuide

    public init(
        schemaVersion: Int,
        appName: String,
        version: String,
        appPath: String,
        outputPath: String,
        volumeName: String,
        window: DMGWindow,
        layout: DMGLayout,
        background: DMGBackground,
        guideArrow: DMGGuideArrow = .default,
        firstLaunchGuide: DMGFirstLaunchGuide = .default
    ) {
        self.schemaVersion = schemaVersion
        self.appName = appName
        self.version = version
        self.appPath = appPath
        self.outputPath = outputPath
        self.volumeName = volumeName
        self.window = window
        self.layout = layout
        self.background = background
        self.guideArrow = guideArrow
        self.firstLaunchGuide = firstLaunchGuide
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case appName
        case version
        case appPath
        case outputPath
        case volumeName
        case window
        case layout
        case background
        case guideArrow
        case firstLaunchGuide
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        self.appName = try container.decode(String.self, forKey: .appName)
        self.version = try container.decode(String.self, forKey: .version)
        self.appPath = try container.decode(String.self, forKey: .appPath)
        self.outputPath = try container.decode(String.self, forKey: .outputPath)
        self.volumeName = try container.decode(String.self, forKey: .volumeName)
        self.window = try container.decode(DMGWindow.self, forKey: .window)
        self.layout = try container.decode(DMGLayout.self, forKey: .layout)
        self.background = try container.decode(DMGBackground.self, forKey: .background)
        self.guideArrow = try container.decodeIfPresent(DMGGuideArrow.self, forKey: .guideArrow) ?? .default
        self.firstLaunchGuide = try container.decodeIfPresent(DMGFirstLaunchGuide.self, forKey: .firstLaunchGuide) ?? .default
    }

    public static func decode(from data: Data) throws -> DMGProject {
        try JSONDecoder().decode(DMGProject.self, from: data)
    }

    public func prettyJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

public struct DMGWindow: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public struct DMGLayout: Codable, Equatable, Sendable {
    public var appIcon: DMGPoint
    public var applicationsIcon: DMGPoint

    public init(appIcon: DMGPoint, applicationsIcon: DMGPoint) {
        self.appIcon = appIcon
        self.applicationsIcon = applicationsIcon
    }
}

public struct DMGPoint: Codable, Equatable, Sendable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct DMGBackground: Codable, Equatable, Sendable {
    public var mode: DMGBackgroundMode
    public var imagePath: String?
    public var title: String
    public var description: String
    public var footer: String

    public init(
        mode: DMGBackgroundMode,
        imagePath: String?,
        title: String,
        description: String,
        footer: String
    ) {
        self.mode = mode
        self.imagePath = imagePath
        self.title = title
        self.description = description
        self.footer = footer
    }
}

public enum DMGBackgroundMode: String, Codable, Equatable, Sendable {
    case generated
    case image
}

public extension DMGProject {
    mutating func setFirstLaunchGuideEnabled(_ enabled: Bool) {
        firstLaunchGuide.enabled = enabled
        guard enabled else { return }

        window.height = max(window.height, 560)

        if layout.appIcon == DMGLayout.defaultAppIcon {
            layout.appIcon = DMGLayout.firstLaunchGuideAppIcon
        }
        if layout.applicationsIcon == DMGLayout.defaultApplicationsIcon {
            layout.applicationsIcon = DMGLayout.firstLaunchGuideApplicationsIcon
        }
        if background.title == "Drag to install" {
            background.title = "Install \(appName)"
        }
        if background.description == "Drop \(appName) into Applications." {
            background.description = "Drag to Applications. If macOS blocks first open, use the helper below."
        }
        if background.footer == "Packaged with DMGForge." {
            background.footer = ""
        }
    }
}

public struct DMGGuideArrow: Codable, Equatable, Sendable {
    public var visible: Bool
    public var color: String
    public var thickness: Int

    public init(visible: Bool, color: String, thickness: Int) {
        self.visible = visible
        self.color = color
        self.thickness = thickness
    }

    public static let `default` = DMGGuideArrow(
        visible: true,
        color: "#444444",
        thickness: 7
    )
}

public extension DMGLayout {
    static let defaultAppIcon = DMGPoint(x: 190, y: 198)
    static let defaultApplicationsIcon = DMGPoint(x: 500, y: 198)
    static let firstLaunchGuideAppIcon = DMGPoint(x: 190, y: 210)
    static let firstLaunchGuideApplicationsIcon = DMGPoint(x: 500, y: 210)
}

public struct DMGFirstLaunchGuide: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var helpFileName: String
    public var securitySettingsShortcutName: String
    public var securitySettingsURL: String
    public var helpText: String
    public var securitySettingsIcon: DMGPoint
    public var helpFileIcon: DMGPoint

    public init(
        enabled: Bool,
        helpFileName: String,
        securitySettingsShortcutName: String,
        securitySettingsURL: String,
        helpText: String,
        securitySettingsIcon: DMGPoint,
        helpFileIcon: DMGPoint
    ) {
        self.enabled = enabled
        self.helpFileName = helpFileName
        self.securitySettingsShortcutName = securitySettingsShortcutName
        self.securitySettingsURL = securitySettingsURL
        self.helpText = helpText
        self.securitySettingsIcon = securitySettingsIcon
        self.helpFileIcon = helpFileIcon
    }

    public func resolvedHelpText(appName: String) -> String {
        let trimmed = helpText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return helpText
        }

        return """
        First launch help

        1. Drag \(appName) into Applications.
        2. Open \(appName) from Applications.
        3. If macOS says the app cannot be opened, click Done.
        4. Double-click Open Security Settings in this window.
        5. In Privacy & Security, click Open Anyway for \(appName).
        6. Click Open when macOS asks one more time.

        After this approval, the app should open normally.
        """
    }

    public static let `default` = DMGFirstLaunchGuide(
        enabled: false,
        helpFileName: "First Launch Help.txt",
        securitySettingsShortcutName: "Open Security Settings.inetloc",
        securitySettingsURL: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension",
        helpText: "",
        securitySettingsIcon: DMGPoint(x: 190, y: 420),
        helpFileIcon: DMGPoint(x: 500, y: 420)
    )
}
