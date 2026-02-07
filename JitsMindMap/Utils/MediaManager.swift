import Foundation
import UIKit
import AVFoundation

class MediaManager {
    static let shared = MediaManager()

    private let fileManager = FileManager.default
    private var mediaDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mediaPath = documentsPath.appendingPathComponent("Media", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: mediaPath.path) {
            try? fileManager.createDirectory(at: mediaPath, withIntermediateDirectories: true)
        }

        return mediaPath
    }

    // MARK: - Save Media

    func saveImage(_ image: UIImage, fileName: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let fileURL = mediaDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }

    func saveVideo(from url: URL, fileName: String) -> Bool {
        let destinationURL = mediaDirectory.appendingPathComponent(fileName)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            return true
        } catch {
            print("Error saving video: \(error)")
            return false
        }
    }

    // MARK: - Load Media

    func loadImage(fileName: String) -> UIImage? {
        let fileURL = mediaDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func getVideoURL(fileName: String) -> URL {
        return mediaDirectory.appendingPathComponent(fileName)
    }

    // MARK: - Delete Media

    func deleteMedia(fileName: String) {
        let fileURL = mediaDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }

    // MARK: - Generate Thumbnail

    func generateVideoThumbnail(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }

    func compressImage(_ image: UIImage, maxWidth: CGFloat = 1024) -> UIImage {
        let scale = maxWidth / image.size.width
        if scale >= 1 {
            return image
        }

        let newHeight = image.size.height * scale
        let newSize = CGSize(width: maxWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }
}
