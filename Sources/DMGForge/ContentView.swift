import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DMGForge")
                .font(.largeTitle.bold())

            Text("Open a .dmgproject to review and export a polished drag-to-install DMG.")
                .foregroundStyle(.secondary)

            HStack {
                Button("Open Project...") {}
                Button("New Project...") {}
            }
        }
        .padding(28)
        .frame(width: 560, height: 260)
    }
}

