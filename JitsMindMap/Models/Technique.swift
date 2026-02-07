import Foundation
import SwiftData

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
final class Technique {
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
        links: [String] = []
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
            links: links
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
            links: data.links
        )
    }
}
