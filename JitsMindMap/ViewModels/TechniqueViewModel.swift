import Foundation
import SwiftData
import SwiftUI

@Observable
class TechniqueViewModel {
    var modelContext: ModelContext
    var selectedMode: String = "gi"
    var expandedNodes: Set<UUID> = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Operations

    func fetchTechniques(for mode: String) -> [Technique] {
        let descriptor = FetchDescriptor<Technique>(
            predicate: #Predicate { $0.mode == mode },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchRootTechniques(for mode: String) -> [Technique] {
        let descriptor = FetchDescriptor<Technique>(
            predicate: #Predicate { $0.mode == mode && $0.parentID == nil },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchChildren(of parentID: UUID) -> [Technique] {
        let descriptor = FetchDescriptor<Technique>(
            predicate: #Predicate { $0.parentID == parentID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - CRUD Operations

    func addTechnique(name: String, parentID: UUID? = nil, mode: String) {
        let siblings = parentID == nil ?
            fetchRootTechniques(for: mode) :
            fetchChildren(of: parentID!)
        let sortOrder = siblings.count

        let technique = Technique(
            name: name,
            parentID: parentID,
            mode: mode,
            sortOrder: sortOrder
        )
        modelContext.insert(technique)
        try? modelContext.save()
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
        let siblings = technique.parentID == nil ?
            fetchRootTechniques(for: technique.mode) :
            fetchChildren(of: technique.parentID!)

        guard let currentIndex = siblings.firstIndex(where: { $0.id == technique.id }),
              currentIndex > 0 else { return }

        let previousTechnique = siblings[currentIndex - 1]
        let tempOrder = technique.sortOrder
        technique.sortOrder = previousTechnique.sortOrder
        previousTechnique.sortOrder = tempOrder

        try? modelContext.save()
    }

    func moveTechniqueDown(_ technique: Technique) {
        let siblings = technique.parentID == nil ?
            fetchRootTechniques(for: technique.mode) :
            fetchChildren(of: technique.parentID!)

        guard let currentIndex = siblings.firstIndex(where: { $0.id == technique.id }),
              currentIndex < siblings.count - 1 else { return }

        let nextTechnique = siblings[currentIndex + 1]
        let tempOrder = technique.sortOrder
        technique.sortOrder = nextTechnique.sortOrder
        nextTechnique.sortOrder = tempOrder

        try? modelContext.save()
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
