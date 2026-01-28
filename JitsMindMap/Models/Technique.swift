import Foundation
import SwiftData

@Model
final class Technique {
    var id: UUID
    var name: String
    var notes: String
    var parentID: UUID?
    var mode: String
    var sortOrder: Int
    var createdDate: Date
    var modifiedDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        parentID: UUID? = nil,
        mode: String,
        sortOrder: Int = 0,
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.parentID = parentID
        self.mode = mode
        self.sortOrder = sortOrder
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
}

extension Technique {
    struct ExportData: Codable {
        let id: UUID
        let name: String
        let notes: String
        let parentID: UUID?
        let mode: String
        let sortOrder: Int
        let createdDate: Date
        let modifiedDate: Date
    }

    func toExportData() -> ExportData {
        ExportData(
            id: id,
            name: name,
            notes: notes,
            parentID: parentID,
            mode: mode,
            sortOrder: sortOrder,
            createdDate: createdDate,
            modifiedDate: modifiedDate
        )
    }

    static func fromExportData(_ data: ExportData) -> Technique {
        Technique(
            id: data.id,
            name: data.name,
            notes: data.notes,
            parentID: data.parentID,
            mode: data.mode,
            sortOrder: data.sortOrder,
            createdDate: data.createdDate,
            modifiedDate: data.modifiedDate
        )
    }
}
