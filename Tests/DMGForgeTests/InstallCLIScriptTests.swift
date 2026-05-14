import Foundation
import Testing

@Test func installCLIScriptCreatesLinkAndVerifiesHelp() throws {
    let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let scriptURL = repoRoot.appendingPathComponent("scripts/install-cli.sh")
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let appURL = tempRoot.appendingPathComponent("DMGForge.app", isDirectory: true)
    let binaryURL = appURL.appendingPathComponent("Contents/MacOS/dmgforge")
    let linkURL = tempRoot.appendingPathComponent("bin/dmgforge")
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    try FileManager.default.createDirectory(
        at: binaryURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try """
    #!/usr/bin/env bash
    if [[ "${1:-}" == "help" ]]; then
      echo "DMGForge"
      exit 0
    fi
    exit 2
    """.write(to: binaryURL, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryURL.path)

    let result = try runScript(
        scriptURL,
        environment: [
            "DMGFORGE_APP_PATH": appURL.path,
            "DMGFORGE_CLI_LINK_PATH": linkURL.path
        ]
    )

    #expect(result.status == 0)
    #expect(FileManager.default.fileExists(atPath: linkURL.path))
    #expect(try FileManager.default.destinationOfSymbolicLink(atPath: linkURL.path) == binaryURL.path)
    #expect(result.output.contains("Installed dmgforge CLI"))
    #expect(result.output.contains("Verified dmgforge help"))
}

private func runScript(_ scriptURL: URL, environment: [String: String]) throws -> (status: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [scriptURL.path]
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    process.waitUntilExit()

    let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    return (process.terminationStatus, output)
}
