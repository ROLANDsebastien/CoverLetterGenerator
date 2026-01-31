import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine
import NaturalLanguage

enum LetterTone: String, CaseIterable, Identifiable {
    case professional = "Professional"
    case enthusiastic = "Enthusiastic"
    case confident = "Confident"
    case academic = "Academic" // Good for research/uni
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .professional: return "Professionnel"
        case .enthusiastic: return "Enthousiaste"
        case .confident: return "Confiant"
        case .academic: return "Académique"
        }
    }
    
    var promptInstruction: String {
        switch self {
        case .professional: return "Use a formal, respectful, and polished tone."
        case .enthusiastic: return "Use an energetic, passionate, and eager tone."
        case .confident: return "Use a bold, assertive, and highly persuasive tone."
        case .academic: return "Use a scholarly, structured, and precise tone."
        }
    }
}

enum GenerationStep: String {
    case idle
    case analyzing = "Analyse du CV et de l'offre..."
    case thinking = "Recherche des meilleurs arguments..."
    case writing = "Rédaction de votre lettre..."
    case polishing = "Finitions..."
}

struct I18n {
    static var language: String {
        // Check user's preferred languages order.
        if let preferred = Locale.preferredLanguages.first, preferred.lowercased().hasPrefix("fr") {
            return "fr"
        }
        return "en"
    }
    
    private static let en = [
        "app_title": "AI Cover Letter Generator",
        "section_context": "1. Context",
        "section_job_description": "2. Job Description",
        "section_options": "3. Options & Tone",
        "section_generated_letter": "Generated Letter",
        "placeholder_drag_drop": "Drag & Drop your CV PDF here",
        "status_loaded": "✓ Loaded",
        "label_ai_model": "AI Model",
        "label_tone": "Tone",
        "label_theme": "PDF Theme",
        "placeholder_custom_instructions": "Custom Instructions (Tone, Focus...)",
        "placeholder_full_name": "Full Name",
        "placeholder_phone": "Phone",
        "placeholder_email": "Email",
        "button_generate": "Generate Letter",
        "button_export_pdf": "Export as PDF",
        "button_copy": "Copy to Clipboard",
        "button_ok": "OK",
        "alert_export_success_title": "Export Successful",
        "alert_export_success_message": "Your cover letter has been saved successfully.",
        "alert_drop_error_title": "Drop Error",
        "drop_error_only_pdf": "Only PDF files are supported",
        "header_gemini": "Gemini (CLI)",
        "header_opencode": "OpenCode (Local)",
        "header_mistral": "Mistral (Vibe)",
        "history_title": "History",
        "history_empty": "No generated letters yet.",
        "history_load": "Load",
        "history_date_format": "MMM d, HH:mm",
        "section_profile": "Profile & Identity",
        "label_load_profile": "Load Profile...",
        "button_save_profile": "Save Current Profile",
        "alert_save_profile_title": "Profile Name",
        "placeholder_profile_name": "e.g. Senior Developer"
    ]
    
    private static let fr = [
        "app_title": "Générateur de Lettre de Motivation IA",
        "section_context": "1. Contexte",
        "section_job_description": "2. Description du Poste",
        "section_options": "3. Options & Ton",
        "section_generated_letter": "Lettre Générée",
        "placeholder_drag_drop": "Glissez-déposez votre CV PDF ici",
        "status_loaded": "✓ Chargé",
        "label_ai_model": "Modèle IA",
        "label_tone": "Ton",
        "label_theme": "Thème PDF",
        "placeholder_custom_instructions": "Instructions personnalisées (Ton, Focus...)",
        "placeholder_full_name": "Nom complet",
        "placeholder_phone": "Téléphone",
        "placeholder_email": "Email",
        "button_generate": "Générer la Lettre",
        "button_export_pdf": "Exporter en PDF",
        "button_copy": "Copier",
        "button_ok": "OK",
        "alert_export_success_title": "Export Réussi",
        "alert_export_success_message": "Votre lettre de motivation a été enregistrée avec succès.",
        "alert_drop_error_title": "Erreur de Fichier",
        "drop_error_only_pdf": "Seuls les fichiers PDF sont supportés",
        "header_gemini": "Gemini (CLI)",
        "header_opencode": "OpenCode (Local)",
        "header_mistral": "Mistral (Vibe)",
        "history_title": "Historique",
        "history_empty": "Aucune lettre générée pour le moment.",
        "history_load": "Charger",
        "history_date_format": "d MMM, HH:mm",
        "section_profile": "Profils & Identité",
        "label_load_profile": "Charger un profil...",
        "button_save_profile": "Sauvegarder ce profil",
        "alert_save_profile_title": "Nom du profil",
        "placeholder_profile_name": "Ex: Développeur Senior"
    ]
    
