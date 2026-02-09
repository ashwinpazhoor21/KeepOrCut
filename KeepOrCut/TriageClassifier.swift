//
//  TriageClassifier.swift
//  KeepOrCut
//
//  Created by Ashwin Pazhoor on 2/9/26.
//

import Foundation
import Vision

struct Neighbor {
    let label: KeepOrCutLabel
    let distance: Float
}

final class TriageClassifier {

    static func predict(
        query: VNFeaturePrintObservation,
        training: [(VNFeaturePrintObservation, KeepOrCutLabel)],
        k: Int = 7
    ) throws -> (label: KeepOrCutLabel, confidence: Double) {

        guard !training.isEmpty else { return (.maybe, 0.0) }

        var neighbors: [Neighbor] = []
        neighbors.reserveCapacity(training.count)

        for (fp, label) in training {
            let d = try EmbeddingEngine.distance(query, fp)
            neighbors.append(Neighbor(label: label, distance: d))
        }

        neighbors.sort { $0.distance < $1.distance }
        let top = neighbors.prefix(min(k, neighbors.count))

        var score: [KeepOrCutLabel: Double] = [.keep: 0, .maybe: 0, .delete: 0]
        for n in top {
            let w = 1.0 / (Double(n.distance) + 1e-6)
            score[n.label, default: 0] += w
        }

        let best = score.max { $0.value < $1.value }!
        let total = score.values.reduce(0, +)
        let confidence = total > 0 ? best.value / total : 0.0

        return (best.key, confidence)
    }
}
