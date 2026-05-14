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
            if valueIndex < arguments.count {
                options[key] = arguments[valueIndex]
                index += 2
            } else {
                index += 1
            }
        }

        return options
    }

    static let usage = """
    DMGForge

    Usage:
      dmgforge init --app <App.app> --name <Name> --version <Version> --output <Project.dmgproject>
      dmgforge validate <Project.dmgproject>
      dmgforge preview <Project.dmgproject>
      dmgforge export <Project.dmgproject>
      dmgforge open <Project.dmgproject>
    """
}
