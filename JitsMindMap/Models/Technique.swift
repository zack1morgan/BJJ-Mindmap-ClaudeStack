import Foundation
import SwiftData

// MARK: - BJJ Mode Enum

enum BJJMode: String, Codable, CaseIterable {
    case gi = "gi"
    case noGi = "nogi"
    case combined = "combined"

    var displayName: String {
        switch self {
        case .gi: return "Gi"
        case .noGi: return "No-Gi"
        case .combined: return "All"
        }
    }
}

// MARK: - Media Item Model

@Model
final class MediaItem {
    var id: UUID
    var fileName: String
    var type: String // "image" or "video"
    var thumbnailData: Data?
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        type: String,
        thumbnailData: Data? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.type = type
        self.thumbnailData = thumbnailData
        self.dateAdded = dateAdded
    }
}

@Model
final class Technique: Hashable {
    static func == (lhs: Technique, rhs: Technique) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id: UUID
    var name: String
    var notes: String
    var notesHTML: String? // Rich text formatted notes (HTML)
    var parentID: UUID?
    var mode: String
    var sortOrder: Int
    var createdDate: Date
    var modifiedDate: Date

    // NEW: Media items (images/videos)
    @Relationship(deleteRule: .cascade)
    var mediaItems: [MediaItem]

    // NEW: Links (URLs)
    var links: [String]

    // NEW: Hidden status per mode
    var hiddenInModes: [String: Bool]

    // NEW: Favorite status per mode
    var favoriteInModes: [String: Bool]

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        notesHTML: String? = nil,
        parentID: UUID? = nil,
        mode: String,
        sortOrder: Int = 0,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        mediaItems: [MediaItem] = [],
        links: [String] = [],
        hiddenInModes: [String: Bool] = [:],
        favoriteInModes: [String: Bool] = [:]
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.notesHTML = notesHTML
        self.parentID = parentID
        self.mode = mode
        self.sortOrder = sortOrder
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.mediaItems = mediaItems
        self.links = links
        self.hiddenInModes = hiddenInModes
        self.favoriteInModes = favoriteInModes
    }

    // MARK: - Helper Methods

    func isHidden(in mode: BJJMode) -> Bool {
        guard mode != .combined else { return false }
        return hiddenInModes[mode.rawValue] ?? false
    }

    func setHidden(_ hidden: Bool, in mode: BJJMode) {
        guard mode != .combined else { return }
        hiddenInModes[mode.rawValue] = hidden
    }

    func isFavorite(in mode: BJJMode) -> Bool {
        guard mode != .combined else {
            // In combined mode, favorited if favorited in either mode
            return (favoriteInModes["gi"] ?? false) || (favoriteInModes["nogi"] ?? false)
        }
        return favoriteInModes[mode.rawValue] ?? false
    }

    func setFavorite(_ favorite: Bool, in mode: BJJMode) {
        guard mode != .combined else { return }
        favoriteInModes[mode.rawValue] = favorite
    }
}

extension Technique {
    struct ExportData: Codable {
        let id: UUID
        let name: String
        let notes: String
        let notesHTML: String?
        let parentID: UUID?
        let mode: String
        let sortOrder: Int
        let createdDate: Date
        let modifiedDate: Date
        let links: [String]
        let hiddenInModes: [String: Bool]?  // Optional for backward compatibility
        let favoriteInModes: [String: Bool]?  // Optional for backward compatibility
    }

    func toExportData() -> ExportData {
        ExportData(
            id: id,
            name: name,
            notes: notes,
            notesHTML: notesHTML,
            parentID: parentID,
            mode: mode,
            sortOrder: sortOrder,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            links: links,
            hiddenInModes: hiddenInModes,
            favoriteInModes: favoriteInModes
        )
    }

    static func fromExportData(_ data: ExportData) -> Technique {
        Technique(
            id: data.id,
            name: data.name,
            notes: data.notes,
            notesHTML: data.notesHTML,
            parentID: data.parentID,
            mode: data.mode,
            sortOrder: data.sortOrder,
            createdDate: data.createdDate,
            modifiedDate: data.modifiedDate,
            links: data.links,
            hiddenInModes: data.hiddenInModes ?? [:],
            favoriteInModes: data.favoriteInModes ?? [:]
        )
    }
}
