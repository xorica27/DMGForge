import DMGForgeCore
import Foundation

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
        case "preview", "export", "open":
            print("\(command) is planned for the next implementation slice.")
            return .success
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

