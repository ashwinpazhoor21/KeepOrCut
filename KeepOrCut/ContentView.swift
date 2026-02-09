import SwiftUI
import PhotosUI
import Vision
import UIKit

enum KeepOrCutLabel: String {
    case keep = "Keep"
    case maybe = "Maybe"
    case delete = "Delete"
}

struct ContentView: View {
    @State private var selection: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var index: Int = 0

    @State private var labeledSet: [(VNFeaturePrintObservation, KeepOrCutLabel)] = []

    @State private var predictedLabel: KeepOrCutLabel = .maybe
    @State private var predictedConfidence: Double = 0.0
    @State private var statusText: String = "Pick photos to start."
    @State private var isComputingPrediction: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("KeepOrCut")
                .font(.title2)
                .bold()

            PhotosPicker(
                selection: $selection,
                maxSelectionCount: 200,
                matching: .images
            ) {
                Text("Pick Photos")
                    .font(.headline)
            }
            .onChange(of: selection) { _, newItems in
                Task { await loadImages(from: newItems) }
            }

            if images.isEmpty {
                Text(statusText)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding(.top, 8)
            } else {
                Image(uiImage: images[index])
                    .resizable()
                    .scaledToFit()
                    .frame(height: 380)
                    .cornerRadius(14)

                Text("Photo \(index + 1) of \(images.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                HStack(spacing: 8) {
                    Text("Prediction:")
                        .foregroundStyle(.secondary)

                    Text(predictedLabel.rawValue)
                        .fontWeight(.semibold)

                    Text("(\(Int(predictedConfidence * 100))%)")
                        .foregroundStyle(.secondary)

                    if isComputingPrediction {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .font(.callout)

                HStack(spacing: 12) {
                    Button("Keep") { label(.keep) }
                    Button("Maybe") { label(.maybe) }
                    Button("Delete") { label(.delete) }
                }
                .buttonStyle(.borderedProminent)

                HStack(spacing: 12) {
                    Button("Prev") { goPrev() }
                        .disabled(index == 0)

                    Button("Next") { goNext() }
                        .disabled(index >= images.count - 1)
                }
                .font(.callout)

                Text("Labeled: \(labeledSet.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .onChange(of: index) { _, _ in
            updatePredictionForCurrent()
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        await MainActor.run {
            images.removeAll()
            index = 0
            labeledSet.removeAll()
            predictedLabel = .maybe
            predictedConfidence = 0.0
            statusText = "Loading photos…"
        }

        var loaded: [UIImage] = []
        loaded.reserveCapacity(items.count)

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                loaded.append(img)
            }
        }

        await MainActor.run {
            images = loaded
            statusText = images.isEmpty ? "No images loaded." : ""
        }

        updatePredictionForCurrent()
    }

    private func updatePredictionForCurrent() {
        guard !images.isEmpty else { return }
        let img = images[index]

        isComputingPrediction = true

        Task {
            do {
                let fp = try EmbeddingEngine.featurePrint(from: img)
                let pred = try TriageClassifier.predict(query: fp, training: labeledSet, k: 7)

                await MainActor.run {
                    predictedLabel = pred.label
                    predictedConfidence = pred.confidence
                    isComputingPrediction = false
                }
            } catch {
                await MainActor.run {
                    predictedLabel = .maybe
                    predictedConfidence = 0.0
                    isComputingPrediction = false
                }
            }
        }
    }

    private func label(_ l: KeepOrCutLabel) {
        guard !images.isEmpty else { return }
        let img = images[index]

        Task {
            do {
                let fp = try EmbeddingEngine.featurePrint(from: img)
                await MainActor.run {
                    labeledSet.append((fp, l))
                }
            } catch {

            }

            await MainActor.run {
                goNext()
            }
        }
    }

    private func goNext() {
        guard !images.isEmpty else { return }
        index = min(index + 1, images.count - 1)
    }

    private func goPrev() {
        guard !images.isEmpty else { return }
        index = max(index - 1, 0)
    }
}
