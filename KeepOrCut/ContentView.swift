import SwiftUI
import PhotosUI

enum KeepOrCutLabel: String {
    case keep = "Keep"
    case maybe = "Maybe"
    case delete = "Delete"
}

struct ContentView: View {
    @State private var selection: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var index: Int = 0

    @State private var lastLabelText: String = ""

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
                Text("Pick some photos to start.")
                    .foregroundStyle(.secondary)
            } else {
                Image(uiImage: images[index])
                    .resizable()
                    .scaledToFit()
                    .frame(height: 360)
                    .cornerRadius(14)

                Text("Photo \(index + 1) of \(images.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                HStack(spacing: 12) {
                    Button("Keep") { label(.keep) }
                    Button("Maybe") { label(.maybe) }
                    Button("Delete") { label(.delete) }
                }
                .buttonStyle(.borderedProminent)

                if !lastLabelText.isEmpty {
                    Text(lastLabelText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        images.removeAll()
        index = 0
        lastLabelText = ""

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                images.append(img)
            }
        }
    }

    private func label(_ l: KeepOrCutLabel) {
        guard !images.isEmpty else { return }
        lastLabelText = "Labeled as \(l.rawValue)"
        index = min(index + 1, images.count - 1)
    }
}

#Preview {
    ContentView()
}
