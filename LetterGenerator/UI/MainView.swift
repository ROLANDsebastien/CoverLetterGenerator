import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    // UI State
    @State private var isDraggingOver: Bool = false
    @State private var showingCVReview: Bool = false
    @State private var newProfileName: String = ""
    @State private var showingSaveProfileAlert: Bool = false

    var body: some View {
        ZStack {
            Color(white: 0.15)
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // MARK: - Left Panel (Controls)
                VStack(spacing: 0) {
                    Spacer().frame(height: 50) // Space for traffic lights in unified bar
                    
                    // --- PROFILE SELECTOR ---
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $viewModel.selectedProfile) {
                            Text(I18n.t("label_load_profile")).tag(nil as UserProfile?)
                            ForEach(viewModel.profiles) { profile in
                                Text(profile.profileName).tag(profile as UserProfile?)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .onChange(of: viewModel.selectedProfile) { newValue in
                            if let profile = newValue {
                                viewModel.loadProfile(profile)
                            }
                        }
                        
                        // Save Profile Button
                        Button(action: {
                            newProfileName = viewModel.selectedProfile?.profileName ?? ""
                            showingSaveProfileAlert = true
                        }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderless)
                        .help(I18n.t("button_save_profile"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)
                    
                    Divider()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 25) {
                            
                            // 1. Profile & CV Section
                            VStack(alignment: .leading, spacing: 15) {
                                SectionHeader(title: I18n.t("section_context"), icon: "person.text.rectangle")
                                
                                // Drop Zone
                                DropZoneView(
                                    fileName: viewModel.cvFileName,
                                    isLoaded: !viewModel.cvText.isEmpty,
                                    isDraggingOver: $isDraggingOver,
                                    onDrop: { providers in
                                        viewModel.handleDrop(providers: providers) { _, _, _ in }
                                    },
                                    onReview: {
                                        showingCVReview = true
                                    }
                                )
                                
                                // Personal Details Form (Bound to ViewModel directly now)
                                VStack(spacing: 12) {
                                    InputField(icon: "person", placeholder: I18n.t("placeholder_full_name"), text: $viewModel.userName)
                                    InputField(icon: "phone", placeholder: I18n.t("placeholder_phone"), text: $viewModel.userPhone)
                                    InputField(icon: "envelope", placeholder: I18n.t("placeholder_email"), text: $viewModel.userEmail)
                                }
                                .padding(15)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                            }

                            // 2. Job Description Section
                            VStack(alignment: .leading, spacing: 15) {
                                SectionHeader(title: I18n.t("section_job_description"), icon: "briefcase")
                                
                                TextEditor(text: $viewModel.jobDescription)
                                    .font(.body)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                            }

                            // 3. AI Options & Tone
                            VStack(alignment: .leading, spacing: 15) {
                                SectionHeader(title: I18n.t("section_options"), icon: "gearshape.2")
                                
                                // Model Picker
                                Picker(I18n.t("label_ai_model"), selection: $viewModel.selectedModel) {
                                    ForEach(viewModel.availableModels) { model in
                                        Text(model.displayName).tag(model)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(8)
                                
                                // Tone Picker
                                Picker(I18n.t("label_tone"), selection: $viewModel.selectedTone) {
                                    ForEach(LetterTone.allCases) { tone in
                                        Text(tone.displayName).tag(tone)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(8)
                                
                                // Theme Picker
                                Picker(I18n.t("label_theme"), selection: $viewModel.selectedTheme) {
                                    ForEach(PDFTheme.allCases) { theme in
                                        Text(theme.displayName).tag(theme)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(8)
                                
                                TextField(I18n.t("placeholder_custom_instructions"), text: $viewModel.customInstructions)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Footer: Generate Button (Enhanced Status)
                    Divider()
                        .padding(.top, 10)
                    
                    GenerateButton(
                        isGenerating: viewModel.isGenerating,
                        currentStep: viewModel.currentStep,
                        isDisabled: viewModel.isGenerating || viewModel.jobDescription.isEmpty || viewModel.cvText.isEmpty,
                        action: {
                            viewModel.generateLetter(userName: viewModel.userName, userPhone: viewModel.userPhone, userEmail: viewModel.userEmail)
                        }
                    )
                    .padding(20)
                }
                .frame(width: 380)
                .zIndex(1)

                // MARK: - Right Panel (Preview)
                ZStack {
                    OutputView(
                        text: $viewModel.generatedLetter,
                        userName: viewModel.userName,
                        userPhone: viewModel.userPhone,
                        userEmail: viewModel.userEmail,
                        selectedTheme: viewModel.selectedTheme,
                        onExport: viewModel.prepareExport
                    )
                    .padding(40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .navigationTitle(I18n.t("app_title"))
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { viewModel.showHistory = true }) {
                    Label(I18n.t("history_title"), systemImage: "clock.arrow.circlepath")
                }
                .help(I18n.t("history_title"))

                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(viewModel.generatedLetter, forType: .string)
                }) {
                    Label(I18n.t("button_copy"), systemImage: "doc.on.doc")
                }
                .disabled(viewModel.generatedLetter.isEmpty)
                .help(I18n.t("button_copy"))

                Button(action: viewModel.prepareExport) {
                    Label(I18n.t("button_export_pdf"), systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.generatedLetter.isEmpty)
                .help(I18n.t("button_export_pdf"))
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
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
        .sheet(isPresented: $showingCVReview) {
            CVReviewSheet(cvText: $viewModel.cvText)
        }
        .sheet(isPresented: $viewModel.showHistory) {
            HistoryView(viewModel: viewModel)
        }
        // SAVE PROFILE ALERT
        .alert(I18n.t("alert_save_profile_title"), isPresented: $showingSaveProfileAlert, actions: {
            TextField(I18n.t("placeholder_profile_name"), text: $newProfileName)
            Button(I18n.t("button_ok")) {
                if !newProfileName.isEmpty {
                    viewModel.saveProfile(name: newProfileName)
                }
            }
            Button("Cancel", role: .cancel) { }
        })
    }
}

// MARK: - CV Review Sheet
struct CVReviewSheet: View {
    @Binding var cvText: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Vérification du contenu du CV")
                    .font(.headline)
                Spacer()
                Button("OK") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.primary.opacity(0.05))
            
            Divider()
            
            TextEditor(text: $cvText)
                .font(.system(size: 13, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Subviews Update
struct DropZoneView: View {
    let fileName: String
    let isLoaded: Bool
    @Binding var isDraggingOver: Bool
    let onDrop: ([NSItemProvider]) -> Bool
    let onReview: () -> Void 
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isDraggingOver ? Color.accentColor : Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .background(isDraggingOver ? Color.accentColor.opacity(0.05) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isDraggingOver)
            
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(isLoaded ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isLoaded ? "checkmark" : (isDraggingOver ? "arrow.down" : "doc.text"))
                        .foregroundStyle(isLoaded ? .green : .blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName.isEmpty ? I18n.t("placeholder_drag_drop") : fileName)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    if isLoaded {
                        Button(action: onReview) {
                            Text("Voir/Modifier le texte")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("PDF format")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
        }
        .frame(height: 70)
        .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
            return onDrop(providers)
        }
    }
}

// Keep HistoryView, HeaderView, SectionHeader, InputField, GenerateButton as is...
struct HeaderView: View {
    @Binding var showHistory: Bool 
    var body: some View {
        EmptyView()
            .padding(.top, 40) // Keep spacing for traffic lights
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

struct InputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
    }
}

struct GenerateButton: View {
    let isGenerating: Bool
    let currentStep: GenerationStep
    let isDisabled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                LinearGradient(
                    colors: isDisabled ? [Color.gray.opacity(0.3), Color.gray.opacity(0.3)] : [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(isDisabled ? 0.3 : 1.0)
                HStack(spacing: 10) {
                    if isGenerating {
                        ProgressView().controlSize(.small).colorInvert().brightness(10)
                        Text(currentStep.rawValue).font(.system(size: 14, weight: .medium)).transition(.opacity)
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 16, weight: .bold))
                        Text(I18n.t("button_generate")).font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .animation(.smooth, value: currentStep)
            }
            .frame(height: 50)
            .cornerRadius(12)
            .shadow(color: isDisabled ? .clear : .blue.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct HistoryView: View {
    @ObservedObject var viewModel: MainViewModel
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = I18n.t("history_date_format")
        return formatter
    }()
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(I18n.t("history_title")).font(.headline)
                Spacer()
                Button("Fermer") { viewModel.showHistory = false }.buttonStyle(.borderless)
            }
            .padding().background(Color.primary.opacity(0.05))
            Divider()
            
            if viewModel.history.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "clock").font(.system(size: 40)).foregroundColor(.secondary)
                    Text(I18n.t("history_empty")).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.history) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                                Text(dateFormatter.string(from: item.date)).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(I18n.t("history_load")) { viewModel.restoreHistoryItem(item) }
                                .buttonStyle(.borderedProminent).controlSize(.small)
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                if let index = viewModel.history.firstIndex(of: item) {
                                    viewModel.deleteHistoryItem(at: IndexSet(integer: index))
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in viewModel.deleteHistoryItem(at: indexSet) }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden) // Ensure list doesn't have its own background
            }
        }
        .background(Color(white: 0.15))
        .frame(width: 400, height: 500)
    }
}

struct OutputView: View {
    @Binding var text: String
    var userName: String
    var userPhone: String
    var userEmail: String
    var selectedTheme: PDFTheme 
    
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Paper View
            ZStack(alignment: .topTrailing) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    
                    // --- THEME-AWARE HEADER ---
                    VStack(spacing: 8) {
                        if !userName.isEmpty {
                            Text(userName)
                                .font(fontForName(theme: selectedTheme))
                                .foregroundColor(colorForName(theme: selectedTheme))
                        }
                        
                        let contactLine = [userPhone, userEmail].filter { !$0.isEmpty }.joined(separator: "  •  ")
                        if !contactLine.isEmpty {
                            Text(contactLine)
                                .font(fontForContact(theme: selectedTheme))
                                .foregroundColor(colorForContact(theme: selectedTheme))
                        }
                        
                        DividerView(theme: selectedTheme, color: colorForName(theme: selectedTheme))
                            .padding(.top, 5)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 40)
                    
                    // --- BODY ---
                    TextEditor(text: $text)
                        .font(fontForBody(theme: selectedTheme))
                        .lineSpacing(4)
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 36)
                        .padding(.top, 10)
                        .scrollContentBackground(.hidden)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: 650)
            .aspectRatio(1 / 1.414, contentMode: .fit)
        }
    }
    
    // Theme Helpers
    func fontForName(theme: PDFTheme) -> Font {
        switch theme {
        case .standard: return .custom("Helvetica-Bold", size: 18)
        case .modern: return .custom("Avenir-Heavy", size: 22) // Heavier
        case .classic: return .custom("Times-Bold", size: 20)
        }
    }
    
    func colorForName(theme: PDFTheme) -> Color {
        switch theme {
        case .standard, .classic: return .black
        case .modern: return Color(red: 0.0, green: 0.3, blue: 0.6) // Yale Blue
        }
    }
    
    func fontForContact(theme: PDFTheme) -> Font {
        switch theme {
        case .standard: return .custom("Helvetica", size: 10)
        case .modern: return .custom("Avenir-Medium", size: 9)
        case .classic: return .custom("Times-Roman", size: 11)
        }
    }
    
    func colorForContact(theme: PDFTheme) -> Color {
        switch theme {
        case .standard: return .gray
        case .modern: return Color(red: 0.2, green: 0.4, blue: 0.7)
        case .classic: return .gray
        }
    }
    
    func fontForBody(theme: PDFTheme) -> Font {
        switch theme {
        case .standard: return .custom("Helvetica Neue", size: 11)
        case .modern: return .custom("Avenir-Book", size: 10)
        case .classic: return .custom("Times-Roman", size: 11)
        }
    }
}

struct DividerView: View {
    let theme: PDFTheme
    let color: Color
    
    var body: some View {
        switch theme {
        case .standard:
            Divider()
        case .modern:
            Rectangle()
                .fill(color)
                .frame(height: 2)
        case .classic:
            EmptyView()
        }
    }
}

struct PDFDocumentWrapper: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    var text: String
    var userDetails: (name: String, phone: String, email: String)
    var theme: PDFTheme
    
    init(text: String, userDetails: (name: String, phone: String, email: String) = ("", "", ""), theme: PDFTheme = .standard) {
        self.text = text
        self.userDetails = userDetails
        self.theme = theme
    }
    
    init(configuration: ReadConfiguration) throws {
        self.text = ""
        self.userDetails = ("", "", "")
        self.theme = .standard
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp.pdf")
        if PDFService.generatePDF(from: text, userDetails: userDetails, theme: theme, to: tempURL) {
            let data = try Data(contentsOf: tempURL)
            return FileWrapper(regularFileWithContents: data)
        } else {
            throw CocoaError(.fileWriteUnknown)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View { MainView() }
}