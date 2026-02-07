import SwiftUI
import SwiftData

struct TechniqueDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let technique: Technique
    let viewModel: TechniqueViewModel

    @State private var name: String
    @State private var notes: String
    @State private var notesHTML: String?
    @State private var mediaItems: [MediaItem]
    @State private var links: [String]

    init(technique: Technique, viewModel: TechniqueViewModel) {
        self.technique = technique
        self.viewModel = viewModel
        _name = State(initialValue: technique.name)
        _notes = State(initialValue: technique.notes)
        _notesHTML = State(initialValue: technique.notesHTML)
        _mediaItems = State(initialValue: technique.mediaItems)
        _links = State(initialValue: technique.links)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Technique Name Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technique Name")
                        .font(.headline)

                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)

                Divider()

                // Rich Text Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .padding(.horizontal)

                    RichTextEditor(text: $notes, htmlText: $notesHTML)
                        .padding(.horizontal)
                }

                Divider()

                // Links Section
                LinksSectionView(links: $links)
                    .padding(.horizontal)

                Divider()

                // Media Gallery Section
                MediaGalleryView(mediaItems: $mediaItems)
                    .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Edit Technique")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: technique.isFavorite(in: viewModel.selectedMode) ? "star.fill" : "star")
                        .foregroundColor(technique.isFavorite(in: viewModel.selectedMode) ? .yellow : .gray)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func saveChanges() {
        viewModel.updateTechnique(
            technique,
            name: name,
            notes: notes,
            notesHTML: notesHTML,
            mediaItems: mediaItems,
            links: links
        )
        dismiss()
    }

    private func toggleFavorite() {
        let currentMode = viewModel.selectedMode
        let isFav = technique.isFavorite(in: currentMode)
        technique.setFavorite(!isFav, in: currentMode)
        try? viewModel.modelContext.save()
    }
}
