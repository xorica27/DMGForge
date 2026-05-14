import DMGForgeCore
import AppKit
import SwiftUI

struct ContentView: View {
    @State private var previewImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("DMGForge")
                    .font(.largeTitle.bold())

                Spacer()

                Text("Preview")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if let previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.08))
                    }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 320)
            }

            Text("Open a .dmgproject to review the installer visual, tweak copy and layout, then export a release-ready DMG.")
                .foregroundStyle(.secondary)

            HStack {
                Button("Open Project...") {}
                Button("New Project...") {}
            }
        }
        .padding(28)
        .frame(width: 760, height: 640)
        .task {
            previewImage = Self.makeDefaultPreview()
        }
    }

    private static func makeDefaultPreview() -> NSImage? {
        let project = DMGProjectFactory.makeDefault(
            appPath: "dist/MyApp.app",
            appName: "MyApp",
            version: "1.0.0"
        )
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("dmgforge-default-preview.png")

        try? PreviewRenderer().render(project: project, to: outputURL)
        return NSImage(contentsOf: outputURL)
    }
}
