import SwiftUI
import PhotosUI
import AVKit

struct MediaGalleryView: View {
    @Binding var mediaItems: [MediaItem]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingFullScreen: MediaItem?
    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Media")
                    .font(.headline)

                Spacer()

                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .any(of: [.images, .videos])
                ) {
                    Label("Add Media", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline)
                }
                .onChange(of: selectedItems) { oldValue, newValue in
                    processSelectedMedia()
                }
                .disabled(isProcessing)
            }

            if mediaItems.isEmpty {
                Text("No media added yet")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(mediaItems) { item in
                            MediaThumbnailView(item: item)
                                .onTapGesture {
                                    showingFullScreen = item
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteMedia(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(item: $showingFullScreen) { item in
            FullScreenMediaView(item: item)
        }
    }

    private func processSelectedMedia() {
        isProcessing = true

        Task {
            for photoItem in selectedItems {
                if let data = try? await photoItem.loadTransferable(type: Data.self) {
                    // Check if it's a video or image
                    if let image = UIImage(data: data) {
                        await processImage(image)
                    }
                } else if let movie = try? await photoItem.loadTransferable(type: Movie.self) {
                    await processVideo(movie.url)
                }
            }

            await MainActor.run {
                selectedItems = []
                isProcessing = false
            }
        }
    }

    @MainActor
    private func processImage(_ image: UIImage) async {
        let compressed = MediaManager.shared.compressImage(image)
        let fileName = "\(UUID().uuidString).jpg"

        if MediaManager.shared.saveImage(compressed, fileName: fileName) {
            // Generate thumbnail
            let thumbnailImage = compressed
            let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.5)

            let mediaItem = MediaItem(
                fileName: fileName,
                type: "image",
                thumbnailData: thumbnailData
            )
            mediaItems.append(mediaItem)
        }
    }

    @MainActor
    private func processVideo(_ url: URL) async {
        let fileName = "\(UUID().uuidString).mov"

        if MediaManager.shared.saveVideo(from: url, fileName: fileName) {
            // Generate thumbnail
            let thumbnailImage = MediaManager.shared.generateVideoThumbnail(from: MediaManager.shared.getVideoURL(fileName: fileName))
            let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 0.5)

            let mediaItem = MediaItem(
                fileName: fileName,
                type: "video",
                thumbnailData: thumbnailData
            )
            mediaItems.append(mediaItem)
        }
    }

    private func deleteMedia(_ item: MediaItem) {
        MediaManager.shared.deleteMedia(fileName: item.fileName)
        mediaItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Media Thumbnail View

struct MediaThumbnailView: View {
    let item: MediaItem

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let thumbnailData = item.thumbnailData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: item.type == "video" ? "video.fill" : "photo.fill")
                            .foregroundColor(.gray)
                    )
            }

            if item.type == "video" {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding(8)
            }
        }
    }
}

// MARK: - Full Screen Media View

struct FullScreenMediaView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if item.type == "image" {
                    if let image = MediaManager.shared.loadImage(fileName: item.fileName) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                } else if item.type == "video" {
                    let videoURL = MediaManager.shared.getVideoURL(fileName: item.fileName)
                    VideoPlayer(player: AVPlayer(url: videoURL))
                }
            }
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
}

// MARK: - Movie Transferable (for video loading)

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie-\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}
