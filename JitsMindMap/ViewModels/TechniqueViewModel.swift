import Foundation
import SwiftData
import SwiftUI

// MARK: - Combined Technique

struct CombinedTechnique: Identifiable {
    let id: UUID
    let name: String
    let giTechnique: Technique?
    let noGiTechnique: Technique?
    let parentID: UUID?
    let sortOrder: Int

    var existsInBothModes: Bool {
        giTechnique != nil && noGiTechnique != nil
    }
}

// MARK: - Technique View Model

@Observable
class TechniqueViewModel {
    var modelContext: ModelContext
    var selectedMode: BJJMode = .gi
    var expandedNodes: Set<UUID> = []

    // Search state
    var searchText: String = ""
    var isSearching: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Operations

    func fetchTechniques(for mode: BJJMode) -> [Technique] {
        guard mode != .combined else { return [] } // Use fetchCombinedTechniques for combined mode

        let modeString = mode.rawValue
        let descriptor = FetchDescriptor<Technique>(
            predicate: #Predicate { $0.mode == modeString },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let techniques = (try? modelContext.fetch(descriptor)) ?? []

        // Filter out hidden items
        return techniques.filter { !$0.isHidden(in: mode) }
    }

    func fetchRootTechniques(for mode: BJJMode) -> [Technique] {
        guard mode != .combined else {
            return [] // Combined mode handled separately
        }

        let modeString = mode.rawValue
        let descriptor = FetchDescriptor<Technique>(
            predicate: #Predicate { $0.mode == modeString && $0.parentID == nil },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let techniques = (try? modelContext.fetch(descriptor)) ?? []

        // Filter out hidden items
        return techniques.filter { !$0.isHidden(in: mode) }
    }

    func fetchChildren(of parentID: UUID, for mode: BJJMode) -> [Technique] {
        let descriptor = FetchDescriptor<Technique>(
            predicate: #Predicate { $0.parentID == parentID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let techniques = (try? modelContext.fetch(descriptor)) ?? []

        // Filter out hidden items (only if not in combined mode)
        if mode == .combined {
            return techniques
        }
        return techniques.filter { !$0.isHidden(in: mode) }
    }

    // Keep old signature for backward compatibility during migration
    func fetchChildren(of parentID: UUID) -> [Technique] {
        return fetchChildren(of: parentID, for: selectedMode)
    }

    // MARK: - CRUD Operations

    func addTechnique(name: String, parentID: UUID? = nil, mode: BJJMode) {
        // Combined mode should never reach here directly - handled by UI
        guard mode != .combined else { return }

        let siblings = parentID == nil ?
            fetchRootTechniques(for: mode) :
            fetchChildren(of: parentID!, for: mode)
        let sortOrder = siblings.count

        let technique = Technique(
            name: name,
            parentID: parentID,
            mode: mode.rawValue,
            sortOrder: sortOrder
        )
        modelContext.insert(technique)
        try? modelContext.save()
    }

    // Add technique to multiple modes (for Combined mode "Add to Both")
    func addTechnique(name: String, parentID: UUID? = nil, modes: Set<BJJMode>) {
        for mode in modes {
            guard mode != .combined else { continue }
            addTechnique(name: name, parentID: parentID, mode: mode)
        }
    }

    func updateTechnique(
        _ technique: Technique,
        name: String,
        notes: String,
        notesHTML: String? = nil,
        mediaItems: [MediaItem] = [],
        links: [String] = []
    ) {
        technique.name = name
        technique.notes = notes
        technique.notesHTML = notesHTML
        technique.mediaItems = mediaItems
        technique.links = links
        technique.modifiedDate = Date()
        try? modelContext.save()
    }

    func deleteTechnique(_ technique: Technique) {
        let children = fetchChildren(of: technique.id)
        for child in children {
            deleteTechnique(child)
        }
        modelContext.delete(technique)
        try? modelContext.save()
    }

    func moveTechniqueUp(_ technique: Technique) {
        let bjjMode = BJJMode(rawValue: technique.mode) ?? .gi
        let siblings = technique.parentID == nil ?
            fetchRootTechniques(for: bjjMode) :
            fetchChildren(of: technique.parentID!, for: bjjMode)

        guard let currentIndex = siblings.firstIndex(where: { $0.id == technique.id }),
              currentIndex > 0 else { return }

        let previousTechnique = siblings[currentIndex - 1]
        let tempOrder = technique.sortOrder
        technique.sortOrder = previousTechnique.sortOrder
        previousTechnique.sortOrder = tempOrder

        try? modelContext.save()
    }

    func moveTechniqueDown(_ technique: Technique) {
        let bjjMode = BJJMode(rawValue: technique.mode) ?? .gi
        let siblings = technique.parentID == nil ?
            fetchRootTechniques(for: bjjMode) :
            fetchChildren(of: technique.parentID!, for: bjjMode)

        guard let currentIndex = siblings.firstIndex(where: { $0.id == technique.id }),
              currentIndex < siblings.count - 1 else { return }

        let nextTechnique = siblings[currentIndex + 1]
        let tempOrder = technique.sortOrder
        technique.sortOrder = nextTechnique.sortOrder
        nextTechnique.sortOrder = tempOrder

        try? modelContext.save()
    }

    // MARK: - Search

    func searchTechniques(query: String, mode: BJJMode) -> [Technique] {
        guard !query.isEmpty else { return [] }

        let lowercasedQuery = query.lowercased()
        var allTechniques: [Technique] = []

        if mode == .combined {
            // Search both modes
            allTechniques = fetchAllTechniques(for: .gi) + fetchAllTechniques(for: .noGi)
        } else {
            allTechniques = fetchAllTechniques(for: mode)
        }

        return allTechniques.filter { technique in
            // Exclude hidden items
            if mode == .combined {
                // In combined mode, include if visible in either mode
                let hiddenInGi = technique.isHidden(in: .gi)
                let hiddenInNoGi = technique.isHidden(in: .noGi)
                guard !(hiddenInGi && hiddenInNoGi) else { return false }
            } else {
                guard !technique.isHidden(in: mode) else { return false }
            }

            // Case-insensitive partial match on name
            return technique.name.lowercased().contains(lowercasedQuery)
        }
    }

    private func fetchAllTechniques(for mode: BJJMode) -> [Technique] {
        guard mode != .combined else { return [] }

        let modeString = mode.rawValue
        let descriptor = FetchDescriptor<Technique>(
            predicate: #Predicate { $0.mode == modeString },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Hide Functionality

    func hideTechnique(_ technique: Technique, in mode: BJJMode) {
        // Hide the technique itself
        technique.setHidden(true, in: mode)

        // Recursively hide all descendants
        let children = fetchChildren(of: technique.id, for: mode)
        for child in children where child.mode == mode.rawValue {
            hideTechnique(child, in: mode)
        }

        try? modelContext.save()
    }

    // MARK: - Favorites

    func fetchFavorites(for mode: BJJMode) -> [Technique] {
        var allTechniques: [Technique] = []

        if mode == .combined {
            allTechniques = fetchAllTechniques(for: .gi) + fetchAllTechniques(for: .noGi)
        } else {
            allTechniques = fetchAllTechniques(for: mode)
        }

        return allTechniques.filter {
            $0.isFavorite(in: mode) && !$0.isHidden(in: mode)
        }
        .sorted { $0.name < $1.name }
    }

    // MARK: - Combined Mode

    func fetchCombinedTechniques() -> [CombinedTechnique] {
        let giTechniques = fetchAllTechniques(for: .gi).filter { !$0.isHidden(in: .gi) }
        let noGiTechniques = fetchAllTechniques(for: .noGi).filter { !$0.isHidden(in: .noGi) }

        var combined: [String: CombinedTechnique] = [:]

        // Process Gi techniques
        for technique in giTechniques {
            let key = technique.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            combined[key] = CombinedTechnique(
                id: technique.id,
                name: technique.name,
                giTechnique: technique,
                noGiTechnique: nil,
                parentID: technique.parentID,
                sortOrder: technique.sortOrder
            )
        }

        // Process NoGi techniques (merge or add new)
        for technique in noGiTechniques {
            let key = technique.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if let existing = combined[key] {
                // Found duplicate - merge
                combined[key] = CombinedTechnique(
                    id: existing.id, // Use Gi ID if available
                    name: technique.name,
                    giTechnique: existing.giTechnique,
                    noGiTechnique: technique,
                    parentID: existing.parentID ?? technique.parentID,
                    sortOrder: existing.sortOrder
                )
            } else {
                // NoGi-only technique
                combined[key] = CombinedTechnique(
                    id: technique.id,
                    name: technique.name,
                    giTechnique: nil,
                    noGiTechnique: technique,
                    parentID: technique.parentID,
                    sortOrder: technique.sortOrder
                )
            }
        }

        return Array(combined.values).sorted { $0.sortOrder < $1.sortOrder }
    }

    func fetchRootCombinedTechniques() -> [CombinedTechnique] {
        let allCombined = fetchCombinedTechniques()
        return allCombined.filter { $0.parentID == nil }
    }

    func fetchCombinedChildren(of parentID: UUID) -> [CombinedTechnique] {
        let allCombined = fetchCombinedTechniques()
        return allCombined.filter { $0.parentID == parentID }
    }

    // MARK: - Expand/Collapse

    func toggleExpanded(_ id: UUID) {
        if expandedNodes.contains(id) {
            expandedNodes.remove(id)
        } else {
            expandedNodes.insert(id)
        }
    }

    func isExpanded(_ id: UUID) -> Bool {
        expandedNodes.contains(id)
    }

    // MARK: - Seed Data

    func loadSeedDataIfNeeded() {
        let descriptor = FetchDescriptor<Technique>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else { return }

        guard let url = Bundle.main.url(forResource: "SeedData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        struct SeedTechnique: Codable {
            let id: String
            let name: String
            let notes: String
            let parentID: String?
            let mode: String
            let sortOrder: Int
        }

        guard let seedTechniques = try? JSONDecoder().decode([SeedTechnique].self, from: data) else { return }

        var idMapping: [String: UUID] = [:]
        for seed in seedTechniques {
            idMapping[seed.id] = UUID()
        }

        for seed in seedTechniques {
            let technique = Technique(
                id: idMapping[seed.id]!,
                name: seed.name,
                notes: seed.notes,
                parentID: seed.parentID.flatMap { idMapping[$0] },
                mode: seed.mode,
                sortOrder: seed.sortOrder
            )
            modelContext.insert(technique)
        }

        try? modelContext.save()
    }

    // MARK: - Export/Import

    func exportToJSON() -> Data? {
        let descriptor = FetchDescriptor<Technique>()
        guard let techniques = try? modelContext.fetch(descriptor) else { return nil }

        let exportData = techniques.map { $0.toExportData() }
        return try? JSONEncoder().encode(exportData)
    }

    func importFromJSON(_ data: Data) throws {
        let decoder = JSONDecoder()
        let exportData = try decoder.decode([Technique.ExportData].self, from: data)

        for data in exportData {
            let technique = Technique.fromExportData(data)
            modelContext.insert(technique)
        }

        try modelContext.save()
    }
}
