import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TreeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TechniqueViewModel
    @State private var showingAddSheet = false
    @State private var newTechniqueName = ""
    @State private var selectedTechniqueForChild: Technique?
    @State private var showingDeleteAlert = false
    @State private var techniqueToDelete: Technique?
    @State private var documentPickerCoordinator: DocumentPickerCoordinator?

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: TechniqueViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if rootTechniques.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(rootTechniques, id: \.id) { technique in
                                techniqueTree(technique, depth: 0, siblings: rootTechniques)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            selectedTechniqueForChild = nil
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("JitsMindMap")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Mode", selection: $viewModel.selectedMode) {
                        Text("Gi").tag("gi")
                        Text("NoGi").tag("nogi")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            exportData()
                        } label: {
                            Label("Export JSON", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            importData()
                        } label: {
                            Label("Import JSON", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addTechniqueSheet
            }
            .alert("Delete Technique", isPresented: $showingDeleteAlert, presenting: techniqueToDelete) { technique in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteTechnique(technique)
                }
            } message: { technique in
                Text("Are you sure you want to delete '\(technique.name)' and all its child techniques?")
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.loadSeedDataIfNeeded()
        }
    }

    private var rootTechniques: [Technique] {
        viewModel.fetchRootTechniques(for: viewModel.selectedMode)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Tap + to add your first technique")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }

    private var addTechniqueSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Technique Name", text: $newTechniqueName)
                }

                if let parent = selectedTechniqueForChild {
                    Section {
                        Text("Parent: \(parent.name)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(selectedTechniqueForChild == nil ? "New Technique" : "New Child Technique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddSheet = false
                        newTechniqueName = ""
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTechnique()
                    }
                    .disabled(newTechniqueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func techniqueTree(_ technique: Technique, depth: Int, siblings: [Technique]) -> AnyView {
        let children = viewModel.fetchChildren(of: technique.id)
        let hasChildren = !children.isEmpty
        let isExpanded = viewModel.isExpanded(technique.id)
        let siblingIndex = siblings.firstIndex(where: { $0.id == technique.id }) ?? 0

        return AnyView(
            Group {
                NavigationLink(destination: TechniqueDetailView(technique: technique, viewModel: viewModel)) {
                    TechniqueRowView(
                        technique: technique,
                        depth: depth,
                        hasChildren: hasChildren,
                        isExpanded: isExpanded,
                        onToggleExpand: {
                            viewModel.toggleExpanded(technique.id)
                        },
                        onAddChild: {
                            selectedTechniqueForChild = technique
                            showingAddSheet = true
                        },
                        onDelete: {
                            techniqueToDelete = technique
                            showingDeleteAlert = true
                        },
                        onMoveUp: {
                            viewModel.moveTechniqueUp(technique)
                        },
                        onMoveDown: {
                            viewModel.moveTechniqueDown(technique)
                        },
                        canMoveUp: siblingIndex > 0,
                        canMoveDown: siblingIndex < siblings.count - 1
                    )
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)

                if hasChildren && isExpanded {
                    ForEach(children, id: \.id) { child in
                        techniqueTree(child, depth: depth + 1, siblings: children)
                    }
                }
            }
        )
    }

    private func addTechnique() {
        let trimmedName = newTechniqueName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        viewModel.addTechnique(
            name: trimmedName,
            parentID: selectedTechniqueForChild?.id,
            mode: viewModel.selectedMode
        )

        if let parent = selectedTechniqueForChild {
            viewModel.expandedNodes.insert(parent.id)
        }

        newTechniqueName = ""
        selectedTechniqueForChild = nil
        showingAddSheet = false
    }

    private func exportData() {
        guard let jsonData = viewModel.exportToJSON() else { return }

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "JitsMindMap_Export_\(Date().ISO8601Format()).json"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: fileURL)

            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            print("Export error: \(error)")
        }
    }

    private func importData() {
        let coordinator = DocumentPickerCoordinator(viewModel: viewModel)
        documentPickerCoordinator = coordinator

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = coordinator

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(documentPicker, animated: true)
        }
    }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    let viewModel: TechniqueViewModel

    init(viewModel: TechniqueViewModel) {
        self.viewModel = viewModel
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        do {
            let data = try Data(contentsOf: url)
            try viewModel.importFromJSON(data)
        } catch {
            print("Import error: \(error)")
        }
    }
}
