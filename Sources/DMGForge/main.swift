import DMGForgeCore
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.isEmpty {
    DMGForgeApp.main()
} else {
    let exitCode = CLI().run(arguments: arguments)
    exit(Int32(exitCode.rawValue))
}

