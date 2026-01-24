import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    // User Personal Info (Stored in AppStorage)
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    
    // UI State for Dragging (View-specific)
    @State private var isDraggingOver: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            HeaderView()

            HStack(spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 15) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            // 1. Context
                            Text(I18n.t("section_context"))
                                .font(.headline)
                            
                            DropZoneView(
                                fileName: viewModel.cvFileName,
                                isLoaded: !viewModel.cvText.isEmpty,
                                isDraggingOver: $isDraggingOver,
                                onDrop: { providers in
                                    viewModel.handleDrop(providers: providers) { name, phone, email in
                                        if let name = name { self.userName = name }
                                        if let phone = phone { self.userPhone = phone }
                                        if let email = email { self.userEmail = email }
                                    }
                                }
                            )

                            // 2. Job Description
                            Text(I18n.t("section_job_description"))
                                .font(.headline)
                            TextEditor(text: $viewModel.jobDescription)
                                .frame(height: 150)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))

                            // 3. Options
                            Text(I18n.t("section_options"))
                                .font(.headline)
                            
                            ModelPicker(selection: $viewModel.selectedModel, availableModels: viewModel.availableModels)
                            
                            TextField(I18n.t("placeholder_custom_instructions"), text: $viewModel.customInstructions)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.trailing, 5)
                    }

                    GenerateButton(
                        isGenerating: viewModel.isGenerating,
                        isDisabled: viewModel.isGenerating || viewModel.jobDescription.isEmpty || viewModel.cvText.isEmpty,
                        action: {
                            viewModel.generateLetter(userName: userName, userPhone: userPhone, userEmail: userEmail)
                        }
                    )
                }
                .frame(width: 350)

                Divider()

                // Output Section
                OutputView(
                    text: $viewModel.generatedLetter,
                    onExport: viewModel.prepareExport
                )
            }
        }
        .padding(30)
        .frame(minWidth: 850, minHeight: 650)
        .fileExporter(
            isPresented: $viewModel.isExporting,
            document: viewModel.documentToExport,
            contentType: .pdf,
            defaultFilename: viewModel.exportFileName
        ) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
                viewModel.showingExportSuccess = true
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
        .alert(I18n.t("alert_export_success_title"), isPresented: $viewModel.showingExportSuccess) {
            Button(I18n.t("button_ok"), role: .cancel) { }
        } message: {
            Text(I18n.t("alert_export_success_message"))
        }
        .alert(I18n.t("alert_drop_error_title"), isPresented: $viewModel.showDropError) {
            Button(I18n.t("button_ok"), role: .cancel) { }
        } message: {
            Text(viewModel.dropErrorMessage)
        }
        .alert("AI Error", isPresented: $viewModel.showError) {
             Button("OK", role: .cancel) { }
        } message: {
             Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Subviews

struct HeaderView: View {
    var body: some View {
        Text(I18n.t("app_title"))
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom)
    }
}

struct DropZoneView: View {
    let fileName: String
    let isLoaded: Bool
    @Binding var isDraggingOver: Bool
    let onDrop: ([NSItemProvider]) -> Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDraggingOver ? Color.accentColor : Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                .background(isDraggingOver ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                .animation(.easeInOut(duration: 0.2), value: isDraggingOver)
            
            VStack(spacing: 10) {
                Image(systemName: isDraggingOver ? "arrow.down.doc" : "doc.text.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(isDraggingOver ? Color.accentColor : Color.secondary)
                Text(fileName.isEmpty ? I18n.t("placeholder_drag_drop") : fileName)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundStyle(isDraggingOver ? Color.accentColor : Color.primary)
                    .font(.headline)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                if isLoaded {
                    Text(I18n.t("status_loaded"))
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(height: 120)
        .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
            return onDrop(providers)
        }
    }
}

struct ModelPicker: View {
    @Binding var selection: AIService.AIModelInfo
    var availableModels: [AIService.AIModelInfo]
    
    var body: some View {
        Picker(I18n.t("label_ai_model"), selection: $selection) {
            // Section for Gemini
            let geminiModels = availableModels.filter { $0.provider == "gemini" }
            if !geminiModels.isEmpty {
                Section(I18n.t("header_gemini")) {
                    ForEach(geminiModels) { model in
                        Text(model.displayName).tag(model)
                    }
                }
            }
            
            // Section for OpenCode
            let openCodeModels = availableModels.filter { $0.provider == "opencode" }
            if !openCodeModels.isEmpty {
                Section(I18n.t("header_opencode")) {
                    ForEach(openCodeModels) { model in
                        Text(model.displayName).tag(model)
                    }
                }
            }
            
            // Section for Mistral
            let mistralModels = availableModels.filter { $0.provider == "mistral" }
            if !mistralModels.isEmpty {
                Section(I18n.t("header_mistral")) {
                    ForEach(mistralModels) { model in
                        Text(model.displayName).tag(model)
                    }
                }
            }
            
            // Section for others if any
            let otherModels = availableModels.filter { $0.provider != "gemini" && $0.provider != "opencode" && $0.provider != "mistral" }
            if !otherModels.isEmpty {
                Section("Other") {
                    ForEach(otherModels) { model in
                        Text(model.displayName).tag(model)
                    }
                }
            }
        }
    }
}

struct GenerateButton: View {
    let isGenerating: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(I18n.t("button_generate"))
                    .font(.title3.bold())
                    .opacity(isGenerating ? 0 : 1)
                    .scaleEffect(isGenerating ? 0.9 : 1.0)
                
                if isGenerating {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(.white) // In borderedProminent, text is usually white
                        .transition(.opacity.combined(with: .scale(scale: 0.5)))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isGenerating)
    }
}

struct OutputView: View {
    @Binding var text: String
    let onExport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(I18n.t("section_generated_letter"))
                    .font(.headline)
                Spacer()
                if !text.isEmpty {
                    Button(I18n.t("button_export_pdf"), action: onExport)
                        .buttonStyle(.bordered)
                }
            }

            TextEditor(text: $text)
                .font(.system(.body, design: .serif))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
        }
    }
}

// Keeping the wrapper here or move to separate file? Keeping here for now as it's small.
struct PDFDocumentWrapper: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        self.text = ""
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp.pdf")
        if PDFService.generatePDF(from: text, to: tempURL) {
            let data = try Data(contentsOf: tempURL)
            return FileWrapper(regularFileWithContents: data)
        } else {
            throw CocoaError(.fileWriteUnknown)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}