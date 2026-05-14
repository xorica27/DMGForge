import DMGForgeCore
import Foundation
import AppKit

enum ExitCode: Int32, Equatable {
    case success = 0
    case failure = 1
    case usageError = 2
}

struct CLI {
    func run(arguments: [String]) -> ExitCode {
        guard let command = arguments.first else {
            print(Self.usage)
            return .success
        }

        switch command {
        case "--help", "-h", "help":
            print(Self.usage)
            return .success
        case "init":
            return runInit(arguments: Array(arguments.dropFirst()))
        case "validate":
            return runValidate(arguments: Array(arguments.dropFirst()))
        case "preview":
            return runPreview(arguments: Array(arguments.dropFirst()))
        case "export":
            return runExport(arguments: Array(arguments.dropFirst()))
        case "review":
            return runReview(arguments: Array(arguments.dropFirst()))
        case "copy":
            return runCopy(arguments: Array(arguments.dropFirst()))
        case "background":
            return runBackground(arguments: Array(arguments.dropFirst()))
        case "arrow":
            return runArrow(arguments: Array(arguments.dropFirst()))
        case "open":
            return runOpen(arguments: Array(arguments.dropFirst()))
        default:
            fputs("Unknown command: \(command)\n\n\(Self.usage)\n", stderr)
            return .usageError
        }
    }

    private func runInit(arguments: [String]) -> ExitCode {
        let options = parseOptions(arguments)
        guard let appPath = options["app"],
              let appName = options["name"],
              let version = options["version"],
              let output = options["output"] else {
            fputs("Usage: dmgforge init --app <App.app> --name <Name> --version <Version> --output <Project.dmgproject>\n", stderr)
            return .usageError
        }

        let project = DMGProjectFactory.makeDefault(
            appPath: appPath,
            appName: appName,
            version: version
        )
        let outputURL = URL(fileURLWithPath: output)

        do {
            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try project.prettyJSONData().write(to: outputURL)
            print("Created \(output)")
            return .success
        } catch {
            fputs("Could not create project: \(error.localizedDescription)\n", stderr)
            return .failure
        }
    }

    private func runValidate(arguments: [String]) -> ExitCode {
        guard arguments.count == 1, let path = arguments.first else {
            fputs("Usage: dmgforge validate <Project.dmgproject>\n", stderr)
            return .usageError
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let project = try DMGProject.decode(from: data)
            let result = ProjectValidator().validate(project)

            if result.isValid {
                print("Project is valid.")
                return .success
            }

            for issue in result.issues {
                fputs("- \(issue.description)\n", stderr)
            }
            return .failure
        } catch {
            fputs("Could not validate project: \(error.localizedDescription)\n", stderr)
            return .failure
        }
    }

    private func runPreview(arguments: [String]) -> ExitCode {
        guard let projectPath = arguments.first, !projectPath.hasPrefix("--") else {
            fputs("Usage: dmgforge preview <Project.dmgproject> [--output <preview.png>]\n", stderr)
            return .usageError
        }

        do {
            let project = try loadProject(at: projectPath)
            let options = parseOptions(Array(arguments.dropFirst()))
            let outputURL = URL(fileURLWithPath: options["output"] ?? defaultPreviewPath(for: project))
            try PreviewRenderer().render(project: project, to: outputURL)
            print("Rendered \(outputURL.path)")
            return .success
        } catch {
            fputs("Could not render preview: \(error.localizedDescription)\n", stderr)
            return .failure
        }
    }

    private func runExport(arguments: [String]) -> ExitCode {
        guard let projectPath = arguments.first, !projectPath.hasPrefix("--") else {
            fputs("Usage: dmgforge export <Project.dmgproject> [--output <App.dmg>] [--dry-run]\n", stderr)
            return .usageError
        }

        do {
            var project = try loadProject(at: projectPath)
            let trailingArguments = Array(arguments.dropFirst())
            let options = parseOptions(trailingArguments)
            if let output = options["output"] {
                project.outputPath = output
            }

            let validation = ProjectValidator().validate(project)
            guard validation.isValid else {
                for issue in validation.issues {
                    fputs("- \(issue.description)\n", stderr)
                }
                return .failure
            }

            if trailingArguments.contains("--dry-run") {
                print("Ready to export \(project.outputPath)")
                return .success
            }

            let result = try DMGBuilder().export(project: project)
            print("Exported \(result.dmgURL.path)")
            return .success
        } catch {
            fputs("Could not export DMG: \(error.localizedDescription)\n", stderr)
            return .failure
        }
    }

