import SwiftUI

struct TechniqueDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let technique: Technique
    let viewModel: TechniqueViewModel

    @State private var name: String
    @State private var notes: String

    init(technique: Technique, viewModel: TechniqueViewModel) {
        self.technique = technique
        self.viewModel = viewModel
        _name = State(initialValue: technique.name)
        _notes = State(initialValue: technique.notes)
    }

    var body: some View {
        Form {
            Section(header: Text("Technique Name")) {
                TextField("Name", text: $name)
            }

            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 200)
            }
        }
        .navigationTitle("Edit Technique")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func saveChanges() {
        viewModel.updateTechnique(technique, name: name, notes: notes)
        dismiss()
    }
}
