import Foundation
import ImageFormats
import SwiftCrossUI

/// A media app's browsing screen: a scroll view holding a lazy grid of cards,
/// each a button around a clipped artwork with overlays and a two-line
/// caption, carrying the modifiers such a card typically has (a task, a
/// change handler, accessibility). Shaped after Avelio's `MediaCard` on its
/// Discover tab, whose updates and tab switches were measured on Windows.
struct CardGridView: View {
    var count: Int
    var revision: Int
    var artwork: ImageFormats.Image<RGBA>

    static func makeArtwork() -> ImageFormats.Image<RGBA> {
        ImageFormats.Image<RGBA>(width: 64, height: 36, bytes: [UInt8](repeating: 128, count: 64 * 36 * 4))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Discover").font(.title)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 24) {
                    ForEach(0..<count, id: \.self) { index in
                        CardGridCard(index: index, revision: revision, artwork: artwork)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct CardGridCard: View {
    var index: Int
    var revision: Int
    var artwork: ImageFormats.Image<RGBA>
    @State private var appeared = false

    var body: some View {
        Button {
            appeared.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Color.gray
                    Image(artwork).resizable().aspectRatio(contentMode: .fill)
                }
                .frame(width: 220, height: 124)
                .overlay(alignment: .topTrailing) {
                    if index % 3 == 0 {
                        Text("4K").font(.caption2).padding(4).background(Color.black.opacity(0.5))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Title number \(index)")
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("2026 · Drama · \(revision)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: 220, alignment: .leading)
        }
        .accessibilityLabel("Title number \(index)")
        .onChange(of: revision) {}
        .onAppear { appeared = true }
    }
}