    private func runReview(arguments: [String]) -> ExitCode {
        guard let projectPath = arguments.first, !projectPath.hasPrefix("--") else {
            fputs("Usage: dmgforge review <Project.dmgproject> [--output <App.dmg>] [--dry-run]\n", stderr)
            return .usageError
        }

        do {
            var project = try loadProject(at: projectPath)
            let trailingArguments = Array(arguments.dropFirst())
            let options = parseOptions(trailingArguments)
            if let output = options["output"] {
                project.outputPath = output
            }

            let validation = ProjectValidator().validate(project)
            guard validation.isValid else {
                for issue in validation.issues {
                    fputs("- \(issue.description)\n", stderr)
                }
                return .failure
            }

            if trailingArguments.contains("--dry-run") {
                print("Ready to review \(project.outputPath)")
                return .success
            }

            let result = try DMGBuilder().export(project: project)
            guard NSWorkspace.shared.open(result.dmgURL) else {
                fputs("Could not open \(result.dmgURL.path)\n", stderr)
                return .failure
            }

            print("Opened \(result.dmgURL.path)")
            return .success
        } catch {
            fputs("Could not review DMG: \(error.localizedDescription)\n", stderr)
            return .failure
        }
    }

    private func runCopy(arguments: [String]) -> ExitCode {
        guard let projectPath = arguments.first, !projectPath.hasPrefix("--") else {
            fputs("Usage: dmgforge copy <Project.dmgproject> [--title <Text>] [--description <Text>] [--footer <Text>]\n", stderr)
            return .usageError
        }

        let options = parseOptions(Array(arguments.dropFirst()))
        guard options["title"] != nil || options["description"] != nil || options["footer"] != nil else {
            fputs("Usage: dmgforge copy <Project.dmgproject> [--title <Text>] [--description <Text>] [--footer <Text>]\n", stderr)
            return .usageError
        }

        do {
            var project = try loadProject(at: projectPath)
            if let title = options["title"] {
                project.background.title = title
            }
            if let description = options["description"] {
                project.background.description = description
            }
            if let footer = options["footer"] {
                project.background.footer = footer
            }

            try saveProject(project, at: projectPath)
            print("Updated copy in \(projectPath)")
            return .success
        } catch {
            fputs("Could not update copy: \(error.localizedDescription)\n", stderr)
            return .failure
        }
    }

    private func runBackground(arguments: [String]) -> ExitCode {
        guard let projectPath = arguments.first, !projectPath.hasPrefix("--") else {
            fputs("Usage: dmgforge background <Project.dmgproject> (--image <Image.png> | --generated)\n", stderr)
            return .usageError
        }

        let trailingArguments = Array(arguments.dropFirst())
        let options = parseOptions(trailingArguments)
        let useGenerated = trailingArguments.contains("--generated")
        let imagePath = options["image"]

        guard useGenerated != (imagePath != nil) else {
            fputs("Usage: dmgforge background <Project.dmgproject> (--image <Image.png> | --generated)\n", stderr)
            return .usageError
        }

        do {
            var project = try loadProject(at: projectPath)
            if useGenerated {
                project.background.mode = .generated
                project.background.imagePath = nil
            } else if let imagePath {
                guard FileManager.default.fileExists(atPath: imagePath) else {
                    fputs("Background image does not exist: \(imagePath)\n", stderr)
                    return .failure
                }
                project.background.mode = .image
                project.background.imagePath = imagePath
            }

            try saveProject(project, at: projectPath)
            print("Updated background in \(projectPath)")
            return .success
        } catch {
            fputs("Could not update background: \(error.localizedDescription)\n", stderr)
            return .failure
        }
    }

