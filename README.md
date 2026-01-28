# JitsMindMap - BJJ Technique Organization App

A native iOS app for organizing Brazilian Jiu-Jitsu techniques using a hierarchical mind map structure. Built with SwiftUI and SwiftData.

> **Note:** This is currently a **BASIC v1 implementation**. The app provides core functionality for organizing techniques, with many planned improvements coming in v2.

## Purpose

JitsMindMap helps BJJ practitioners organize and track their technique knowledge in a structured, hierarchical format. Whether you're a white belt learning the fundamentals or a black belt refining your game, this app provides a clear way to map out your BJJ knowledge, take notes, and build your personal technique library.

Think of it as a digital notebook that understands the hierarchical nature of BJJ positions and techniques - from broad positions (Mount, Guard, Back Control) down to specific submissions, sweeps, and transitions.

## Current Features (v1)

- **Hierarchical Tree View**: Organize techniques in a collapsible tree structure (like iOS Files app)
- **Gi/NoGi Modes**: Separate workspaces for Gi and NoGi technique libraries
- **CRUD Operations**: Create, view, edit, and delete techniques
- **Child Techniques**: Add sub-techniques under any technique (e.g., Armbar → High Mount Armbar)
- **Note-Taking**: Multi-line notes for each technique with technique names and details
- **Reordering**: Move techniques up/down to organize within sibling groups
- **Preset Content**: Starter techniques included for common positions (Mount, Guard, Side Control, Back Control)
- **Export/Import**: Backup and restore your entire technique database as JSON
- **Local Storage**: All data stored locally using SwiftData (no cloud, no account needed)

## Planned Features (v2)

- **Video Integration**: Upload technique videos (up to 30 seconds) for visual reference
- **Color Coding**: Color-code techniques by type (submissions, sweeps, escapes, transitions)
- **Advanced Filtering**: Filter by technique type, difficulty, or custom tags
- **Search Functionality**: Quickly find techniques across your entire library
- **Improved UI**: Enhanced visual design with better spacing and modern iOS styling
- **Dark Mode**: Full dark mode support
- **Categories/Tags**: Tag techniques with multiple categories for better organization
- **Progress Tracking**: Mark techniques as learning, proficient, or mastered
- **Cloud Sync**: Optional iCloud sync across devices

## Tech Stack

- **Framework**: SwiftUI
- **Persistence**: SwiftData (local storage)
- **Minimum iOS**: 17.0+
- **Architecture**: MVVM pattern
- **Dependencies**: None (iOS native only)

## Setup Instructions

### Requirements
- Xcode 15.0 or later
- iOS 17.0 or later
- macOS Sonoma or later

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/BJJ-Mindmap-ClaudeStack.git
   cd BJJ-Mindmap-ClaudeStack
   ```

2. Open the project in Xcode:
   ```bash
   open JitsMindMap.xcodeproj
   ```

3. Select a simulator or device (iOS 17+)

4. Build and run (Cmd+R)

The app will launch with preset techniques for both Gi and NoGi modes.

## Project Structure

```
JitsMindMap/
├── Models/
│   └── Technique.swift           # SwiftData model
├── Views/
│   ├── TreeView.swift            # Main hierarchical view
│   ├── TechniqueDetailView.swift # Edit technique details
│   └── TechniqueRowView.swift    # Individual row component
├── ViewModels/
│   └── TechniqueViewModel.swift  # Business logic
├── Data/
│   └── SeedData.json             # Preset techniques
└── JitsMindMapApp.swift          # App entry point
```

## Usage

### Switching Modes
- Use the segmented control at the top to toggle between **Gi** and **NoGi** modes
- Each mode maintains its own separate technique tree

### Adding Techniques
- Tap the blue **+** button (bottom right) to add a root-level technique
- Long-press any technique → select **"Add Child Technique"** to add a sub-technique

### Editing Techniques
- Tap any technique to open the detail view
- Edit the name and notes
- Tap **"Save"** to save changes

### Organizing Techniques
Long-press a technique to access:
- **Add Child Technique**: Create a sub-technique
- **Move Up/Down**: Reorder within sibling group
- **Delete**: Remove technique and all children (with confirmation)

### Expanding/Collapsing
- Tap the **chevron icon** (▶/▼) next to techniques with children to expand/collapse

### Export/Import
- Tap the **ellipsis menu** (top right) to access export/import
- **Export**: Creates a JSON file you can save or share
- **Import**: Restores techniques from a JSON file backup

## Data Model

Each technique contains:
- **id**: Unique identifier (UUID)
- **name**: Technique name
- **notes**: Multi-line notes (optional)
- **parentID**: Parent technique ID (nil for root techniques)
- **mode**: "gi" or "nogi"
- **sortOrder**: Position among siblings
- **createdDate**: Creation timestamp
- **modifiedDate**: Last modification timestamp

## Contributing

This is a personal learning project, but suggestions and feedback are welcome! Feel free to:
- Open issues for bugs or feature requests
- Submit pull requests with improvements
- Share your ideas for v2 features

## Roadmap

### v1 (Current) - Core Functionality
- ✅ Basic tree structure
- ✅ CRUD operations
- ✅ Gi/NoGi modes
- ✅ Notes and organization
- ✅ Export/Import

### v2 (Planned) - Enhanced Features
- 🔲 Video uploads (30s limit)
- 🔲 Color coding by technique type
- 🔲 Search functionality
- 🔲 Advanced filtering
- 🔲 Dark mode
- 🔲 Improved UI/UX
- 🔲 Tags and categories
- 🔲 Progress tracking

### v3 (Future)
- 🔲 iCloud sync
- 🔲 Social features (share techniques)
- 🔲 Training log integration
- 🔲 Belt-specific technique recommendations

## License

MIT License - Feel free to use this project for learning or personal use.

## Acknowledgments

Built with SwiftUI and SwiftData as a tool for the BJJ community. OSS!

---

**Current Version**: 1.0.0
**Last Updated**: January 2026
**Maintained By**: Zack Morgan
