import AppKit
import DMGForgeCore
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class ProjectEditorViewModel: ObservableObject {
    @Published var project: DMGProject {
        didSet {
            refreshValidation()
            refreshPreview()
        }
    }
    @Published private(set) var projectURL: URL?
    @Published private(set) var previewImage: NSImage?
    @Published private(set) var validationIssues: [ValidationIssue] = []
    @Published var statusMessage = "Ready"

    private let previewRenderer: PreviewRenderer
    private let projectValidator: ProjectValidator
    private let builder: DMGBuilder
    private let previewURL: URL

    init(
        project: DMGProject = DMGProjectFactory.makeDefault(
            appPath: "dist/MyApp.app",
            appName: "MyApp",
            version: "1.0.0"
        ),
        previewRenderer: PreviewRenderer = PreviewRenderer(),
        projectValidator: ProjectValidator = ProjectValidator(),
        builder: DMGBuilder = DMGBuilder()
    ) {
        self.project = project
        self.previewRenderer = previewRenderer
        self.projectValidator = projectValidator
        self.builder = builder
        self.previewURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("dmgforge-editor-\(UUID().uuidString)-preview.png")

        refreshValidation()
        refreshPreview()
    }

    func newProject() {
        project = DMGProjectFactory.makeDefault(
            appPath: "dist/MyApp.app",
            appName: "MyApp",
            version: "1.0.0"
        )
        projectURL = nil
        statusMessage = "Started a new project."
    }

    func loadProject(from url: URL) throws {
        let data = try Data(contentsOf: url)
        project = try DMGProject.decode(from: data)
        projectURL = url
        statusMessage = "Loaded \(url.lastPathComponent)."
    }

    func saveProject(to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try project.prettyJSONData().write(to: url)
        projectURL = url
        statusMessage = "Saved \(url.lastPathComponent)."
    }

    func saveProject() {
        guard let projectURL else {
            saveProjectWithPanel()
            return
        }

        do {
            try saveProject(to: projectURL)
        } catch {
            statusMessage = "Could not save project: \(error.localizedDescription)"
        }
    }

    func setBackgroundImage(_ url: URL) throws {
        project.background.mode = .image
        project.background.imagePath = url.path
        statusMessage = "Using \(url.lastPathComponent) as the background."
    }

    func setGeneratedBackground() {
        project.background.mode = .generated
        project.background.imagePath = nil
        statusMessage = "Using generated background."
    }

    func exportDMG() {
        let validation = projectValidator.validate(project)
        guard validation.isValid else {
            validationIssues = validation.issues
            statusMessage = "Fix validation issues before exporting."
            return
        }

        do {
            let result = try builder.export(project: project)
            statusMessage = "Exported \(result.dmgURL.lastPathComponent)."
        } catch {
            statusMessage = "Could not export DMG: \(error.localizedDescription)"
        }
    }

    func openProjectWithPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [Self.dmgProjectType, .json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try loadProject(from: url)
        } catch {
            statusMessage = "Could not open project: \(error.localizedDescription)"
        }
    }

    func saveProjectWithPanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.dmgProjectType]
        panel.nameFieldStringValue = "\(project.appName).dmgproject"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try saveProject(to: url)
        } catch {
            statusMessage = "Could not save project: \(error.localizedDescription)"
        }
    }

    func chooseAppBundleWithPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        project.appPath = url.path
        if project.appName == "MyApp" {
            project.appName = url.deletingPathExtension().lastPathComponent
        }
    }

    func chooseBackgroundImageWithPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, Self.heicType]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try setBackgroundImage(url)
        } catch {
            statusMessage = "Could not use background image: \(error.localizedDescription)"
        }
    }

    func chooseOutputDMGWithPanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.dmgType]
        panel.nameFieldStringValue = "\(project.appName)-macos-arm64.dmg"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        project.outputPath = url.path
    }

    func refreshPreview() {
        do {
            try previewRenderer.render(project: project, to: previewURL)
            previewImage = NSImage(contentsOf: previewURL)
        } catch {
            previewImage = nil
            statusMessage = "Could not render preview: \(error.localizedDescription)"
        }
    }

    private func refreshValidation() {
        validationIssues = projectValidator.validate(project).issues
    }

    private static let dmgProjectType = UTType(filenameExtension: "dmgproject") ?? .json
    private static let dmgType = UTType(filenameExtension: "dmg") ?? .data
    private static let heicType = UTType(filenameExtension: "heic") ?? .image
}