    private func runArrow(arguments: [String]) -> ExitCode {
        guard let projectPath = arguments.first, !projectPath.hasPrefix("--") else {
            fputs("Usage: dmgforge arrow <Project.dmgproject> [--show | --hide] [--color <#RRGGBB>] [--thickness <Pixels>]\n", stderr)
            return .usageError
        }

        let trailingArguments = Array(arguments.dropFirst())
        let options = parseOptions(trailingArguments)
        let hasShow = trailingArguments.contains("--show")
        let hasHide = trailingArguments.contains("--hide")
        guard !(hasShow && hasHide) else {
            fputs("Choose either --show or --hide, not both.\n", stderr)
            return .usageError
        }
        guard hasShow || hasHide || options["color"] != nil || options["thickness"] != nil else {
            fputs("Usage: dmgforge arrow <Project.dmgproject> [--show | --hide] [--color <#RRGGBB>] [--thickness <Pixels>]\n", stderr)
            return .usageError
        }

        do {
            var project = try loadProject(at: projectPath)
            if hasShow {
                project.guideArrow.visible = true
            }
            if hasHide {
                project.guideArrow.visible = false
            }
            if let color = options["color"] {
                guard Self.isHexColor(color) else {
                    fputs("Arrow color must be #RRGGBB: \(color)\n", stderr)
                    return .usageError
                }
                project.guideArrow.color = color.uppercased()
            }
            if let thicknessValue = options["thickness"] {
                guard let thickness = Int(thicknessValue), thickness > 0 else {
                    fputs("Arrow thickness must be a positive integer.\n", stderr)
                    return .usageError
                }
                project.guideArrow.thickness = thickness
            }

            try saveProject(project, at: projectPath)
            print("Updated arrow in \(projectPath)")
            return .success
        } catch {
            fputs("Could not update arrow: \(error.localizedDescription)\n", stderr)
            return .failure
        }
    }

    private func runOpen(arguments: [String]) -> ExitCode {
        guard arguments.count == 1, let path = arguments.first else {
            fputs("Usage: dmgforge open <Project.dmgproject>\n", stderr)
            return .usageError
        }

        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            fputs("Project does not exist: \(path)\n", stderr)
            return .failure
        }

        NSWorkspace.shared.open(url)
        print("Opened \(path)")
        return .success
    }

    private func loadProject(at path: String) throws -> DMGProject {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try DMGProject.decode(from: data)
    }

    private func saveProject(_ project: DMGProject, at path: String) throws {
        try project.prettyJSONData().write(to: URL(fileURLWithPath: path))
    }

    private func defaultPreviewPath(for project: DMGProject) -> String {
        let outputURL = URL(fileURLWithPath: project.outputPath)
        let filename = outputURL.deletingPathExtension().lastPathComponent + "-preview.png"
        return outputURL.deletingLastPathComponent().appendingPathComponent(filename).path
    }

    private func parseOptions(_ arguments: [String]) -> [String: String] {
        var options: [String: String] = [:]
        var index = 0

        while index < arguments.count {
            let token = arguments[index]
            guard token.hasPrefix("--") else {
                index += 1
                continue
            }

            let key = String(token.dropFirst(2))
            let valueIndex = index + 1
            if valueIndex < arguments.count && !arguments[valueIndex].hasPrefix("--") {
                options[key] = arguments[valueIndex]
                index += 2
            } else {
                index += 1
            }
        }

        return options
    }

    private static func isHexColor(_ value: String) -> Bool {
        let pattern = /^#[0-9A-Fa-f]{6}$/
        return value.wholeMatch(of: pattern) != nil
    }

    static let usage = """
    DMGForge

    Usage:
      dmgforge init --app <App.app> --name <Name> --version <Version> --output <Project.dmgproject>
      dmgforge validate <Project.dmgproject>
      dmgforge preview <Project.dmgproject>
      dmgforge export <Project.dmgproject>
      dmgforge review <Project.dmgproject>
      dmgforge copy <Project.dmgproject> [--title <Text>] [--description <Text>] [--footer <Text>]
      dmgforge background <Project.dmgproject> (--image <Image.png> | --generated)
      dmgforge arrow <Project.dmgproject> [--show | --hide] [--color <#RRGGBB>] [--thickness <Pixels>]
      dmgforge open <Project.dmgproject>
    """
}
