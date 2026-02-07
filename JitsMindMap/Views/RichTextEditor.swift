import SwiftUI
import UIKit

struct RichTextEditor: View {
    @Binding var text: String
    @Binding var htmlText: String?
    @FocusState private var isFocused: Bool

    @State private var attributedText: NSAttributedString = NSAttributedString(string: "")
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)

    var body: some View {
        VStack(spacing: 0) {
            // Rich text editor using UITextView
            RichTextViewRepresentable(
                attributedText: $attributedText,
                selectedRange: $selectedRange,
                htmlText: $htmlText,
                plainText: $text
            )
            .frame(minHeight: 200)
            .focused($isFocused)
            .onAppear {
                if !text.isEmpty && attributedText.string.isEmpty {
                    attributedText = NSAttributedString(string: text)
                }
            }

            // Formatting toolbar
            Divider()

            HStack(spacing: 20) {
                // Bold button
                Button(action: { toggleBold() }) {
                    Image(systemName: "bold")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                // Italic button
                Button(action: { toggleItalic() }) {
                    Image(systemName: "italic")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                // Underline button
                Button(action: { toggleUnderline() }) {
                    Image(systemName: "underline")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                Divider()
                    .frame(height: 20)

                // Bullet list button
                Button(action: { insertBulletPoint() }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                // Numbered list button
                Button(action: { insertNumberedPoint() }) {
                    Image(systemName: "list.number")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemGray6))
        }
    }

    private func toggleBold() {
        applyStyle(.traitBold)
    }

    private func toggleItalic() {
        applyStyle(.traitItalic)
    }

    private func toggleUnderline() {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)

        if selectedRange.length > 0 {
            let attributes = mutableAttributedText.attributes(at: selectedRange.location, effectiveRange: nil)

            if let underlineStyle = attributes[.underlineStyle] as? Int, underlineStyle == NSUnderlineStyle.single.rawValue {
                // Remove underline
                mutableAttributedText.removeAttribute(.underlineStyle, range: selectedRange)
            } else {
                // Add underline
                mutableAttributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
            }
        }

        attributedText = mutableAttributedText
    }

    private func applyStyle(_ trait: UIFontDescriptor.SymbolicTraits) {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)

        if selectedRange.length > 0 {
            mutableAttributedText.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
                guard let font = value as? UIFont else { return }

                let newFont: UIFont
                if font.fontDescriptor.symbolicTraits.contains(trait) {
                    // Remove the trait
                    var traits = font.fontDescriptor.symbolicTraits
                    traits.remove(trait)
                    if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        newFont = UIFont(descriptor: descriptor, size: font.pointSize)
                    } else {
                        newFont = font
                    }
                } else {
                    // Add the trait
                    var traits = font.fontDescriptor.symbolicTraits
                    traits.insert(trait)
                    if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        newFont = UIFont(descriptor: descriptor, size: font.pointSize)
                    } else {
                        newFont = font
                    }
                }

                mutableAttributedText.addAttribute(.font, value: newFont, range: range)
            }
        }

        attributedText = mutableAttributedText
    }

    private func insertBulletPoint() {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        let bullet = "• "
        let bulletString = NSAttributedString(string: bullet)

        mutableAttributedText.insert(bulletString, at: selectedRange.location)
        attributedText = mutableAttributedText
    }

    private func insertNumberedPoint() {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)

        // Count existing numbered items to get next number
        let existingText = mutableAttributedText.string
        let lines = existingText.components(separatedBy: "\n")
        let numberedLines = lines.filter { $0.range(of: #"^\d+\."#, options: .regularExpression) != nil }
        let nextNumber = numberedLines.count + 1

        let number = "\(nextNumber). "
        let numberString = NSAttributedString(string: number)

        mutableAttributedText.insert(numberString, at: selectedRange.location)
        attributedText = mutableAttributedText
    }
}

// MARK: - UITextView Wrapper

struct RichTextViewRepresentable: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    @Binding var htmlText: String?
    @Binding var plainText: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextViewRepresentable

        init(_ parent: RichTextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
            parent.plainText = textView.text

            // Convert to HTML for storage
            if let htmlData = try? textView.attributedText.data(
                from: NSRange(location: 0, length: textView.attributedText.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
            ) {
                parent.htmlText = String(data: htmlData, encoding: .utf8)
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}
