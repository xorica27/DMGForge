import Foundation

public struct ValidationResult: Equatable, Sendable {
    public var issues: [ValidationIssue]

    public var isValid: Bool {
        issues.isEmpty
    }

    public init(issues: [ValidationIssue]) {
        self.issues = issues
    }
}

public enum ValidationIssue: Equatable, Sendable, CustomStringConvertible {
    case missingAppBundle(path: String)
    case appPathIsNotBundle(path: String)
    case windowTooSmall(width: Int, height: Int)
    case missingBackgroundImage(path: String)
    case outputDirectoryMissing(path: String)
    case invalidGuideArrowColor(color: String)
    case invalidGuideArrowThickness(thickness: Int)
    case invalidFirstLaunchGuideFileName(name: String)
    case invalidFirstLaunchGuideURL(url: String)

    public var description: String {
        switch self {
        case .missingAppBundle(let path):
            "App bundle does not exist: \(path)"
        case .appPathIsNotBundle(let path):
            "App path must end in .app: \(path)"
        case .windowTooSmall(let width, let height):
            "DMG window must be at least 500x320, got \(width)x\(height)"
        case .missingBackgroundImage(let path):
            "Background image does not exist: \(path)"
        case .outputDirectoryMissing(let path):
            "Output directory does not exist: \(path)"
        case .invalidGuideArrowColor(let color):
            "Guide arrow color must be #RRGGBB: \(color)"
        case .invalidGuideArrowThickness(let thickness):
            "Guide arrow thickness must be greater than 0, got \(thickness)"
        case .invalidFirstLaunchGuideFileName(let name):
            "First launch guide file names must be plain file names: \(name)"
        case .invalidFirstLaunchGuideURL(let url):
            "First launch security settings URL is invalid: \(url)"
        }
    }
}

public struct ProjectValidator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func validate(_ project: DMGProject) -> ValidationResult {
        var issues: [ValidationIssue] = []

        if !project.appPath.hasSuffix(".app") {
            issues.append(.appPathIsNotBundle(path: project.appPath))
        }

        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: project.appPath, isDirectory: &isDirectory) || !isDirectory.boolValue {
            issues.append(.missingAppBundle(path: project.appPath))
        }

        if project.window.width < 500 || project.window.height < 320 {
            issues.append(.windowTooSmall(width: project.window.width, height: project.window.height))
        }

        if project.background.mode == .image {
            let imagePath = project.background.imagePath ?? ""
            if imagePath.isEmpty || !fileManager.fileExists(atPath: imagePath) {
                issues.append(.missingBackgroundImage(path: imagePath))
            }
        }

        let outputDirectory = URL(fileURLWithPath: project.outputPath).deletingLastPathComponent().path
        if !outputDirectory.isEmpty && !fileManager.fileExists(atPath: outputDirectory) {
            issues.append(.outputDirectoryMissing(path: outputDirectory))
        }

        if !Self.isHexColor(project.guideArrow.color) {
            issues.append(.invalidGuideArrowColor(color: project.guideArrow.color))
        }

        if project.guideArrow.thickness <= 0 {
            issues.append(.invalidGuideArrowThickness(thickness: project.guideArrow.thickness))
        }

        if project.firstLaunchGuide.enabled {
            if !Self.isPlainFileName(project.firstLaunchGuide.helpFileName) {
                issues.append(.invalidFirstLaunchGuideFileName(name: project.firstLaunchGuide.helpFileName))
            }
            if !Self.isPlainFileName(project.firstLaunchGuide.securitySettingsShortcutName) {
                issues.append(.invalidFirstLaunchGuideFileName(name: project.firstLaunchGuide.securitySettingsShortcutName))
            }
            if project.firstLaunchGuide.securitySettingsURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.invalidFirstLaunchGuideURL(url: project.firstLaunchGuide.securitySettingsURL))
            }
        }

        return ValidationResult(issues: issues)
    }

    private static func isHexColor(_ value: String) -> Bool {
        guard value.count == 7, value.first == "#" else {
            return false
        }

        return value.dropFirst().allSatisfy { character in
            character.isNumber || ("a"..."f").contains(character.lowercased())
        }
    }

    private static func isPlainFileName(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains("/") && !trimmed.contains("\\")
    }
}
