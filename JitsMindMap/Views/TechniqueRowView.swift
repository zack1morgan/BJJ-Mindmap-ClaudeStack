import SwiftUI

struct TechniqueRowView: View {
    let technique: Technique
    let depth: Int
    let hasChildren: Bool
    let isExpanded: Bool
    let currentMode: BJJMode
    let onToggleExpand: () -> Void
    let onAddChild: () -> Void
    let onDelete: () -> Void
    let onHide: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let canMoveUp: Bool
    let canMoveDown: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Indentation
            if depth > 0 {
                Color.clear
                    .frame(width: CGFloat(depth) * 20)
            }

            // Expand/Collapse Chevron
            if hasChildren {
                Button(action: onToggleExpand) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 20, height: 20)
            }

            // Technique Name
            Text(technique.name)
                .font(.body)

            // Star indicator if favorited
            if technique.isFavorite(in: currentMode) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onAddChild()
            } label: {
                Label("Add Child Technique", systemImage: "plus")
            }

            // Only show hide option in non-combined modes
            if currentMode != .combined {
                Button {
                    onHide()
                } label: {
                    Label("Hide \(technique.name)", systemImage: "eye.slash")
                }
            }

            Divider()

            if canMoveUp {
                Button {
                    onMoveUp()
                } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
            }

            if canMoveDown {
                Button {
                    onMoveDown()
                } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
