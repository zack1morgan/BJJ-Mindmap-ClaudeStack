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
    @State private var showingFavorites = false
    @State private var selectedModesForAdd: Set<BJJMode> = [.gi]
    @State private var draggedTechnique: Technique?

    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: TechniqueViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Show search results or tree view
                if viewModel.isSearching && !viewModel.searchText.isEmpty {
                    searchResultsView
                } else if rootTechniques.isEmpty {
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
                            selectedModesForAdd = [.gi]  // Reset to default
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFavorites = true
                    } label: {
                        Image(systemName: "star")
                    }
                }

                ToolbarItem(placement: .principal) {
                    Picker("Mode", selection: $viewModel.selectedMode) {
                        Text("Gi").tag(BJJMode.gi)
                        Text("No-Gi").tag(BJJMode.noGi)
                        Text("All").tag(BJJMode.combined)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
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
            .sheet(isPresented: $showingFavorites) {
                FavoritesView(viewModel: viewModel, mode: viewModel.selectedMode)
            }
            .alert("Delete Technique", isPresented: $showingDeleteAlert, presenting: techniqueToDelete) { technique in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteTechnique(technique)
                }
            } message: { technique in
                Text("Are you sure you want to delete '\(technique.name)' and all its child techniques?")
            }
            .searchable(
                text: $viewModel.searchText,
                isPresented: $viewModel.isSearching,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search techniques"
            )
            .navigationDestination(for: Technique.self) { technique in
                TechniqueDetailView(technique: technique, viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.loadSeedDataIfNeeded()
        }
    }

    private var rootTechniques: [Technique] {
        if viewModel.selectedMode == .combined {
            // In combined mode, deduplicate techniques from both Gi and NoGi
            let giTechniques = viewModel.fetchRootTechniques(for: .gi)
            let noGiTechniques = viewModel.fetchRootTechniques(for: .noGi)

            return deduplicateTechniques(giTechniques + noGiTechniques)
        } else {
            return viewModel.fetchRootTechniques(for: viewModel.selectedMode)
        }
    }

    /// Deduplicates techniques by normalized name (case-insensitive, trimmed)
    /// When duplicates exist, prefers the Gi version
    private func deduplicateTechniques(_ techniques: [Technique]) -> [Technique] {
        var seen: Set<String> = []
        var deduplicated: [Technique] = []

        // Sort to ensure Gi techniques come before NoGi (for preference)
        let sorted = techniques.sorted { t1, t2 in
            if t1.mode == t2.mode {
                return t1.name < t2.name
            }
            return t1.mode == "gi"  // Gi comes first
        }

        for technique in sorted {
            let normalizedName = technique.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            if !seen.contains(normalizedName) {
                seen.insert(normalizedName)
                deduplicated.append(technique)
            }
        }

        return deduplicated.sorted { $0.name < $1.name }
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

    private var searchResultsView: some View {
        let results = viewModel.searchTechniques(
            query: viewModel.searchText,
            mode: viewModel.selectedMode
        )

        return List(results, id: \.id) { technique in
            NavigationLink(destination: TechniqueDetailView(technique: technique, viewModel: viewModel)) {
                HStack {
                    Text(technique.name)
                    Spacer()
                    if technique.isFavorite(in: viewModel.selectedMode) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
        }
        .overlay {
            if results.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
    }

    private var addTechniqueSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Technique Name", text: $newTechniqueName)
                }

                // Show mode selection only in Combined mode
                if viewModel.selectedMode == .combined {
                    Section(header: Text("Add to Mode")) {
                        ForEach([BJJMode.gi, BJJMode.noGi], id: \.self) { mode in
                            Button(action: {
                                if selectedModesForAdd.contains(mode) {
                                    selectedModesForAdd.remove(mode)
                                } else {
                                    selectedModesForAdd.insert(mode)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedModesForAdd.contains(mode) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedModesForAdd.contains(mode) ? .blue : .gray)
                                    Text(mode.displayName)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
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
        let allChildren = viewModel.fetchChildren(of: technique.id)
        // Deduplicate children in Combined mode
        let children = viewModel.selectedMode == .combined ? deduplicateTechniques(allChildren) : allChildren
        let hasChildren = !children.isEmpty
        let isExpanded = viewModel.isExpanded(technique.id)
        let siblingIndex = siblings.firstIndex(where: { $0.id == technique.id }) ?? 0

        return AnyView(
            Group {
                NavigationLink(value: technique) {
                    TechniqueRowView(
                        technique: technique,
                        depth: depth,
                        hasChildren: hasChildren,
                        isExpanded: isExpanded,
                        currentMode: viewModel.selectedMode,
                        onToggleExpand: {
                            viewModel.toggleExpanded(technique.id)
                        },
                        onAddChild: {
                            selectedTechniqueForChild = technique
                            selectedModesForAdd = [.gi]  // Reset to default
                            showingAddSheet = true
                        },
                        onDelete: {
                            techniqueToDelete = technique
                            showingDeleteAlert = true
                        },
                        onHide: {
                            viewModel.hideTechnique(technique, in: viewModel.selectedMode)
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
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            // Start drag after long press
                            if viewModel.selectedMode != .combined {
                                self.draggedTechnique = technique
                            }
                        }
                )
                .onDrag {
                    // Only enable drag in Gi or No-Gi mode, not Combined
                    guard viewModel.selectedMode != .combined else {
                        return NSItemProvider()
                    }

                    self.draggedTechnique = technique
                    let itemProvider = NSItemProvider()
                    itemProvider.suggestedName = technique.id.uuidString
                    itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.text.identifier, visibility: .all) { completion in
                        let data = technique.id.uuidString.data(using: .utf8)
                        completion(data, nil)
                        return nil
                    }
                    return itemProvider
                }
                .onDrop(of: [.text], delegate: TechniqueDropDelegate(
                    technique: technique,
                    siblings: siblings,
                    viewModel: viewModel,
                    draggedTechnique: $draggedTechnique,
                    currentMode: viewModel.selectedMode
                ))

                // Drop zone to add as first child (when expanded or to expand and add)
                if isExpanded || viewModel.selectedMode != .combined {
                    Color.clear
                        .frame(height: isExpanded ? 20 : 0)
                        .onDrop(of: [.text], delegate: TechniqueChildDropDelegate(
                            parentTechnique: technique,
                            viewModel: viewModel,
                            draggedTechnique: $draggedTechnique,
                            currentMode: viewModel.selectedMode,
                            insertAtBeginning: true
                        ))
                }

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

        if viewModel.selectedMode == .combined {
            // Add to selected modes (Gi, NoGi, or both)
            guard !selectedModesForAdd.isEmpty else { return }
            viewModel.addTechnique(
                name: trimmedName,
                parentID: selectedTechniqueForChild?.id,
                modes: selectedModesForAdd
            )
        } else {
            // Add to current mode
            viewModel.addTechnique(
                name: trimmedName,
                parentID: selectedTechniqueForChild?.id,
                mode: viewModel.selectedMode
            )
        }

        if let parent = selectedTechniqueForChild {
            viewModel.expandedNodes.insert(parent.id)
        }

        newTechniqueName = ""
        selectedTechniqueForChild = nil
        selectedModesForAdd = [.gi]  // Reset to default
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

// MARK: - Drag and Drop Delegate

struct TechniqueDropDelegate: DropDelegate {
    let technique: Technique
    let siblings: [Technique]
    let viewModel: TechniqueViewModel
    @Binding var draggedTechnique: Technique?
    let currentMode: BJJMode

    func validateDrop(info: DropInfo) -> Bool {
        // Don't allow drops in Combined mode
        guard currentMode != .combined else { return false }

        // Make sure we have a dragged technique
        guard let draggedTechnique = draggedTechnique else { return false }

        // Don't drop onto itself
        guard draggedTechnique.id != technique.id else { return false }

        // Validate using viewModel's validation
        return viewModel.canDropTechnique(draggedTechnique, onParent: technique.parentID)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTechnique = draggedTechnique else { return false }
        guard currentMode != .combined else { return false }
        guard validateDrop(info: info) else { return false }

        // Find the current index of the target technique
        guard let targetIndex = siblings.firstIndex(where: { $0.id == technique.id }) else {
            return false
        }

        // Find the current index of the dragged technique in siblings (if exists)
        let draggedIndex = siblings.firstIndex(where: { $0.id == draggedTechnique.id })

        // Determine final destination index
        var destinationIndex: Int

        // If dragging within same parent
        if draggedTechnique.parentID == technique.parentID, let draggedIdx = draggedIndex {
            // If dragging down (from earlier to later position)
            if draggedIdx < targetIndex {
                destinationIndex = targetIndex  // Will go to target's current position
            } else {
                // If dragging up (from later to earlier position)
                destinationIndex = targetIndex + 1  // Will go after target
            }
        } else {
            // If dragging from different parent or to different parent
            destinationIndex = targetIndex + 1  // Insert after target
        }

        // Perform the move
        viewModel.moveTechnique(
            draggedTechnique,
            to: destinationIndex,
            newParentID: technique.parentID
        )

        // Clear the dragged technique
        self.draggedTechnique = nil

        return true
    }

    func dropEntered(info: DropInfo) {
        // Visual feedback handled automatically by SwiftUI
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: validateDrop(info: info) ? .move : .forbidden)
    }
}

// MARK: - Child Drop Delegate (for dropping as child)

struct TechniqueChildDropDelegate: DropDelegate {
    let parentTechnique: Technique
    let viewModel: TechniqueViewModel
    @Binding var draggedTechnique: Technique?
    let currentMode: BJJMode
    let insertAtBeginning: Bool

    func validateDrop(info: DropInfo) -> Bool {
        // Don't allow drops in Combined mode
        guard currentMode != .combined else { return false }

        // Make sure we have a dragged technique
        guard let draggedTechnique = draggedTechnique else { return false }

        // Don't drop onto itself
        guard draggedTechnique.id != parentTechnique.id else { return false }

        // Validate using viewModel's validation (check for cycles)
        return viewModel.canDropTechnique(draggedTechnique, onParent: parentTechnique.id)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTechnique = draggedTechnique else { return false }
        guard currentMode != .combined else { return false }
        guard validateDrop(info: info) else { return false }

        // Make the dragged technique a child of the parent
        let children = viewModel.fetchChildren(of: parentTechnique.id)
        let destinationIndex = insertAtBeginning ? 0 : children.count

        // Perform the move
        viewModel.moveTechnique(
            draggedTechnique,
            to: destinationIndex,
            newParentID: parentTechnique.id
        )

        // Expand the parent to show the new child
        viewModel.expandedNodes.insert(parentTechnique.id)

        // Clear the dragged technique
        self.draggedTechnique = nil

        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: validateDrop(info: info) ? .move : .forbidden)
    }
}
