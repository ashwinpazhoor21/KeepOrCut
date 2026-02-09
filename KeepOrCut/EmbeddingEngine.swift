import Foundation
import Vision
import UIKit
import CoreImage

enum EmbeddingError: Error {
    case cannotCreateCGImage
    case noResult
}

final class EmbeddingEngine {
    private static let ciContext = CIContext()

    static func featurePrint(from image: UIImage) throws -> VNFeaturePrintObservation {
        // PhotosPicker often gives images without a backing cgImage.
        // This creates a CGImage from cgImage, ciImage, or by rendering.
        let cg: CGImage? = {
            if let cg = image.cgImage { return cg }

            if let ci = image.ciImage {
                return ciContext.createCGImage(ci, from: ci.extent)
            }

            // Last resort: render UIImage into a CGImage
            let renderer = UIGraphicsImageRenderer(size: image.size)
            let rendered = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
            return rendered.cgImage
        }()

        guard let cg else { throw EmbeddingError.cannotCreateCGImage }

        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try handler.perform([request])

        guard let fp = request.results?.first as? VNFeaturePrintObservation else {
            throw EmbeddingError.noResult
        }

        return fp
    }

    static func distance(_ a: VNFeaturePrintObservation, _ b: VNFeaturePrintObservation) throws -> Float {
        var dist: Float = 0
        try a.computeDistance(&dist, to: b)
        return dist
    }
}
