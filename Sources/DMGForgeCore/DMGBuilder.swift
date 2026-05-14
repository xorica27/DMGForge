import Foundation

public enum DMGBuilderError: Error, CustomStringConvertible, LocalizedError {
    case validationFailed([ValidationIssue])
    case missingTool(String)
    case commandFailed(command: String, status: Int32, output: String)
    case couldNotFindMountedDevice
    case finderDidNotWriteDSStore

    public var description: String {
        switch self {
        case .validationFailed(let issues):
            issues.map(\.description).joined(separator: "\n")
        case .missingTool(let tool):
            "Required macOS tool is missing: \(tool)"
        case .commandFailed(let command, let status, let output):
            "\(command) failed with status \(status): \(output)"
        case .couldNotFindMountedDevice:
            "Could not find mounted DMG device."
        case .finderDidNotWriteDSStore:
            "Finder did not write .DS_Store, so DMG styling was not saved."
        }
    }

    public var errorDescription: String? {
        description
    }
}

public struct DMGExportResult: Equatable, Sendable {
    public var dmgURL: URL

    public init(dmgURL: URL) {
        self.dmgURL = dmgURL
    }
}

public struct DMGBuilder {
    private let fileManager: FileManager
    private let previewRenderer: PreviewRenderer

    public init(fileManager: FileManager = .default, previewRenderer: PreviewRenderer = PreviewRenderer()) {
        self.fileManager = fileManager
        self.previewRenderer = previewRenderer
    }

    public func stage(project: DMGProject, at stagingURL: URL) throws {
        if fileManager.fileExists(atPath: stagingURL.path) {
            try fileManager.removeItem(at: stagingURL)
        }

        let backgroundDirectory = stagingURL.appendingPathComponent(".background", isDirectory: true)
        try fileManager.createDirectory(at: backgroundDirectory, withIntermediateDirectories: true)

        let stagedAppURL = stagingURL.appendingPathComponent("\(project.appName).app", isDirectory: true)
        try fileManager.copyItem(at: URL(fileURLWithPath: project.appPath), to: stagedAppURL)
        try fileManager.createSymbolicLink(
            at: stagingURL.appendingPathComponent("Applications"),
            withDestinationURL: URL(fileURLWithPath: "/Applications", isDirectory: true)
        )

        try previewRenderer.renderBackground(
            project: project,
            to: backgroundDirectory.appendingPathComponent(Self.backgroundName)
        )
    }

    public func export(project: DMGProject, workDirectory: URL? = nil) throws -> DMGExportResult {
        let validation = ProjectValidator(fileManager: fileManager).validate(project)
        guard validation.isValid else {
            throw DMGBuilderError.validationFailed(validation.issues)
        }

        try requireTool("hdiutil")
        try requireTool("osascript")
        try requireTool("SetFile")

        let outputURL = URL(fileURLWithPath: project.outputPath)
        let rootWorkDirectory = workDirectory ?? outputURL.deletingLastPathComponent().appendingPathComponent("dmgforge-work", isDirectory: true)
        let stagingURL = rootWorkDirectory.appendingPathComponent("staging", isDirectory: true)
        let rwDMGURL = rootWorkDirectory.appendingPathComponent("\(project.appName)-rw.dmg")

        if fileManager.fileExists(atPath: rootWorkDirectory.path) {
            try fileManager.removeItem(at: rootWorkDirectory)
        }
        try fileManager.createDirectory(at: rootWorkDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        try detachExistingMounts(volumeName: project.volumeName)
        try stage(project: project, at: stagingURL)

        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }

        _ = try run(
            "/usr/bin/hdiutil",
            [
                "create",
                "-volname", project.volumeName,
                "-srcfolder", stagingURL.path,
                "-fs", "HFS+",
                "-format", "UDRW",
                "-size", "180m",
                rwDMGURL.path
            ]
        )

        let attachOutput = try run("/usr/bin/hdiutil", ["attach", rwDMGURL.path, "-readwrite", "-noverify", "-noautoopen"])
        let mounted = try parseMount(output: attachOutput, volumeName: project.volumeName)

        do {
            _ = try run("/usr/bin/SetFile", ["-a", "V", mounted.mountPoint.appendingPathComponent(".background").path])
            try runAppleScript(Self.finderAppleScript(
                project: project,
                mountPoint: mounted.mountPoint.path,
                backgroundName: Self.backgroundName
            ))

            guard fileManager.fileExists(atPath: mounted.mountPoint.appendingPathComponent(".DS_Store").path) else {
                throw DMGBuilderError.finderDidNotWriteDSStore
            }
        } catch {
            _ = try? run("/usr/bin/hdiutil", ["detach", mounted.device])
            throw error
        }

        _ = try run("/usr/bin/hdiutil", ["detach", mounted.device])
        _ = try run(
            "/usr/bin/hdiutil",
            [
                "convert",
                rwDMGURL.path,
                "-format", "UDZO",
                "-imagekey", "zlib-level=9",
                "-o", outputURL.path
            ]
        )

        return DMGExportResult(dmgURL: outputURL)
    }

