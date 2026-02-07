import SwiftUI
import UIKit

struct RichTextEditor: View {
    @Binding var text: String
    @Binding var htmlText: String?
    @FocusState private var isFocused: Bool

    @State private var textViewCoordinator: RichTextViewRepresentable.Coordinator?

    var body: some View {
        VStack(spacing: 0) {
            // Rich text editor using UITextView
            RichTextViewRepresentable(
                htmlText: $htmlText,
                plainText: $text,
                coordinatorBinding: $textViewCoordinator
            )
            .frame(minHeight: 200)
            .focused($isFocused)

            // Formatting toolbar
            Divider()

            HStack(spacing: 20) {
                // Bold button
                Button(action: {
                    textViewCoordinator?.toggleBold()
                }) {
                    Image(systemName: "bold")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                // Italic button
                Button(action: {
                    textViewCoordinator?.toggleItalic()
                }) {
                    Image(systemName: "italic")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                // Underline button
                Button(action: {
                    textViewCoordinator?.toggleUnderline()
                }) {
                    Image(systemName: "underline")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                Divider()
                    .frame(height: 20)

                // Bullet list button
                Button(action: {
                    textViewCoordinator?.insertBulletPoint()
                }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.primary)
                        .font(.title3)
                }

                // Numbered list button
                Button(action: {
                    textViewCoordinator?.insertNumberedPoint()
                }) {
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
}

// MARK: - UITextView Wrapper

struct RichTextViewRepresentable: UIViewRepresentable {
    @Binding var htmlText: String?
    @Binding var plainText: String
    @Binding var coordinatorBinding: Coordinator?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear

        // Set initial text with attributes
        if !plainText.isEmpty {
            let attributedString = NSMutableAttributedString(string: plainText)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: attributedString.length))
            textView.attributedText = attributedString
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update if plain text binding changed externally (not from user typing)
        if uiView.text != plainText && !context.coordinator.isUpdating {
            let attributedString = NSMutableAttributedString(string: plainText)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: attributedString.length))
            uiView.attributedText = attributedString
        }
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        DispatchQueue.main.async {
            coordinatorBinding = coordinator
        }
        return coordinator
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextViewRepresentable
        weak var textView: UITextView?
        var isUpdating = false

        init(_ parent: RichTextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            self.textView = textView
            isUpdating = true
            parent.plainText = textView.text

            // Convert to HTML for storage
            if let htmlData = try? textView.attributedText.data(
                from: NSRange(location: 0, length: textView.attributedText.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
            ) {
                parent.htmlText = String(data: htmlData, encoding: .utf8)
            }
            isUpdating = false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            self.textView = textView
        }

        // MARK: - Formatting Methods

        func toggleBold() {
            guard let textView = textView else { return }
            applyFontTrait(.traitBold, to: textView)
        }

        func toggleItalic() {
            guard let textView = textView else { return }
            applyFontTrait(.traitItalic, to: textView)
        }

        func toggleUnderline() {
            guard let textView = textView else { return }
            let selectedRange = textView.selectedRange

            guard selectedRange.length > 0 else { return }

            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)

            // Check if already underlined
            let attributes = mutableText.attributes(at: selectedRange.location, effectiveRange: nil)
            let currentUnderline = attributes[.underlineStyle] as? Int ?? 0

            if currentUnderline == NSUnderlineStyle.single.rawValue {
                // Remove underline
                mutableText.removeAttribute(.underlineStyle, range: selectedRange)
            } else {
                // Add underline
                mutableText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
            }

            textView.attributedText = mutableText
            textView.selectedRange = selectedRange // Restore selection
            textViewDidChange(textView)
        }

        private func applyFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, to textView: UITextView) {
            let selectedRange = textView.selectedRange

            guard selectedRange.length > 0 else { return }

            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            let fullRange = NSRange(location: 0, length: mutableText.length)

            // Ensure all text has a font attribute
            mutableText.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
                if value == nil {
                    mutableText.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: range)
                }
            }

            // Apply trait to selected range
            mutableText.enumerateAttribute(.font, in: selectedRange, options: []) { value, range, _ in
                let currentFont = (value as? UIFont) ?? UIFont.systemFont(ofSize: 16)
                let newFont = toggleTrait(trait, in: currentFont)
                mutableText.addAttribute(.font, value: newFont, range: range)
            }

            textView.attributedText = mutableText
            textView.selectedRange = selectedRange // Restore selection
            textViewDidChange(textView)
        }

        private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits, in font: UIFont) -> UIFont {
            let descriptor = font.fontDescriptor
            var traits = descriptor.symbolicTraits

            if traits.contains(trait) {
                // Remove trait
                traits.remove(trait)
            } else {
                // Add trait
                traits.insert(trait)
            }

            guard let newDescriptor = descriptor.withSymbolicTraits(traits) else {
                return font
            }

            return UIFont(descriptor: newDescriptor, size: font.pointSize)
        }

        func insertBulletPoint() {
            guard let textView = textView else { return }
            let selectedRange = textView.selectedRange

            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            let bullet = NSAttributedString(string: "• ", attributes: [.font: UIFont.systemFont(ofSize: 16)])

            mutableText.insert(bullet, at: selectedRange.location)

            textView.attributedText = mutableText
            textView.selectedRange = NSRange(location: selectedRange.location + 2, length: 0)
            textViewDidChange(textView)
        }

        func insertNumberedPoint() {
            guard let textView = textView else { return }
            let selectedRange = textView.selectedRange

            // Count existing numbered items
            let text = textView.text ?? ""
            let lines = text.components(separatedBy: "\n")
            let numberedLines = lines.filter { line in
                line.range(of: #"^\d+\."#, options: NSString.CompareOptions.regularExpression) != nil
            }
            let nextNumber = numberedLines.count + 1

            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            let number = NSAttributedString(string: "\(nextNumber). ", attributes: [.font: UIFont.systemFont(ofSize: 16)])

            mutableText.insert(number, at: selectedRange.location)

            textView.attributedText = mutableText
            textView.selectedRange = NSRange(location: selectedRange.location + number.length, length: 0)
            textViewDidChange(textView)
        }
    }
}
