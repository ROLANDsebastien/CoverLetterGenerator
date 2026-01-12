import Foundation
import PDFKit
import AppKit

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
    
    /// Extract contact details (Name, Phone, Email) from text using Heuristics/Regex
    static func extractContactDetails(from text: String) -> (name: String?, phone: String?, email: String?) {
        var name: String? = nil
        var phone: String? = nil
        var email: String? = nil
        
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // 1. Name Heuristic: The first non-empty line is often the name in a CV
        if let firstLine = lines.first {
            // Basic cleanup: remove common titles if present? For now take the raw line.
            // Limit length to avoid capturing a whole paragraph
            if firstLine.count < 50 {
                name = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // 2. Email Regex
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        if let emailRange = text.range(of: emailPattern, options: .regularExpression) {
            email = String(text[emailRange])
        }
        
        // 3. Phone Regex (Supports various formats including French)
        // Matches: 06 12 34 56 78, +33 6 12 34 56 78, 06.12.34.56.78, etc.
        let phonePattern = "(?:(?:\\+|00)33|0)\\s*[1-9](?:[\\s.-]*\\d{2}){4}"
        if let phoneRange = text.range(of: phonePattern, options: .regularExpression) {
            phone = String(text[phoneRange])
        }
        
        return (name, phone, email)
    }
    
    /// Generate a PDF from a string with optional signature
    static func generatePDF(from text: String, to outputURL: URL) -> Bool {
        // A4 Size
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 72.0 // 1 inch margin
        
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            return false
        }
        
        let mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        context.beginPDFPage(nil)
        
        let textRect = mediaBox.insetBy(dx: margin, dy: margin)
        
        let fullAttributedString = NSMutableAttributedString()
        
        // Body Style (Justified)
        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.alignment = .justified
        bodyParagraphStyle.lineSpacing = 4
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.black,
            .paragraphStyle: bodyParagraphStyle
        ]
        
        fullAttributedString.append(NSAttributedString(string: text, attributes: bodyAttributes))
        
        let framesetter = CTFramesetterCreateWithAttributedString(fullAttributedString as CFAttributedString)
        
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, fullAttributedString.length), path, nil)
        
        // Draw the frame
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
