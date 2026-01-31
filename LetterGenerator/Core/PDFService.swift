import Foundation
import PDFKit
import AppKit
import SwiftUI

enum PDFTheme: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case modern = "Modern"
    case classic = "Classic"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .standard: return "Standard (Helvetica)"
        case .modern: return "Moderne (Bleu & Sans-Serif)"
        case .classic: return "Classique (Times & Serif)"
        }
    }
}

class PDFService {
    
    /// Extract text from a PDF file
    static func extractText(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                fullText += page.string ?? ""
            }
        }
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extract contact details (Name, Phone, Email) from text
    static func extractContactDetails(from text: String) -> (name: String?, phone: String?, email: String?) {
        var name: String? = nil
        var phone: String? = nil
        var email: String? = nil
        
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        if let firstLine = lines.first, firstLine.count < 50 {
            name = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        if let emailRange = text.range(of: emailPattern, options: .regularExpression) {
            email = String(text[emailRange])
        }
        
        let phonePattern = "(?:(?:\\+|00)33|0)\\s*[1-9](?:[\\s.-]*\\d{2}){4}"
        if let phoneRange = text.range(of: phonePattern, options: .regularExpression) {
            phone = String(text[phoneRange])
        }
        
        return (name, phone, email)
    }
    
    /// Generate a PDF with a styled header based on the selected theme
    static func generatePDF(from text: String, userDetails: (name: String, phone: String, email: String), theme: PDFTheme, to outputURL: URL) -> Bool {
        // A4 Size
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 72.0 // 1 inch
        
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            return false
        }
        
        let mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        context.beginPDFPage(nil)
        
        // --- 1. SETUP STYLES BASED ON THEME ---
        var nameFont: NSFont
        var contactFont: NSFont
        var bodyFont: NSFont
        var nameColor: NSColor
        var accentColor: NSColor
        let separatorStyle: Int // 0: Line, 1: None, 2: Thick Colored
        
        switch theme {
        case .standard:
            nameFont = NSFont(name: "Helvetica-Bold", size: 18) ?? NSFont.boldSystemFont(ofSize: 18)
            contactFont = NSFont(name: "Helvetica", size: 10) ?? NSFont.systemFont(ofSize: 10)
            bodyFont = NSFont(name: "Helvetica", size: 10.5) ?? NSFont.systemFont(ofSize: 10.5)
            nameColor = .black
            accentColor = .gray
            separatorStyle = 0
            
        case .modern:
            nameFont = NSFont(name: "Avenir-Heavy", size: 22) ?? NSFont.boldSystemFont(ofSize: 22)
            contactFont = NSFont(name: "Avenir-Medium", size: 9) ?? NSFont.systemFont(ofSize: 9)
            bodyFont = NSFont(name: "Avenir-Book", size: 10) ?? NSFont.systemFont(ofSize: 10)
            nameColor = NSColor(red: 0.0, green: 0.3, blue: 0.6, alpha: 1.0) // Yale Blue
            accentColor = NSColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1.0)
            separatorStyle = 2
            
        case .classic:
            nameFont = NSFont(name: "Times-Bold", size: 20) ?? NSFont.boldSystemFont(ofSize: 20)
            contactFont = NSFont(name: "Times-Roman", size: 11) ?? NSFont.systemFont(ofSize: 11)
            bodyFont = NSFont(name: "Times-Roman", size: 11) ?? NSFont.systemFont(ofSize: 11)
            nameColor = .black
            accentColor = .darkGray
            separatorStyle = 0
        }
        
        // --- 2. DRAW HEADER ---
        let headerStartY = pageHeight - margin
        var currentY = headerStartY
        
        if !userDetails.name.isEmpty {
            let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: nameColor]
            let nameString = NSAttributedString(string: userDetails.name, attributes: nameAttrs)
            
            // Center for classic, Left for others? Let's keep Left for now as standard.
            // Actually Classic looks better centered usually, but let's stick to consistent left layout for simplicity unless requested.
            
            let nameRect = CGRect(x: margin, y: currentY - 30, width: pageWidth - (2 * margin), height: 35)
            let framesetter = CTFramesetterCreateWithAttributedString(nameString)
            let path = CGPath(rect: nameRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, nameString.length), path, nil)
            CTFrameDraw(frame, context)
            
            currentY -= 35
        }
        
        let contactText = [userDetails.phone, userDetails.email].filter { !$0.isEmpty }.joined(separator: "  •  ")
        if !contactText.isEmpty {
            let contactAttrs: [NSAttributedString.Key: Any] = [.font: contactFont, .foregroundColor: accentColor]
            let contactString = NSAttributedString(string: contactText, attributes: contactAttrs)
            
            let contactRect = CGRect(x: margin, y: currentY - 15, width: pageWidth - (2 * margin), height: 20)
            let framesetter = CTFramesetterCreateWithAttributedString(contactString)
            let path = CGPath(rect: contactRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, contactString.length), path, nil)
            CTFrameDraw(frame, context)
            
            currentY -= 25
        }
        
        // Separator
        if separatorStyle == 0 {
            // Thin Line
            context.setStrokeColor(NSColor.lightGray.cgColor)
            context.setLineWidth(1.0)
            context.move(to: CGPoint(x: margin, y: currentY))
            context.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
            context.strokePath()
            currentY -= 20
        } else if separatorStyle == 2 {
            // Thick Colored Line
            context.setStrokeColor(nameColor.cgColor)
            context.setLineWidth(3.0)
            context.move(to: CGPoint(x: margin, y: currentY))
            context.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
            context.strokePath()
            currentY -= 25
        } else {
            // None (Classic sometimes has none or custom)
            currentY -= 15
        }
        
        // --- 3. DRAW BODY ---
        let textRect = CGRect(x: margin, y: margin, width: pageWidth - (2 * margin), height: currentY - margin)
        
        let fullAttributedString = NSMutableAttributedString()
        
        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.alignment = .justified
        bodyParagraphStyle.lineSpacing = 3
        bodyParagraphStyle.paragraphSpacing = 8
        
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: NSColor.black,
            .paragraphStyle: bodyParagraphStyle
        ]
        
        fullAttributedString.append(NSAttributedString(string: text, attributes: bodyAttrs))
        
        let framesetter = CTFramesetterCreateWithAttributedString(fullAttributedString as CFAttributedString)
        
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, fullAttributedString.length), path, nil)
        
        CTFrameDraw(frame, context)
        
        context.endPDFPage()
        context.closePDF()
        
        do {
            try pdfData.write(to: outputURL)
            return true
        } catch {
            print("❌ PDF Export Error: \(error)")
            return false
        }
    }
}
