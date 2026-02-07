import SwiftUI

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TechniqueViewModel
    let mode: BJJMode

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites",
                        systemImage: "star",
                        description: Text("Tap the star icon on any technique to add it to your favorites")
                    )
                } else {
                    List(favorites, id: \.id) { technique in
                        NavigationLink(destination: TechniqueDetailView(technique: technique, viewModel: viewModel)) {
                            HStack {
                                Text(technique.name)
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var favorites: [Technique] {
        viewModel.fetchFavorites(for: mode)
    }
}
