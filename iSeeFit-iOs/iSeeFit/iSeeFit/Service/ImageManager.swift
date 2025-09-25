//
//  ImageManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-25.
//

import Foundation
import UIKit

final class ImageManager {
    static let shared = ImageManager()
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    private init() {
        // Get documents directory
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Create Images directory if it doesn't exist
        let imagesDirectory = documentsDirectory.appendingPathComponent("Images")
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
                print("DEBUG: ImageManager - Created Images directory at: \(imagesDirectory.path)")
            } catch {
                print("ERROR: ImageManager - Failed to create Images directory: \(error)")
            }
        }
    }
    
    // MARK: - Save Image
    func saveImage(_ image: UIImage, filename: String, compressionQuality: CGFloat = 0.8) -> String? {
        let imagesDirectory = documentsDirectory.appendingPathComponent("Images")
        let fileURL = imagesDirectory.appendingPathComponent("\(filename).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            print("ERROR: ImageManager - Failed to convert image to JPEG data")
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            print("DEBUG: ImageManager - Saved image to: \(fileURL.path)")
            return fileURL.path
        } catch {
            print("ERROR: ImageManager - Failed to save image: \(error)")
            return nil
        }
    }
    
    func saveFoodImage(_ image: UIImage, recordId: UUID) -> String? {
        let filename = "food_\(recordId.uuidString)_\(Int(Date().timeIntervalSince1970))"
        return saveImage(image, filename: filename)
    }
    
    func saveWeightImage(_ image: UIImage, recordId: UUID) -> String? {
        let filename = "weight_\(recordId.uuidString)_\(Int(Date().timeIntervalSince1970))"
        return saveImage(image, filename: filename)
    }
    
    // MARK: - Load Image
    func loadImage(from path: String) -> UIImage? {
        let fileURL = URL(fileURLWithPath: path)
        
        guard fileManager.fileExists(atPath: path) else {
            print("WARNING: ImageManager - Image file does not exist: \(path)")
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: fileURL) else {
            print("ERROR: ImageManager - Failed to load image data from: \(path)")
            return nil
        }
        
        guard let image = UIImage(data: imageData) else {
            print("ERROR: ImageManager - Failed to create UIImage from data")
            return nil
        }
        
        print("DEBUG: ImageManager - Loaded image from: \(path)")
        return image
    }
    
    // MARK: - Delete Image
    func deleteImage(at path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
            print("DEBUG: ImageManager - Deleted image at: \(path)")
            return true
        } catch {
            print("ERROR: ImageManager - Failed to delete image: \(error)")
            return false
        }
    }
    
    // MARK: - Image Utilities
    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func compressImage(_ image: UIImage, to maxSizeKB: Int) -> UIImage? {
        let maxSizeBytes = maxSizeKB * 1024
        var compressionQuality: CGFloat = 1.0
        
        guard var imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        // Reduce quality until we're under the size limit
        while imageData.count > maxSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            guard let newImageData = image.jpegData(compressionQuality: compressionQuality) else {
                break
            }
            imageData = newImageData
        }
        
        return UIImage(data: imageData)
    }
    
    // MARK: - Directory Management
    func getImagesDirectory() -> URL {
        return documentsDirectory.appendingPathComponent("Images")
    }
    
    func getAllImageFiles() -> [String] {
        let imagesDirectory = getImagesDirectory()
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: imagesDirectory.path)
            return files.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".png") }
        } catch {
            print("ERROR: ImageManager - Failed to list image files: \(error)")
            return []
        }
    }
    
    func getTotalImageSize() -> Int64 {
        let imageFiles = getAllImageFiles()
        let imagesDirectory = getImagesDirectory()
        var totalSize: Int64 = 0
        
        for file in imageFiles {
            let fileURL = imagesDirectory.appendingPathComponent(file)
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            } catch {
                print("WARNING: ImageManager - Failed to get size for file: \(file)")
            }
        }
        
        return totalSize
    }
    
    func cleanupOldImages(olderThan days: Int = 30) {
        let imagesDirectory = getImagesDirectory()
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: imagesDirectory.path)
            
            for file in files {
                let fileURL = imagesDirectory.appendingPathComponent(file)
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try fileManager.removeItem(at: fileURL)
                    print("DEBUG: ImageManager - Cleaned up old image: \(file)")
                }
            }
        } catch {
            print("ERROR: ImageManager - Failed to cleanup old images: \(error)")
        }
    }
}