    static func t(_ key: String) -> String {
        let dict = (language == "fr") ? fr : en
        return dict[key] ?? key
    }
}

@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Input State
    @Published var jobDescription: String = ""
    @Published var customInstructions: String = ""
    @Published var selectedTone: LetterTone = .professional
    @Published var cvText: String = ""
    @Published var cvFileName: String = ""
    @Published var selectedTheme: PDFTheme = .standard
    
    // Custom Defaults Suite to avoid conflicts
    private let defaults = UserDefaults(suiteName: "CoverLetterGenerator")
    
    // Migrated from AppStorage (Now ViewModel Source of Truth for better Profile management)
    @Published var userName: String = ""
    @Published var userPhone: String = ""
    @Published var userEmail: String = ""
    
    // NEW: Profile Management
    @Published var profiles: [UserProfile] = []
    @Published var selectedProfile: UserProfile? = nil // For Picker
    
    @Published var selectedModel: AIService.AIModelInfo = AIService.AIModelInfo(id: "loading", modelName: "loading", displayName: "Loading...", provider: "gemini", executablePath: "")
    @Published var availableModels: [AIService.AIModelInfo] = []
    
    // MARK: - Output State
    @Published var generatedLetter: String = ""
    @Published var isGenerating: Bool = false
    @Published var currentStep: GenerationStep = .idle 
    
    @Published var showingExportSuccess: Bool = false
    
    // MARK: - Error Handling State
    @Published var showDropError: Bool = false
    @Published var dropErrorMessage: String = ""
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Export State
    @Published var isExporting: Bool = false
    @Published var documentToExport: PDFDocumentWrapper? = nil
    @Published var exportFileName: String = "Cover_Letter"
    
    // MARK: - History State
    @Published var history: [HistoryItem] = []
    @Published var showHistory: Bool = false
    @Published var currentHistoryItemId: UUID? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load Defaults from Custom Suite
        self.userName = defaults?.string(forKey: "userName") ?? ""
        self.userPhone = defaults?.string(forKey: "userPhone") ?? ""
        self.userEmail = defaults?.string(forKey: "userEmail") ?? ""

        Task {
            let loadedHistory = HistoryService.load()
            let loadedProfiles = ProfileService.load()
            
            await MainActor.run {
                self.history = loadedHistory
                self.profiles = loadedProfiles
            }
            
            await loadModels()
        }
        
        // Auto-save edits to history
        $generatedLetter
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newText in
                self?.updateCurrentHistoryItem(with: newText)
            }
            .store(in: &cancellables)
    }
    
    func loadModels() async {
        let models = await AIService.fetchAvailableModels()
        self.availableModels = models
        if let first = models.first {
            self.selectedModel = first
        }
    }
    
    // MARK: - Actions
    
    func saveProfile(name: String) {
        let newProfile = UserProfile(
            profileName: name,
            fullName: self.userName,
            phone: self.userPhone,
            email: self.userEmail,
            customInstructions: self.customInstructions,
            preferredToneRawValue: self.selectedTone.rawValue
        )
        
        // Update if exists or append
        if let existingIndex = profiles.firstIndex(where: { $0.profileName == name }) {
            profiles[existingIndex] = newProfile
        } else {
            profiles.append(newProfile)
        }
        
        profiles.sort(by: { $0.profileName < $1.profileName })
        ProfileService.save(profiles)
        self.selectedProfile = newProfile
    }
    
    func loadProfile(_ profile: UserProfile) {
        self.userName = profile.fullName
        self.userPhone = profile.phone
        self.userEmail = profile.email
        self.customInstructions = profile.customInstructions
        if let toneRaw = profile.preferredToneRawValue, let tone = LetterTone(rawValue: toneRaw) {
            self.selectedTone = tone
        }
        self.selectedProfile = profile
    }
    
    func deleteProfile(_ profile: UserProfile) {
        profiles.removeAll(where: { $0.id == profile.id })
        ProfileService.save(profiles)
        if selectedProfile == profile {
            selectedProfile = nil
        }
    }
    
    func handleDrop(providers: [NSItemProvider], completion: @escaping (String?, String?, String?) -> Void) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                print("❌ Drop error: invalid URL")
                return
            }
            
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let fileName = url.lastPathComponent
            
            if url.pathExtension.lowercased() == "pdf" {
                if let extractedText = PDFService.extractText(from: url) {
                    Task { @MainActor in
                        self.cvFileName = fileName
                        self.cvText = extractedText
                        let details = PDFService.extractContactDetails(from: extractedText)
                        
                        // Auto-fill logic (Updating ViewModel directly now)
                        if let name = details.name, !name.isEmpty { self.userName = name }
                        if let phone = details.phone, !phone.isEmpty { self.userPhone = phone }
                        if let email = details.email, !email.isEmpty { self.userEmail = email }
                        
                        completion(details.name, details.phone, details.email)
                    }
                }
            } else {
                Task { @MainActor in
                    self.dropErrorMessage = I18n.t("drop_error_only_pdf")
                    self.showDropError = true
                }
            }
        }
        return true
    }
    
    func generateLetter(userName: String, userPhone: String, userEmail: String) {
        // Save these as "Last Used" in UserDefaults for persistence across restarts without profiles
        defaults?.set(userName, forKey: "userName")
        defaults?.set(userPhone, forKey: "userPhone")
        defaults?.set(userEmail, forKey: "userEmail")
        
        self.isGenerating = true
        self.currentStep = .analyzing 
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(jobDescription)
        let language = recognizer.dominantLanguage?.rawValue ?? "en"
        self.exportFileName = (language == "fr") ? "Lettre_de_Motivation" : "Cover_Letter"
        
        let smartSignatureInstruction = "Write the letter in the SAME language as the Job Description. End with a professional closing (e.g., 'Sincerely,' or 'Cordialement,') matching that language, but DO NOT write the candidate's name or contact details."
        
        // Strict length constraint
        let lengthInstruction = "STRICT LENGTH LIMIT: The letter MUST be concise and fit on a single A4 page (approximately 250-300 words). Focus on quality over quantity."

        let finalInstructions = """
        TONE: \(selectedTone.promptInstruction)
        
        LENGTH_CONSTRAINT:
        \(lengthInstruction)
        
        ADDITIONAL INSTRUCTIONS:
        \(customInstructions)
        
        IMPORTANT:
        \(smartSignatureInstruction)
        """
        
        Task {
            // Simulated steps for UX
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run { self.currentStep = .thinking }
            
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run { self.currentStep = .writing }
            
            AIService.generateCoverLetter(
                jobDescription: jobDescription,
                cvContext: cvText,
                instructions: finalInstructions,
                model: selectedModel
            ) { result in
                
                Task { @MainActor in
                     self.currentStep = .polishing
                     try? await Task.sleep(nanoseconds: 500_000_000)
                    
                    self.isGenerating = false
                    self.currentStep = .idle
                    
                    switch result {
                    case .success(let output):
                        var finalLetter = output.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Append Name as Signature
                        if !userName.isEmpty {
                             finalLetter += "\n\n\(userName)"
                        }
                        
                        self.generatedLetter = finalLetter
                        
                        // SAVE TO HISTORY
                        let newItem = HistoryItem(
                            date: Date(),
                            jobDescription: self.jobDescription,
                            generatedLetter: finalLetter,
                            toneRawValue: self.selectedTone.rawValue
                        )
                        self.currentHistoryItemId = newItem.id
                        self.history.insert(newItem, at: 0)
                        HistoryService.save(self.history)
                        
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                }
            }
        }
    }
    
    // MARK: - History Management
    
    func deleteHistoryItem(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        HistoryService.save(history)
    }
    
    func restoreHistoryItem(_ item: HistoryItem) {
        self.jobDescription = item.jobDescription
        self.generatedLetter = item.generatedLetter
        if let tone = LetterTone(rawValue: item.toneRawValue) {
            self.selectedTone = tone
        }
        self.currentHistoryItemId = item.id
        self.showHistory = false
    }
    
    private func updateCurrentHistoryItem(with text: String) {
        guard let id = currentHistoryItemId, !text.isEmpty else { return }
        
        if let index = history.firstIndex(where: { $0.id == id }) {
            // Only update if changed
            if history[index].generatedLetter != text {
                history[index].generatedLetter = text
                HistoryService.save(history)
            }
        }
    }
    
    func prepareExport() {
        // Retrieve details for export (using ViewModel source of truth)
        let details = (name: self.userName, phone: self.userPhone, email: self.userEmail)
                       
        self.documentToExport = PDFDocumentWrapper(text: generatedLetter, userDetails: details, theme: selectedTheme)
        self.isExporting = true
    }
}