    public static func finderAppleScript(project: DMGProject, mountPoint: String, backgroundName: String) -> String {
        let windowRight = 140 + project.window.width
        let windowBottom = 140 + project.window.height

        return """
        tell application "Finder"
          set dmgFolder to POSIX file "\(mountPoint)" as alias
          tell folder dmgFolder
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set sidebar width of container window to 0
            set bounds of container window to {140, 140, \(windowRight), \(windowBottom)}

            set viewOptions to icon view options of container window
            set arrangement of viewOptions to not arranged
            set icon size of viewOptions to 112
            set background picture of viewOptions to file ".background:\(backgroundName)"

            set position of item "\(project.appName).app" of container window to {\(project.layout.appIcon.x), \(project.layout.appIcon.y)}
            set position of item "Applications" of container window to {\(project.layout.applicationsIcon.x), \(project.layout.applicationsIcon.y)}

            update without registering applications
            set bounds of container window to {140, 140, \(windowRight), \(windowBottom)}
            delay 1
            close
          end tell
        end tell
        """
    }

    private func requireTool(_ tool: String) throws {
        let result = try run("/usr/bin/which", [tool], allowFailure: true)
        if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw DMGBuilderError.missingTool(tool)
        }
    }

    private func detachExistingMounts(volumeName: String) throws {
        let info = try run("/usr/bin/hdiutil", ["info"])
        for line in info.components(separatedBy: .newlines) where line.contains("/Volumes/\(volumeName)") {
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            guard let device = components.first else { continue }
            _ = try? run("/usr/bin/hdiutil", ["detach", String(device)])
        }
    }

    private func parseMount(output: String, volumeName: String) throws -> (device: String, mountPoint: URL) {
        for line in output.components(separatedBy: .newlines) where line.contains("Apple_HFS") {
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            guard let device = components.first else { continue }
            if let range = line.range(of: "/Volumes/") {
                let mountPath = String(line[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return (String(device), URL(fileURLWithPath: mountPath, isDirectory: true))
            }
        }

        throw DMGBuilderError.couldNotFindMountedDevice
    }

    private func runAppleScript(_ script: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        guard process.terminationStatus == 0 else {
            throw DMGBuilderError.commandFailed(command: "osascript", status: process.terminationStatus, output: output)
        }
    }

    private func run(_ executable: String, _ arguments: [String], allowFailure: Bool = false) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        if !allowFailure && process.terminationStatus != 0 {
            throw DMGBuilderError.commandFailed(
                command: ([executable] + arguments).joined(separator: " "),
                status: process.terminationStatus,
                output: output
            )
        }
        return output
    }

    private static let backgroundName = "background.png"
}
