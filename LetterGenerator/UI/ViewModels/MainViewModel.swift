import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine
import NaturalLanguage

struct I18n {
    static var language: String {
        // Check user's preferred languages order. This works even if the app doesn't officially 'support' the language in Info.plist.
        if let preferred = Locale.preferredLanguages.first, preferred.lowercased().hasPrefix("fr") {
            return "fr"
        }
        return "en"
    }
    
    private static let en = [
        "app_title": "AI Cover Letter Generator",
        "section_context": "1. Context",
        "section_job_description": "2. Job Description",
        "section_options": "3. Options",
        "section_generated_letter": "Generated Letter",
        "placeholder_drag_drop": "Drag & Drop your CV PDF here",
        "status_loaded": "✓ Loaded",
        "label_ai_model": "AI Model",
        "placeholder_custom_instructions": "Custom Instructions (Tone, Focus...)",
        "placeholder_full_name": "Full Name",
        "placeholder_phone": "Phone",
        "placeholder_email": "Email",
        "button_generate": "Generate Letter",
        "button_export_pdf": "Export as PDF",
        "button_ok": "OK",
        "alert_export_success_title": "Export Successful",
        "alert_export_success_message": "Your cover letter has been saved successfully.",
        "alert_drop_error_title": "Drop Error",
        "drop_error_only_pdf": "Only PDF files are supported",
        "header_gemini": "Gemini (CLI)",
        "header_opencode": "OpenCode (Local)",
        "header_mistral": "Mistral (Vibe)"
    ]
    
    private static let fr = [
        "app_title": "Générateur de Lettre de Motivation IA",
        "section_context": "1. Contexte",
        "section_job_description": "2. Description du Poste",
        "section_options": "3. Options",
        "section_generated_letter": "Lettre Générée",
        "placeholder_drag_drop": "Glissez-déposez votre CV PDF ici",
        "status_loaded": "✓ Chargé",
        "label_ai_model": "Modèle IA",
        "placeholder_custom_instructions": "Instructions personnalisées (Ton, Focus...)",
        "placeholder_full_name": "Nom complet",
        "placeholder_phone": "Téléphone",
        "placeholder_email": "Email",
        "button_generate": "Générer la Lettre",
        "button_export_pdf": "Exporter en PDF",
        "button_ok": "OK",
        "alert_export_success_title": "Export Réussi",
        "alert_export_success_message": "Votre lettre de motivation a été enregistrée avec succès.",
        "alert_drop_error_title": "Erreur de Fichier",
        "drop_error_only_pdf": "Seuls les fichiers PDF sont supportés",
        "header_gemini": "Gemini (CLI)",
        "header_opencode": "OpenCode (Local)",
        "header_mistral": "Mistral (Vibe)"
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
    @Published var cvText: String = ""
    @Published var cvFileName: String = ""
    @Published var selectedModel: AIService.AIModel = .gemini3Flash
    
    // MARK: - Output State
    @Published var generatedLetter: String = ""
    @Published var isGenerating: Bool = false
    @Published var showingExportSuccess: Bool = false
    @Published var showDropError: Bool = false
    @Published var dropErrorMessage: String = ""
    
    // MARK: - Export State
    @Published var isExporting: Bool = false
    @Published var documentToExport: PDFDocumentWrapper? = nil
    @Published var exportFileName: String = "Cover_Letter"
    
    // MARK: - User Preferences
    // We use AppStorage in the View, but we can sync or access them here if needed. 
    // For MVVM purity, we'll pass these values in when needed, or bind them in the View.
    // However, to keep the logic here, we will accept them as parameters in methods.
    
    // MARK: - Actions
    
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
                        
                        // Extract contact details
                        let details = PDFService.extractContactDetails(from: extractedText)
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
        self.isGenerating = true
        
        // Detect language for filename
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(jobDescription)
        let language = recognizer.dominantLanguage?.rawValue ?? "en"
        self.exportFileName = (language == "fr") ? "Lettre_de_Motivation" : "Cover_Letter"
        
        // Instruction: Detect language from Job Description & Handle Closing
        // We ask AI to include the closing (Sincerely/Cordialement) but NOT the name.
        let smartSignatureInstruction = "Write the letter in the SAME language as the Job Description. End with a professional closing (e.g., 'Sincerely,' or 'Cordialement,') matching that language, but DO NOT write the candidate's name or contact details."
        
        // Append instructions
        let finalInstructions = """
        \(customInstructions)
        IMPORTANT:
        \(smartSignatureInstruction)
        """
        
        AIService.generateCoverLetter(
            jobDescription: jobDescription,
            cvContext: cvText,
            instructions: finalInstructions,
            model: selectedModel
        ) { result in
            self.isGenerating = false
            if let result = result {
                var finalLetter = result.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Append only contact details (AI provides the closing "Sincerely,"/"Cordialement,")
                if !userName.isEmpty || !userPhone.isEmpty || !userEmail.isEmpty {
                    finalLetter += "\n\n"
                    if !userName.isEmpty { finalLetter += "\(userName)\n" }
                    if !userPhone.isEmpty { finalLetter += "\(userPhone)\n" }
                    if !userEmail.isEmpty { finalLetter += "\(userEmail)" }
                }
                self.generatedLetter = finalLetter
            }
        }
    }
    
    func prepareExport() {
        self.documentToExport = PDFDocumentWrapper(text: generatedLetter)
        self.isExporting = true
    }
}
