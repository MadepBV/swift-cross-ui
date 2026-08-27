import Foundation
import ImageFormats
import SwiftCrossUI

/// Counts how many times a benchmark view's `body` has been evaluated.
///
/// A CAD-class app's view bodies are expensive, so the number of times the
/// framework evaluates them per update pass is a first-class measurement
/// rather than an implementation detail.
@MainActor
enum BodyCounter {
    static var count = 0

    static func reset() {
        count = 0
    }

    @inline(never)
    static func record() {
        count += 1
    }
}

/// A label row of the kind that fills a CAD app's inspector panels.
struct PropertyRow: View {
    var name: String
    var value: String
    var highlighted: Bool

    var body: some View {
        BodyCounter.record()
        return HStack(spacing: 4) {
            Text(name)
                .foregroundColor(highlighted ? .blue : .gray)
            Text(value)
                .foregroundColor(.black)
        }
        .padding(2)
    }
}

/// A sidebar entry: a colour swatch plus two lines of text.
struct SidebarRow: View {
    var title: String
    var subtitle: String
    var color: Color

    var body: some View {
        BodyCounter.record()
        return HStack(spacing: 6) {
            color.frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(subtitle)
                    .foregroundColor(.gray)
            }
        }
        .padding(3)
    }
}

/// A toolbar button.
struct ToolbarItem: View {
    var label: String

    var body: some View {
        BodyCounter.record()
        return Text(label)
            .padding(4)
            .background(Color.gray)
            .cornerRadius(3)
    }
}

/// A model panel: a stack of property rows.
struct PropertyPanel: View {
    var title: String
    var rowCount: Int
    var selection: Int

    var body: some View {
        BodyCounter.record()
        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundColor(.black)
            ForEach(Array(0..<rowCount)) { index in
                PropertyRow(
                    name: CADView.propertyNames[index % CADView.propertyNames.count],
                    value: CADView.propertyValues[index % CADView.propertyValues.count],
                    highlighted: index == selection
                )
            }
        }
        .padding(4)
    }
}

/// A CAD-class window: a tool bar, a navigator sidebar, a large raster
/// viewport, and two inspector panels. Roughly 500 text labels and a few
/// thousand view graph nodes.
struct CADView: TestCaseView {
    static let propertyNames = [
        "Diameter", "Length", "Bending radius", "Cover", "Grade",
        "Shape code", "Spacing", "Count", "Weight", "Layer",
    ]

    static let propertyValues = [
        "16 mm", "1 250 mm", "64 mm", "35 mm", "B500B",
        "21", "150 mm", "48", "19.7 kg", "Slab / top",
    ]

    static let sidebarTitles = [
        "Foundation", "Slab", "Column", "Beam", "Wall",
        "Stair", "Ramp", "Corbel", "Pile cap", "Capping beam",
    ]

    static let swatchColors: [Color] = [
        .blue, .green, .orange, .purple, .red, .yellow,
    ]

    /// The number of frames rendered so far. Drives the viewport image and the
    /// selected inspector row.
    var frame: Int = 0

    /// The viewport's pixels. Handed in from the benchmark driver so that the
    /// driver controls whether the pixels change from frame to frame.
    var viewport: ImageFormats.Image<RGBA>

    init() {
        self.init(frame: 0, viewport: CADView.makeViewport(frame: 0))
    }

    init(frame: Int, viewport: ImageFormats.Image<RGBA>) {
        self.frame = frame
        self.viewport = viewport
    }

    /// Builds a viewport-sized RGBA buffer. `frame` perturbs the first pixel so
    /// that consecutive frames aren't bitwise identical, which is what a real
    /// 3D viewport produces.
    static func makeViewport(frame: Int) -> ImageFormats.Image<RGBA> {
        let width = 640
        let height = 1001
        var bytes = [UInt8](repeating: 0x20, count: width * height * 4)
        bytes[0] = UInt8(frame % 256)
        return ImageFormats.Image<RGBA>(
            width: width,
            height: height,
            bytes: bytes
        )
    }

    var body: some View {
        BodyCounter.record()
        return VStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(Array(0..<16)) { index in
                    ToolbarItem(label: "Tool \(index)")
                }
            }
            .padding(4)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(0..<120)) { index in
                        SidebarRow(
                            title: Self.sidebarTitles[index % Self.sidebarTitles.count],
                            subtitle: "id \(index)",
                            color: Self.swatchColors[index % Self.swatchColors.count]
                        )
                    }
                }
                .frame(width: 220)

                Image(viewport)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 0) {
                    PropertyPanel(
                        title: "Bar properties",
                        rowCount: 60,
                        selection: frame % 60
                    )
                    PropertyPanel(
                        title: "Placement",
                        rowCount: 60,
                        selection: (frame / 2) % 60
                    )
                }
                .frame(width: 260)
            }

            HStack(spacing: 8) {
                ForEach(Array(0..<6)) { index in
                    Text("Status field \(index)")
                        .foregroundColor(.gray)
                }
            }
            .padding(3)
        }
    }
}

/// A long uniform list of rows, the shape a bar schedule or a parts list takes.
struct LongListView: TestCaseView {
    var body: some View {
        BodyCounter.record()
        return VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(0..<800)) { index in
                PropertyRow(
                    name: CADView.propertyNames[index % CADView.propertyNames.count],
                    value: CADView.propertyValues[index % CADView.propertyValues.count],
                    highlighted: false
                )
            }
        }
    }
}

/// A drafting overlay: a `Canvas` issuing a few hundred drawing commands, the
/// shape a CAD app's selection highlights, snap indicators, handles and section
/// markers take.
struct DraftingOverlayView: TestCaseView {
    /// Perturbs the drawing so that the "animating" case actually changes.
    var phase: Double = 0

    init() {
        self.init(phase: 0)
    }

    init(phase: Double) {
        self.phase = phase
    }

    var body: some View {
        BodyCounter.record()
        let phase = phase
        // Wrapped in a stack because `View.defaultComputeLayout` lays a body
        // out as if it were a `VStack`, which only works for `TupleView`
        // content; a body that is a bare `Canvas` lays out to zero.
        return VStack(spacing: 0) {
            Canvas { context, size in
                for index in 0..<200 {
                    let t = Double(index) / 200.0
                    let x = t * size.width
                    let y = (0.5 + 0.4 * Foundation.sin(t * 12 + phase)) * size.height
                    var path = Path()
                    path = path.addRectangle(
                        Path.Rect(x: x, y: y, width: 6, height: 6)
                    )
                    context.fill(path, with: .color(.blue))
                    context.stroke(path, with: .color(.black), lineWidth: 1)
                }
                for index in 0..<40 {
                    context.draw(
                        Text("d\(index)"),
                        at: CGPoint(
                            x: Double(index) * 18,
                            y: 12
                        )
                    )
                }
            }
        }
    }
}
