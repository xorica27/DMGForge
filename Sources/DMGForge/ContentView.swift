import AppKit
import DMGForgeCore
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ProjectEditorViewModel()

    var body: some View {
        HStack(spacing: 0) {
            editorPane
                .frame(width: 360)

            Divider()

            previewPane
                .frame(minWidth: 560, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        }
        .frame(minWidth: 980, minHeight: 680)
    }

    private var editorPane: some View {
        VStack(spacing: 0) {
            toolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            Form {
                projectSection
                backgroundSection
                firstLaunchGuideSection
                arrowSection
                layoutSection
                validationSection
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.newProject()
            } label: {
                Label("New", systemImage: "plus")
            }

            Button {
                viewModel.openProjectWithPanel()
            } label: {
                Label("Open", systemImage: "folder")
            }

            Button {
                viewModel.saveProject()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }

            Spacer()

            Button {
                viewModel.exportDMG()
            } label: {
                Label("Export", systemImage: "shippingbox")
            }
            .disabled(!viewModel.validationIssues.isEmpty)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
    }

    private var projectSection: some View {
        Section("Project") {
            TextField("App name", text: $viewModel.project.appName)
            TextField("Version", text: $viewModel.project.version)
            TextField("Volume name", text: $viewModel.project.volumeName)

            pathField(
                title: "App bundle",
                value: $viewModel.project.appPath,
                buttonTitle: "Choose",
                action: viewModel.chooseAppBundleWithPanel
            )

            pathField(
                title: "Output DMG",
                value: $viewModel.project.outputPath,
                buttonTitle: "Choose",
                action: viewModel.chooseOutputDMGWithPanel
            )
        }
    }

    private var backgroundSection: some View {
        Section("Background") {
            Picker("Mode", selection: backgroundModeBinding) {
                Text("Generated").tag(DMGBackgroundMode.generated.rawValue)
                Text("Image").tag(DMGBackgroundMode.image.rawValue)
            }
            .pickerStyle(.segmented)

            if viewModel.project.background.mode == .image {
                pathField(
                    title: "Image",
                    value: imagePathBinding,
                    buttonTitle: "Choose",
                    action: viewModel.chooseBackgroundImageWithPanel
                )
            }

            TextField("Title", text: $viewModel.project.background.title)
            TextField("Description", text: $viewModel.project.background.description, axis: .vertical)
                .lineLimit(2...4)
            TextField("Footer", text: $viewModel.project.background.footer)
        }
    }

    private var layoutSection: some View {
        Section("Layout") {
            HStack {
                TextField("Width", value: $viewModel.project.window.width, format: .number)
                TextField("Height", value: $viewModel.project.window.height, format: .number)
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("App icon")
                        .foregroundStyle(.secondary)
                    TextField("X", value: $viewModel.project.layout.appIcon.x, format: .number)
                    TextField("Y", value: $viewModel.project.layout.appIcon.y, format: .number)
                }

                GridRow {
                    Text("Applications")
                        .foregroundStyle(.secondary)
                    TextField("X", value: $viewModel.project.layout.applicationsIcon.x, format: .number)
                    TextField("Y", value: $viewModel.project.layout.applicationsIcon.y, format: .number)
                }

                if viewModel.project.firstLaunchGuide.enabled {
                    GridRow {
                        Text("Security help")
                            .foregroundStyle(.secondary)
                        TextField("X", value: $viewModel.project.firstLaunchGuide.securitySettingsIcon.x, format: .number)
                        TextField("Y", value: $viewModel.project.firstLaunchGuide.securitySettingsIcon.y, format: .number)
                    }

                    GridRow {
                        Text("Help file")
                            .foregroundStyle(.secondary)
                        TextField("X", value: $viewModel.project.firstLaunchGuide.helpFileIcon.x, format: .number)
                        TextField("Y", value: $viewModel.project.firstLaunchGuide.helpFileIcon.y, format: .number)
                    }
                }
            }
        }
    }

    private var firstLaunchGuideSection: some View {
        Section("First Launch Help") {
            Toggle("Include unsigned-app helper", isOn: firstLaunchGuideEnabledBinding)

            if viewModel.project.firstLaunchGuide.enabled {
                TextField("Security shortcut", text: $viewModel.project.firstLaunchGuide.securitySettingsShortcutName)
                TextField("Help file", text: $viewModel.project.firstLaunchGuide.helpFileName)
                TextField("Security URL", text: $viewModel.project.firstLaunchGuide.securitySettingsURL)
                TextField("Help text", text: $viewModel.project.firstLaunchGuide.helpText, axis: .vertical)
                    .lineLimit(4...8)
            }
        }
    }

    private var arrowSection: some View {
        Section("Guide Arrow") {
            Toggle("Visible", isOn: $viewModel.project.guideArrow.visible)

            TextField("Color", text: $viewModel.project.guideArrow.color)
                .textFieldStyle(.roundedBorder)

            Stepper(
                "Thickness: \(viewModel.project.guideArrow.thickness)",
                value: $viewModel.project.guideArrow.thickness,
                in: 1...24
            )
        }
    }

    private var validationSection: some View {
        Section("Validation") {
            if viewModel.validationIssues.isEmpty {
                Label("Ready to export", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            } else {
                ForEach(Array(viewModel.validationIssues.enumerated()), id: \.offset) { _, issue in
                    Text(issue.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DMGForge")
                        .font(.largeTitle.bold())
                    Text(projectSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    viewModel.refreshPreview()
                } label: {
                    Label("Refresh Preview", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .windowBackgroundColor))

                if let previewImage = viewModel.previewImage {
                    Image(nsImage: previewImage)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .padding(24)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 36))
                            .foregroundStyle(.tertiary)
                        Text("Preview unavailable")
                            .font(.headline)
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.08))
            }

            HStack {
                Label("\(viewModel.project.window.width)x\(viewModel.project.window.height)", systemImage: "rectangle")
                Label(viewModel.project.background.mode == .image ? "Custom image" : "Generated", systemImage: "photo.on.rectangle")
                Spacer()
                Text(viewModel.projectURL?.path ?? "Unsaved project")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var projectSubtitle: String {
        "\(viewModel.project.appName) \(viewModel.project.version)"
    }

    private var backgroundModeBinding: Binding<String> {
        Binding(
            get: { viewModel.project.background.mode.rawValue },
            set: { rawValue in
                if rawValue == DMGBackgroundMode.generated.rawValue {
                    viewModel.setGeneratedBackground()
                } else {
                    viewModel.project.background.mode = .image
                }
            }
        )
    }

    private var imagePathBinding: Binding<String> {
        Binding(
            get: { viewModel.project.background.imagePath ?? "" },
            set: { newValue in
                viewModel.project.background.imagePath = newValue.isEmpty ? nil : newValue
            }
        )
    }

    private var firstLaunchGuideEnabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.project.firstLaunchGuide.enabled },
            set: { viewModel.setFirstLaunchGuideEnabled($0) }
        )
    }

    private func pathField(
        title: String,
        value: Binding<String>,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField(title, text: value)
                    .textFieldStyle(.roundedBorder)

                if !buttonTitle.isEmpty {
                    Button(buttonTitle, action: action)
                }
            }
        }
    }
}
