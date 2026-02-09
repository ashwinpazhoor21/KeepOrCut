//
//  EmbeddingEngine.swift
//  KeepOrCut
//
//  Created by Ashwin Pazhoor on 2/9/26.
//

import Foundation
import Vision
import UIKit

enum EmbeddingError: Error {
    case badCGImage
    case noResult
}

final class EmbeddingEngine {

    static func featurePrint(from image: UIImage) throws -> VNFeaturePrintObservation {
        guard let cg = image.cgImage else { throw EmbeddingError.badCGImage }

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
